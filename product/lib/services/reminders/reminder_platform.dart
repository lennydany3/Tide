import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../config/app_constants.dart';
import '../models/reminder_options.dart';
import 'reminder_plan.dart';

/// What a reminder needs the phone to allow, in the order onboarding asks.
enum ReminderPermission {
  /// Anything at all can be shown.
  notifications(
    'Notifications',
    'So we can nudge you before a habit.',
    optional: false,
  ),

  /// Reminders land on the minute rather than somewhere in Android's window.
  exactAlarms(
    'Exact alarms',
    'So reminders arrive on the minute.',
    optional: false,
  ),

  /// A call can take the screen over the lock screen, while the phone is
  /// asleep.
  fullScreen(
    'Full-screen alerts',
    'So a reminder can wake your screen while the phone is locked.',
    optional: false,
  ),

  /// The system does not put Tide to sleep in the background.
  battery(
    'Background running',
    'So reminders are not stopped in the background.',
    optional: true,
  );

  const ReminderPermission(this.title, this.reason, {required this.optional});

  final String title;

  /// One line on why — the whole of the case onboarding makes for it.
  final String reason;

  /// Reminders work without it; it only makes them sturdier.
  final bool optional;
}

enum PermissionState {
  granted,
  denied,

  /// Means nothing on this phone: an Android version that grants it by
  /// default, or a platform that has no such thing.
  notApplicable;

  bool get ok => this != PermissionState.denied;
}

/// Where a tap on a reminder should land.
enum ReminderOpenTarget { habit, task, call }

@immutable
class ReminderOpen {
  const ReminderOpen(this.target, this.id, {this.calls = const []});

  final ReminderOpenTarget target;

  /// The habit or task id. For [ReminderOpenTarget.call], the reminder key.
  final String id;

  /// For a call opened inside the app: the reminders to answer.
  final List<PlannedReminder> calls;
}

/// Everything reminders need from the operating system.
///
/// Three implementations: `AndroidReminderPlatform`, which hands the plan to
/// native code that schedules, draws and rings it; `DarwinReminderPlatform`
/// on iOS, through `flutter_local_notifications`; and [NoReminderPlatform]
/// for tests, the web and desktop.
abstract class ReminderPlatform {
  /// The permissions that mean anything here, in the order to ask for them.
  List<ReminderPermission> get permissionsAsked;

  /// A call can take over the screen, rather than arrive as a notification
  /// that opens one.
  bool get fullScreenCalls;

  /// A tone can be played on the spot from the pickers.
  bool get canPreviewTones;

  Future<Map<ReminderPermission, PermissionState>> permissions();

  /// Asks for [permission]. One granted in the system's own settings opens
  /// them and returns what stands now; the store asks again when the app
  /// comes back to the foreground.
  Future<PermissionState> request(ReminderPermission permission);

  /// Replaces every reminder in [group] with [items]. A snoozed reminder in
  /// [group] whose subject is not in [open] is dropped: it was about
  /// something that has been settled since.
  Future<void> schedule(
    ReminderGroup group,
    List<PlannedReminder> items, {
    required Set<String> open,
  });

  /// Fires [items] at their times, apart from every plan, and changes
  /// nothing when they are answered.
  Future<void> test(List<PlannedReminder> items);

  /// Brings a call put off inside the app back in [after], counting [snoozes]
  /// taken so far. The one answer that leaves the phone, because a reminder is
  /// the phone's from the moment it rings. A later past
  /// [AppConstants.maxReminderSnoozes] is refused: the reminder is spent, and
  /// saying so would be another interruption about there being none left.
  Future<void> snooze(PlannedReminder item, Duration after, int snoozes);

  /// Taps on reminders while the app is running.
  Stream<ReminderOpen> get opened;

  /// The tap that launched the app, if one did. Handed over once.
  Future<ReminderOpen?> takeLaunch();

  Future<void> previewTone(ReminderTone tone);
}

/// Reminders that never fire: tests, the web, desktop.
///
/// Records what it is handed so tests can read it, and can be told to act
/// like a phone — which permissions it has, what a request answers — and to
/// record the "laters" and taps a lock screen would have sent.
class NoReminderPlatform implements ReminderPlatform {
  NoReminderPlatform({
    this.permissionsAsked = const [],
    Map<ReminderPermission, PermissionState>? states,
    this.grantOnRequest = true,
    this.fullScreenCalls = false,
  }) : states = {
         for (final p in ReminderPermission.values)
           p: permissionsAsked.contains(p)
               ? PermissionState.denied
               : PermissionState.notApplicable,
         ...?states,
       };

  @override
  final List<ReminderPermission> permissionsAsked;

  @override
  final bool fullScreenCalls;

  @override
  bool get canPreviewTones => false;

  final Map<ReminderPermission, PermissionState> states;

  /// What a request does to a permission: grant it, or leave it refused.
  bool grantOnRequest;

  final Map<ReminderGroup, List<PlannedReminder>> scheduled = {};
  final Map<ReminderGroup, Set<String>> openSubjects = {};
  final List<List<PlannedReminder>> tests = [];
  final List<({PlannedReminder item, Duration after, int snoozes})> snoozes =
      [];
  final List<ReminderPermission> requested = [];

  final StreamController<ReminderOpen> _opened =
      StreamController<ReminderOpen>.broadcast();
  ReminderOpen? launch;

  /// Taps a reminder.
  void tap(ReminderOpen open) => _opened.add(open);

  @override
  Future<Map<ReminderPermission, PermissionState>> permissions() async =>
      Map.of(states);

  @override
  Future<PermissionState> request(ReminderPermission permission) async {
    requested.add(permission);
    if (states[permission] == PermissionState.denied && grantOnRequest) {
      states[permission] = PermissionState.granted;
    }
    return states[permission] ?? PermissionState.notApplicable;
  }

  @override
  Future<void> schedule(
    ReminderGroup group,
    List<PlannedReminder> items, {
    required Set<String> open,
  }) async {
    scheduled[group] = items;
    openSubjects[group] = open;
  }

  @override
  Future<void> test(List<PlannedReminder> items) async => tests.add(items);

  @override
  Future<void> snooze(
    PlannedReminder item,
    Duration after,
    int snoozes,
  ) async => this.snoozes.add((item: item, after: after, snoozes: snoozes));

  @override
  Stream<ReminderOpen> get opened => _opened.stream;

  @override
  Future<ReminderOpen?> takeLaunch() async {
    final taken = launch;
    launch = null;
    return taken;
  }

  @override
  Future<void> previewTone(ReminderTone tone) async {}
}
