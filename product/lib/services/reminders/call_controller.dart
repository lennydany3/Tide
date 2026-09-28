import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/app_constants.dart';
import '../habits/habit_rows.dart';
import '../models/habit.dart';
import 'reminder_plan.dart';
import 'reminder_store.dart';

/// What was done with a call.
///
/// A call asks one question — *are you awake, and when shall I come back?* —
/// and there is no third thing. Nothing here can log a habit, dock a to-do,
/// spend a freeze, move one to tomorrow or tick one of its steps: the call is
/// a reminder, and being reminded is not a decision about the day.
sealed class CallOutcome {
  const CallOutcome();
}

/// Heard, and nothing more. The habit or to-do stays open and today is
/// nobody's business but the person's.
final class CallHeard extends CallOutcome {
  const CallHeard();
}

/// Put off by [minutes]. The last "later" allowed is
/// [AppConstants.maxReminderSnoozes]; after that the occurrence is simply
/// over, and the phone does not say so twice.
final class CallLater extends CallOutcome {
  const CallLater(this.minutes);

  final int minutes;

  Duration get after => Duration(minutes: minutes);
}

/// The calls on screen and what answering them does.
///
/// The screens never know where they are. On Android's lock screen they run
/// in their own isolate and answer through native code
/// ([NativeCallController]); inside the app — a tap on iOS, a preview from
/// Settings — they answer through the stores ([InAppCallController]).
///
/// **An answered call stays in [calls] until the screen retires it**, so its
/// farewell plays out in full. The answer itself is sent at once: the ringing
/// must stop the moment it is given, not a second and a half later.
abstract class CallController extends ChangeNotifier {
  final List<PlannedReminder> _calls = [];
  final Map<String, int> _snoozes = {};
  final Set<String> _answered = {};
  bool _loaded = false;
  bool _closed = false;

  List<PlannedReminder> get calls => List.unmodifiable(_calls);

  /// Whether [calls] has been read yet. Nothing is drawn before it has.
  bool get loaded => _loaded;

  /// Shown over the lock screen, where nothing but the call is reachable.
  bool get overLockScreen => false;

  /// Answered, and waiting on its farewell before it is retired.
  bool isAnswered(PlannedReminder call) => _answered.contains(call.key);

  int snoozesTaken(PlannedReminder call) {
    final own = _snoozes[call.key];
    if (own != null) return own;
    // A call put off on the lock screen is counted in the phone's book, and
    // the call that comes back for it carries the figure. Read from there
    // rather than assumed, so the cap is the same whichever screen is asking.
    final carried = call.details['snoozes'];
    return carried is num ? carried.toInt() : 0;
  }

  /// A "later" is still allowed: [AppConstants.maxReminderSnoozes] is the
  /// last. A test can be put off, to see it happen; it just does not come
  /// back.
  ///
  /// **The count belongs to the phone.** A reminder put off from the lock
  /// screen is counted in the book, and the next call for that occurrence
  /// arrives carrying the figure — so it is read from the call itself when the
  /// controller has none of its own. Without that, a call answered inside the
  /// app always read zero, and the cap was only ever enforced on one screen.
  bool canLater(PlannedReminder call) =>
      snoozesTaken(call) < AppConstants.maxReminderSnoozes;

  /// Answers [call]. Sends the answer at once; the call stays on screen
  /// until [retire].
  ///
  /// A "later" past the last allowed one is dropped rather than sent: the
  /// reminder is spent, and saying so would be the fourth interruption in a
  /// row about the fact there is nothing left to interrupt with.
  Future<void> resolve(PlannedReminder call, CallOutcome outcome) async {
    if (outcome is CallLater && !canLater(call)) return;
    if (!_answered.add(call.key)) return;
    notifyListeners();
    await send(call, outcome);
  }

  /// Takes an answered call off the screen. The last one closes it.
  void retire(PlannedReminder call) {
    _calls.removeWhere((c) => c.key == call.key);
    _answered.remove(call.key);
    notifyListeners();
    if (_calls.isEmpty) unawaited(close());
  }

  /// Leaves the call for the app itself. On the lock screen this asks for
  /// the phone to be unlocked first.
  Future<void> openApp(PlannedReminder? call);

