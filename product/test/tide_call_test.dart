import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tide/config/app_constants.dart';
import 'package:tide/config/reminder_copy.dart';
import 'package:tide/screens/tide_call/call_deck.dart';
import 'package:tide/services/auth/demo_auth_service.dart';
import 'package:tide/services/device_flags.dart';
import 'package:tide/services/reminders/call_controller.dart';
import 'package:tide/services/reminders/reminder_plan.dart';
import 'package:tide/services/reminders/reminder_platform.dart';
import 'package:tide/services/reminders/reminder_settings.dart';
import 'package:tide/services/reminders/reminder_store.dart';
import 'package:tide/services/tasks/task.dart';
import 'package:tide/services/tasks/task_local.dart';
import 'package:tide/services/tasks/task_store.dart';
import 'package:tide/services/tide_store.dart';
import 'package:tide/theme/tide_theme.dart';
import 'package:tide/widgets/tide_sheet.dart';

/// Pumps in small steps: the call screens chain an animation into a farewell
/// timer into a retire, and never settle — the water keeps moving, the beam
/// keeps sweeping.
Future<void> _run(WidgetTester tester, [int ms = 2600]) async {
  for (var elapsed = 0; elapsed < ms; elapsed += 100) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Just long enough for the surge, so the line said while the ringing is
/// stopping is still on screen.
Future<void> _throughAnswer(WidgetTester tester) async {
  for (var elapsed = 0; elapsed < 1100; elapsed += 100) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

class _Harness {
  _Harness() {
    tide = TideStore(
      auth: DemoAuthService(signedIn: true),
      flags: DeviceFlags.memory(onboardingSeen: true),
    );
    platform = NoReminderPlatform();
    reminders = ReminderStore(
      tide: tide,
      platform: platform,
      prefs: ReminderPrefs.memory(),
      watchLifecycle: false,
    );
    tasks = TaskStore(
      tide: tide,
      local: MemoryTaskLocal(),
      reminders: reminders.taskReminders,
    );
    reminders.attachTasks(tasks);
  }

  late final TideStore tide;
  late final NoReminderPlatform platform;
  late final ReminderStore reminders;
  late final TaskStore tasks;
  bool closed = false;

  InAppCallController controller(List<PlannedReminder> calls) =>
      InAppCallController(
        reminders: reminders,
        calls: calls,
        onClose: () => closed = true,
      );

  PlannedReminder habitCall(String habitId) {
    final habit = tide.habitById(habitId)!;
    final now = DateTime.now();
    final call = ReminderPlanner.habitTest(
      habit,
      reminders.settings,
      now: now,
    ).last;
    // A real call, not a test: only a test's answers are held back.
    return PlannedReminder.fromJson({
      ...call.toJson(),
      'key': 'h:$habitId:call',
      'test': false,
      'account': tide.account!.id,
    })!;
  }

  PlannedReminder taskCall(Task task) {
    final call = ReminderPlanner.taskTest(
      task,
      reminders.settings,
      now: DateTime.now(),
    ).last;
    return PlannedReminder.fromJson({
      ...call.toJson(),
      'key': 't:${task.id}:call',
      'test': false,
      'account': tide.account!.id,
    })!;
  }

  void dispose() {
    tasks.dispose();
    reminders.dispose();
    tide.dispose();
  }
}

/// On a phone-sized screen, set on the view rather than with
/// `setSurfaceSize`, so the tree's [MediaQuery] agrees with the boxes the
/// screens were laid out at — the orb's "put it off" threshold is a fraction
/// of the width, and a stale 800-wide one never lets a swipe through.
Future<void> _show(WidgetTester tester, CallController controller) async {
  tester.view.physicalSize = const Size(400, 860);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: TideTheme.current,
      home: CallDeck(controller: controller),
    ),
  );
  await tester.pump(const Duration(milliseconds: 900));
}

