import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tide/config/app_constants.dart';
import 'package:tide/services/auth/demo_auth_service.dart';
import 'package:tide/services/device_flags.dart';
import 'package:tide/services/reminders/call_controller.dart';
import 'package:tide/services/reminders/reminder_plan.dart';
import 'package:tide/services/reminders/reminder_platform.dart';
import 'package:tide/services/reminders/reminder_settings.dart';
import 'package:tide/services/reminders/reminder_store.dart';
import 'package:tide/services/tasks/task_local.dart';
import 'package:tide/services/tide_store.dart';
import 'package:tide/services/tasks/task_store.dart';

/// Six in the morning today: every seed habit's reminder is still to come.
final DateTime _dawn = DateUtils.dateOnly(
  DateTime.now(),
).add(const Duration(hours: 6));

/// Long enough for the store's debounce to run out.
Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 450));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TideStore tide;
  late NoReminderPlatform platform;
  late ReminderStore reminders;
  late TaskStore tasks;

  void build({
    NoReminderPlatform? phone,
    ReminderSettings settings = const ReminderSettings(),
    bool signedIn = true,
  }) {
    tide = TideStore(
      auth: DemoAuthService(signedIn: signedIn),
      flags: DeviceFlags.memory(onboardingSeen: true),
    );
    platform = phone ?? NoReminderPlatform();
    reminders = ReminderStore(
      tide: tide,
      platform: platform,
      prefs: ReminderPrefs.memory(settings: settings),
      clock: () => _dawn,
      watchLifecycle: false,
    );
    tasks = TaskStore(
      tide: tide,
      local: MemoryTaskLocal(),
      reminders: reminders.taskReminders,
      clock: () => _dawn,
    );
    reminders.attachTasks(tasks);
    addTearDown(() {
      tasks.dispose();
      reminders.dispose();
      tide.dispose();
    });
  }

  List<PlannedReminder> habitPlan() =>
      platform.scheduled[ReminderGroup.habits] ?? const [];

  group('plans', () {
    test('the signed-in account\'s habits are handed to the phone', () async {
      build();
      await _settle();

      final subjects = habitPlan().map((r) => r.subjectId).toSet();
      expect(subjects, contains('morning-water'));
      expect(habitPlan().every((r) => r.accountId == 'demo-jules'), isTrue);
    });

    test('keeping a habit today takes today\'s reminder away', () async {
      build();
      await _settle();
      bool owedToday() => habitPlan().any(
        (r) =>
            r.subjectId == 'morning-water' &&
            DateUtils.isSameDay(r.dueAt, _dawn),
      );
      expect(owedToday(), isTrue);

      tide.log('morning-water', date: _dawn);
      await _settle();

      expect(owedToday(), isFalse);
      expect(
        platform.openSubjects[ReminderGroup.habits],
        isNot(contains('morning-water')),
      );
    });

    test('nobody signed in, nothing scheduled', () async {
      build(signedIn: false);
      await _settle();
      expect(habitPlan(), isEmpty);
    });

    test('switching reminders off empties both plans', () async {
      build();
      tasks.add(
        title: 'Call the plumber',
        reminders: [_dawn.add(const Duration(hours: 3))],
      );
      await _settle();
      expect(platform.scheduled[ReminderGroup.tasks], isNotEmpty);

      reminders.updateSettings(reminders.settings.copyWith(enabled: false));
      await _settle();

      expect(habitPlan(), isEmpty);
      expect(platform.scheduled[ReminderGroup.tasks], isEmpty);
    });

    test('a to-do reminder becomes a Beacon and a Lighthouse', () async {
      build();
      tasks.add(
        title: 'Call the plumber',
        reminders: [_dawn.add(const Duration(hours: 3))],
      );
      await _settle();

      expect(platform.scheduled[ReminderGroup.tasks]!.map((r) => r.kind), [
        ReminderKind.taskHeadsUp,
        ReminderKind.taskCall,
      ]);
    });
  });

  group('a call answered inside the app', () {
    test('a "later" is the one thing that reaches the phone', () async {
      build();
      await _settle();
      final call = habitPlan().firstWhere((r) => r.kind == ReminderKind.habitCall);
      final controller = InAppCallController(
        reminders: reminders,
        calls: [call],
        onClose: () {},
      );
      addTearDown(controller.dispose);

      await controller.resolve(call, const CallLater(45));
      await _settle();

      expect(platform.snoozes.single, (
        item: call,
        after: const Duration(minutes: 45),
        snoozes: 1,
      ));
    });

    test('hearing a call reaches nothing and changes nothing', () async {
      build();
      await _settle();
      final task = tasks.add(title: 'Post the parcel');
      final call = habitPlan().firstWhere((r) => r.kind == ReminderKind.habitCall);
      final controller = InAppCallController(
        reminders: reminders,
        calls: [call],
        onClose: () {},
      );
      addTearDown(controller.dispose);
      expect(tide.habitById(call.subjectId)!.isCompleteOn(_dawn), isFalse);

      await controller.resolve(call, const CallHeard());
      await _settle();

      expect(platform.snoozes, isEmpty);
      expect(tide.habitById(call.subjectId)!.isCompleteOn(_dawn), isFalse);
      expect(tasks.byId(task.id)!.isCompleted, isFalse);
      expect(tide.pendingHabitCue, isNull);
    });

    test('the last later is dropped rather than sent', () async {
      build();
      await _settle();
      final call = habitPlan().firstWhere((r) => r.kind == ReminderKind.habitCall);
      final phone = _SpyCallController(call, AppConstants.maxReminderSnoozes);

      expect(phone.canLater(call), isFalse);
      await phone.resolve(call, const CallLater(10));

      expect(phone.sent, isEmpty);
    });

    test('one later short of the cap is still sent', () async {
      build();
      await _settle();
      final call = habitPlan().firstWhere((r) => r.kind == ReminderKind.habitCall);
      final phone = _SpyCallController(
        call,
        AppConstants.maxReminderSnoozes - 1,
      );

      expect(phone.canLater(call), isTrue);
      await phone.resolve(call, const CallLater(10));

      expect(phone.sent, [const CallLater(10)]);
    });

    test('the cap is the phone\'s count, not this controller\'s', () async {
      build();
      await _settle();
      final plan = habitPlan().firstWhere((r) => r.kind == ReminderKind.habitCall);
      // A call put off on the lock screen comes back carrying the count the
      // book kept, with nothing in this controller to say so.
      final call = PlannedReminder.fromJson({
        ...plan.toJson(),
        'details': {
          ...plan.details,
          'snoozes': AppConstants.maxReminderSnoozes,
        },
      })!;
      final phone = _SpyCallController(call);

      expect(phone.snoozesTaken(call), AppConstants.maxReminderSnoozes);
      expect(phone.canLater(call), isFalse);
      await phone.resolve(call, const CallLater(10));

      expect(phone.sent, isEmpty);
    });
  });

  group('permissions', () {
    test(
      'a refused permission raises the banner until it is granted',
      () async {
        build(
          phone: NoReminderPlatform(
            permissionsAsked: const [
              ReminderPermission.notifications,
              ReminderPermission.battery,
            ],
          ),
        );
        await _settle();
        expect(reminders.missing, [ReminderPermission.notifications]);
        expect(reminders.needsAttention, isTrue);

        await reminders.request(ReminderPermission.notifications);

        expect(reminders.missing, isEmpty);
        expect(reminders.needsAttention, isFalse);
        expect(reminders.grantedCount, 1, reason: 'battery is still to ask');
      },
    );

    test('no reminders in use, no banner', () async {
      build(
        phone: NoReminderPlatform(
          permissionsAsked: const [ReminderPermission.notifications],
        ),
        settings: const ReminderSettings(enabled: false),
      );
      await _settle();
      expect(reminders.needsAttention, isFalse);
    });

    test('the banner can be waved away for the session', () async {
      build(
        phone: NoReminderPlatform(
          permissionsAsked: const [ReminderPermission.notifications],
        ),
      );
      await _settle();
      reminders.dismissBanner();
      expect(reminders.needsAttention, isFalse);
    });
  });

  test(
    'the test button rings a heads-up and a call for a real habit',
    () async {
      build();
      await reminders.testHabit();

      final rung = platform.tests.single;
      expect(rung.map((r) => r.kind), [
        ReminderKind.habitHeadsUp,
        ReminderKind.habitCall,
      ]);
      expect(rung.every((r) => r.test), isTrue);
      expect(tide.habitById(rung.first.subjectId), isNotNull);
    },
  );
}

/// A call controller that only records what it was asked to send, so the cap
/// on "laters" can be tested where the phone counts them — the lock screen's
/// [NativeCallController] reads the count from the book on every wake-up.
class _SpyCallController extends CallController {
  _SpyCallController(PlannedReminder call, [int? taken]) {
    show([call], snoozes: {call.key: ?taken});
  }

  final List<CallOutcome> sent = [];

  @override
  Future<void> send(PlannedReminder call, CallOutcome outcome) async =>
      sent.add(outcome);

  @override
  Future<void> openApp(PlannedReminder? call) async {}

  @override
  Future<void> finish() async {}
}