  /// The screen has nothing left to show.
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await finish();
  }

  // --- For implementations ---------------------------------------------------

  @protected
  void show(List<PlannedReminder> next, {Map<String, int> snoozes = const {}}) {
    // Calls already answered keep their place until they are retired, even
    // if the phone has stopped listing them.
    final keep = _calls.where((c) => _answered.contains(c.key)).toList();
    _calls
      ..clear()
      ..addAll(keep)
      ..addAll(next.where((c) => !keep.any((k) => k.key == c.key)));
    _snoozes
      ..clear()
      ..addAll(snoozes);
    _loaded = true;
    notifyListeners();
  }

  @protected
  Future<void> send(PlannedReminder call, CallOutcome outcome);

  @protected
  Future<void> finish();
}

/// Calls answered inside the app: a notification tapped on iOS, or a
/// preview from Settings → Reminders.
///
/// Only a "later" is sent on: it is the one answer that has to reach the
/// phone, because the reminder is native's from that moment. Being heard
/// changes nothing anywhere, so nothing is sent.
class InAppCallController extends CallController {
  InAppCallController({
    required this.reminders,
    required List<PlannedReminder> calls,
    required this.onClose,
    this.preview = false,
  }) {
    show(calls);
  }

  final ReminderStore reminders;

  /// Called once, when the screen has nothing left to show.
  final VoidCallback onClose;

  /// Answers change nothing: a look at the design, not a reminder.
  final bool preview;

  bool _live(PlannedReminder call) => !preview && !call.test;

  @override
  Future<void> send(PlannedReminder call, CallOutcome outcome) async {
    if (outcome is! CallLater || !_live(call)) return;
    await reminders.platform.snooze(
      call,
      outcome.after,
      snoozesTaken(call) + 1,
    );
  }

  @override
  Future<void> openApp(PlannedReminder? call) => close();

  @override
  Future<void> finish() async => onClose();
}

/// Calls on Android's lock screen, in the isolate `TideCallActivity` starts.
///
/// Native code owns the ringing and the "laters" given on the lock screen;
/// this asks it what is ringing, tells it what was answered, and hears when
/// another call joins the one on screen.
class NativeCallController extends CallController {
  NativeCallController({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'changed') await load();
    });
  }

  static const MethodChannel _channel = MethodChannel('tide/call');

  final DateTime Function() _clock;

  bool _locked = true;

  @override
  bool get overLockScreen => _locked;

  /// Reads what is ringing, and brings each habit's figures up to date from
  /// the device's copy of the account.
  Future<void> load() async {
    try {
      final raw = await _channel.invokeMethod<String>('load');
      final json = raw == null ? null : jsonDecode(raw);
      if (json is! Map) {
        show(const []);
        return;
      }
      _locked = json['locked'] != false;
      final calls = [
        for (final item in (json['calls'] as List? ?? const []))
          ?PlannedReminder.fromJson(item),
      ];
      final snoozes = <String, int>{
        for (final entry in (json['snoozes'] as Map? ?? const {}).entries)
          if (entry.value is int) '${entry.key}': entry.value as int,
      };
      show(await _refreshed(calls), snoozes: snoozes);
    } catch (error) {
      debugPrint('Calls not read: $error');
      show(const []);
    }
  }

  /// [calls] with streaks worked out from the device's copy of the account. A
  /// call planned three days ago would otherwise show three-day-old figures.
  Future<List<PlannedReminder>> _refreshed(List<PlannedReminder> calls) async {
    final accounts = {
      for (final call in calls)
        if (call.kind.isHabit && !call.test) ?call.accountId,
    };
    if (accounts.isEmpty) return calls;

    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final now = _clock();
    final habits = <String, Habit>{};
    for (final account in accounts) {
      for (final habit in HabitRows.decodeCache(
        prefs.getString(HabitRows.cacheKey(account)),
      )) {
        habits[habit.id] = habit;
      }
    }
    return [
      for (final call in calls)
        if (call.kind.isHabit && habits[call.subjectId] != null)
          ReminderPlanner.refreshed(call, habits[call.subjectId]!, now: now)
        else
          call,
    ];
  }

  @override
  Future<void> send(PlannedReminder call, CallOutcome outcome) async {
    try {
      await _channel.invokeMethod<void>('resolve', {
        'key': call.key,
        'outcome': outcome is CallLater ? 'later' : 'dismiss',
        if (outcome is CallLater) 'minutes': outcome.minutes,
      });
    } catch (error) {
      debugPrint('Call not answered: $error');
    }
  }

  @override
  Future<void> openApp(PlannedReminder? call) async {
    try {
      await _channel.invokeMethod<void>('openApp', {'key': call?.key});
    } catch (error) {
      debugPrint('App not opened: $error');
    }
  }

  @override
  Future<void> finish() async {
    try {
      await _channel.invokeMethod<void>('close');
    } catch (error) {
      debugPrint('Call not closed: $error');
    }
  }
}