void main() {
  late _Harness harness;

  setUp(() => harness = _Harness());
  tearDown(() => harness.dispose());

  group('Tide Call', () {
    testWidgets('asks one question: heard, or remind me in', (tester) async {
      final controller = harness.controller([
        harness.habitCall('morning-water'),
      ]);
      await _show(tester, controller);

      expect(find.text('Morning water'), findsOneWidget);
      expect(find.textContaining('Day '), findsOneWidget);
      expect(find.text('Remind me in'), findsOneWidget);
      for (final choice in AppConstants.reminderLaterChoices) {
        expect(find.text(ReminderCopy.minutes(choice)), findsOneWidget);
      }
      expect(find.text('Later…'), findsOneWidget);
      expect(find.text('Got it, thanks'), findsOneWidget);
      expect(find.text('Swipe up to say you\'ve heard it'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          RegExp('Double-tap to say you have heard it'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('no done, no skip, no tomorrow', (tester) async {
      final controller = harness.controller([
        harness.habitCall('morning-water'),
      ]);
      await _show(tester, controller);

      for (final gone in [
        'Done',
        'Done all',
        'Skip today',
        'Dismiss',
        'Tomorrow',
        'Undo',
      ]) {
        expect(
          find.text(gone),
          findsNothing,
          reason: '"$gone" is not one of the two answers a call takes',
        );
      }
    });

    testWidgets('hearing it stops the ringing and logs nothing', (
      tester,
    ) async {
      final controller = harness.controller([
        harness.habitCall('morning-water'),
      ]);
      await _show(tester, controller);
      expect(
        harness.tide.habitById('morning-water')!.isCompleteOn(DateTime.now()),
        isFalse,
      );

      await tester.tap(find.text('Got it, thanks'));
      await _throughAnswer(tester);

      expect(find.text(ReminderCopy.heardHabit), findsOneWidget);
      expect(harness.platform.snoozes, isEmpty, reason: 'heard sends nothing');
      expect(
        harness.tide.habitById('morning-water')!.isCompleteOn(DateTime.now()),
        isFalse,
        reason: 'a reminder is not a decision about the day',
      );
      expect(harness.tide.pendingHabitCue, isNull);

      await _run(tester);
      expect(harness.closed, isTrue);
    });

    testWidgets('swiping up hears it, and writes nothing', (tester) async {
      final controller = harness.controller([
        harness.habitCall('morning-water'),
      ]);
      await _show(tester, controller);

      await tester.dragFrom(const Offset(200, 780), const Offset(0, -420));
      await _run(tester);

      expect(harness.platform.snoozes, isEmpty);
      expect(
        harness.tide.habitById('morning-water')!.isCompleteOn(DateTime.now()),
        isFalse,
      );
      expect(harness.closed, isTrue);
    });

    testWidgets('a short swipe springs back and changes nothing', (
      tester,
    ) async {
      final controller = harness.controller([
        harness.habitCall('morning-water'),
      ]);
      await _show(tester, controller);

      await tester.dragFrom(const Offset(200, 780), const Offset(0, -60));
      await _run(tester, 1200);

      expect(harness.platform.snoozes, isEmpty);
      expect(harness.closed, isFalse);
    });

    testWidgets('a preset puts the habit off for exactly that long', (
      tester,
    ) async {
      final controller = harness.controller([
        harness.habitCall('morning-water'),
      ]);
      await _show(tester, controller);

      await tester.tap(find.text(ReminderCopy.minutes(10)));
      await _throughAnswer(tester);

      expect(find.textContaining('Back at '), findsOneWidget);
      expect(harness.platform.snoozes.single.after, const Duration(minutes: 10));
      expect(harness.platform.snoozes.single.snoozes, 1);

      await _run(tester);
      expect(harness.closed, isTrue);
    });

    testWidgets('Later… takes a number of its own', (tester) async {
      final controller = harness.controller([
        harness.habitCall('morning-water'),
      ]);
      await _show(tester, controller);

      await tester.tap(find.text('Later…'));
      await _run(tester, 800);

      expect(find.text('Set for 10 min'), findsOneWidget, reason: 'opens on it');
      await tester.tap(find.byKey(const ValueKey('later-9')));
      await tester.pump(const Duration(milliseconds: 60));
      await tester.tap(find.byKey(const ValueKey('later-0')));
      await tester.pump(const Duration(milliseconds: 60));
      expect(find.text('Set for 1 hr 30 min'), findsOneWidget);

      await tester.tap(find.text('Set for 1 hr 30 min'));
      await _run(tester);

      expect(
        harness.platform.snoozes.single.after,
        const Duration(minutes: 90),
      );
      expect(harness.closed, isTrue);
    });

    testWidgets('a Later… left alone is not a later at all', (tester) async {
      final controller = harness.controller([
        harness.habitCall('morning-water'),
      ]);
      await _show(tester, controller);

      await tester.tap(find.text('Later…'));
      await _run(tester, 800);
      await tester.tap(find.byType(SheetDismissButton));
      await _run(tester, 800);

      expect(harness.platform.snoozes, isEmpty);
      expect(harness.closed, isFalse, reason: 'the call is still ringing');
    });

    testWidgets('swiping the orb left puts it off for the bar\'s minutes', (
      tester,
    ) async {
      final call = harness.habitCall('morning-water');
      final controller = harness.controller([call]);
      await _show(tester, controller);

      final orb = find.bySemanticsLabel(
        RegExp('Double-tap to say you have heard it'),
      );
      await tester.dragFrom(tester.getCenter(orb), const Offset(-160, 0));
      await _run(tester);

      expect(
        harness.platform.snoozes.single.after,
        Duration(minutes: call.options.snoozeMinutes),
      );
      expect(harness.closed, isTrue);
    });

    testWidgets('the last later is spent, so only hearing it is offered', (
      tester,
    ) async {
      final call = harness.habitCall('morning-water');
      final spent = _SpentCallController(call);
      await _show(tester, spent);

      expect(find.text(ReminderCopy.lastLaterToday), findsWidgets);
      expect(find.text('Remind me in'), findsNothing);
      expect(find.text('Got it, thanks'), findsOneWidget);

      await tester.tap(find.text('Got it, thanks'));
      await _run(tester);

      expect(spent.sent, [const CallHeard()]);
    });

    testWidgets('two habits ring as one call and can be heard together', (
      tester,
    ) async {
      final controller = harness.controller([
        harness.habitCall('morning-water'),
        harness.habitCall('read-pages'),
      ]);
      await _show(tester, controller);
      // Read before answering, so the seed's own history cannot be mistaken
      // for something the call did.
      final today = DateUtils.dateOnly(DateTime.now());
      final before = {
        for (final id in ['morning-water', 'read-pages'])
          id: harness.tide.habitById(id)!.isCompleteOn(today),
      };

      expect(find.text('Heard all'), findsOneWidget);
      await tester.tap(find.text('Heard all'));
      await _throughAnswer(tester);

      expect(harness.platform.snoozes, isEmpty);
      for (final id in before.keys) {
        expect(
          harness.tide.habitById(id)!.isCompleteOn(today),
          before[id],
          reason: 'hearing a call is not keeping a habit',
        );
      }
      expect(harness.tide.pendingHabitCue, isNull);

      await _run(tester);
      expect(harness.closed, isTrue);
    });
  });

  group('Lighthouse', () {
    testWidgets('shows the to-do, and its steps as they stand', (
      tester,
    ) async {
      final task = harness.tasks.add(
        title: 'Post the parcel',
        subtasks: const [Subtask(id: 'label', title: 'Print the label')],
      );
      final controller = harness.controller([harness.taskCall(task)]);
      await _show(tester, controller);

      expect(find.text('Post the parcel'), findsOneWidget);
      expect(find.text('Print the label'), findsOneWidget);
      expect(find.text('0 of 1 steps done'), findsOneWidget);
      expect(find.text('Remind me in'), findsOneWidget);
      expect(find.text('Got it, thanks'), findsOneWidget);
      expect(find.text('Tomorrow'), findsNothing);
      expect(find.text('Slide to dock'), findsNothing);
    });

    testWidgets('a step on the call is not a control', (tester) async {
      final task = harness.tasks.add(
        title: 'Post the parcel',
        subtasks: const [Subtask(id: 'label', title: 'Print the label')],
      );
      final controller = harness.controller([harness.taskCall(task)]);
      await _show(tester, controller);

      await tester.tap(find.text('Print the label'));
      await _run(tester, 600);

      expect(
        harness.tasks.byId(task.id)!.subtasksLeft,
        1,
        reason: 'the list is where steps are ticked',
      );
      expect(harness.platform.snoozes, isEmpty);
    });

    testWidgets('hearing it rests the beam and writes nothing', (
      tester,
    ) async {
      final task = harness.tasks.add(
        title: 'Post the parcel',
        subtasks: const [Subtask(id: 'label', title: 'Print the label')],
      );
      final controller = harness.controller([harness.taskCall(task)]);
      await _show(tester, controller);

      await tester.tap(find.text('Got it, thanks'));
      await _throughAnswer(tester);

      expect(find.text(ReminderCopy.heardTask), findsOneWidget);
      expect(harness.platform.snoozes, isEmpty);
      expect(harness.tasks.byId(task.id)!.isCompleted, isFalse);
      expect(harness.tasks.byId(task.id)!.subtasksLeft, 1);

      await _run(tester);
      expect(harness.closed, isTrue);
    });

    testWidgets('a preset puts the to-do off, and nothing else', (
      tester,
    ) async {
      final task = harness.tasks.add(title: 'Water the plants');
      final controller = harness.controller([harness.taskCall(task)]);
      await _show(tester, controller);

      await tester.tap(find.text(ReminderCopy.minutes(30)));
      await _run(tester);

      expect(harness.platform.snoozes.single.after, const Duration(minutes: 30));
      expect(harness.tasks.byId(task.id)!.isCompleted, isFalse);
      expect(harness.closed, isTrue);
    });
  });

  testWidgets('habits ring before to-dos when both are due', (tester) async {
    final task = harness.tasks.add(title: 'Call the plumber');
    final controller = harness.controller([
      harness.taskCall(task),
      harness.habitCall('morning-water'),
    ]);
    await _show(tester, controller);

    expect(find.text('Morning water'), findsOneWidget);
    expect(find.text('Call the plumber'), findsNothing);

    await tester.tap(find.text('Got it, thanks'));
    await _run(tester);

    expect(find.text('Call the plumber'), findsOneWidget);
    expect(harness.closed, isFalse);
  });
}

/// A call whose "laters" are already spent, so the bar has only one answer
/// left to offer — the state a lock-screen call reaches after its last one.
class _SpentCallController extends CallController {
  _SpentCallController(PlannedReminder call) {
    show([
      call,
    ], snoozes: {call.key: AppConstants.maxReminderSnoozes});
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
