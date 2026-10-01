import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';

import '../../config/reminder_copy.dart';
import '../../services/habits/habit_rows.dart';
import '../../services/haptics.dart';
import '../../services/models/tide_glyph.dart';
import '../../services/reminders/call_controller.dart';
import '../../services/reminders/reminder_plan.dart';
import '../../theme/tide_colors.dart';
import '../../theme/tide_gradients.dart';
import '../../theme/tide_motion.dart';
import '../../theme/tide_typography.dart';
import '../../widgets/habit_glyph.dart';
import '../../widgets/press_scale.dart';
import '../../widgets/ripple_burst.dart';
import 'widgets/call_chip.dart';
import 'widgets/call_clock.dart';
import 'widgets/call_water.dart';
import 'widgets/habit_orb.dart';
import 'widgets/reminder_bar.dart';
import 'widgets/wave_marks.dart';

/// "Tide Call": a habit's reminder, full screen, at its time.
///
/// **The whole screen is the gesture.** The same hand the app already
/// taught: swipe up and the water rises under the finger — let go high enough
/// and the call is heard, the water surges to the top and a ripple runs out
/// from the orb. Swipe the orb away to the left to put it off for however
/// long the bar under it is set to, and the water drains out.
///
/// **Nothing is decided here.** Hearing a reminder is not the same as keeping
/// a habit, and the screen has no way to tell the difference: the answer goes
/// to the [controller] the moment it is given — the ringing stops as the
/// water reaches the top — and the screen plays its farewell before retiring
/// the call. There is no done, no skip and no tomorrow, and a habit with no
/// freezes left has nothing to lose by not being asked.
class TideCallScreen extends StatefulWidget {
  const TideCallScreen({
    super.key,
    required this.controller,
    required this.calls,
    this.clock,
  });

  final CallController controller;

  /// The habit calls still on screen, in the order they rang.
  final List<PlannedReminder> calls;

  /// For the "back at" line, and for tests. Nothing else in the call reads
  /// the clock: the face is a countdown, not a time.
  final DateTime Function()? clock;

  @override
  State<TideCallScreen> createState() => _TideCallScreenState();
}

enum _Answer { none, heard, heardAll, later }

class _TideCallScreenState extends State<TideCallScreen>
    with TickerProviderStateMixin {
  /// Where the water rests while the call rings: the lower two fifths.
  static const double _rest = 0.4;

  final ValueNotifier<double> _time = ValueNotifier<double>(0);
  final ValueNotifier<double> _level = ValueNotifier<double>(0);
  Ticker? _ticker;

  late final AnimationController _entry = AnimationController(
    vsync: this,
    duration: TideMotion.callEntry,
  );

  /// The water above or below its resting level: the finger's pull, the
  /// surge, the drain.
  late final AnimationController _water = AnimationController.unbounded(
    vsync: this,
  );

  /// The orb's sideways travel, in pixels. Negative is toward a "later".
  late final AnimationController _slide = AnimationController.unbounded(
    vsync: this,
  );

  late final AnimationController _farewell = AnimationController(
    vsync: this,
    duration: TideMotion.celebrateIn,
  );

  String? _currentKey;
  _Answer _answer = _Answer.none;

  /// What the bar is offering to put this call off by. Kept here because the
  /// orb's sideways gesture means the same thing as the chip under it.
  int _minutes = 0;

  int _ripple = 0;
  bool _still = false;
  double _rideOrigin = 0;
  int _answeredCount = 0;

  String? _hint;
  Timer? _hintTimer;

  PlannedReminder get _call => widget.calls.firstWhere(
    (c) => c.key == _currentKey,
    orElse: () => widget.calls.first,
  );

  DateTime _now() => (widget.clock ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    _currentKey = widget.calls.first.key;
    _minutes = widget.calls.first.options.snoozeMinutes;
    _entry.addListener(_syncLevel);
    _water.addListener(_syncLevel);
    _entry.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = MediaQuery.disableAnimationsOf(context);
    if (_still) {
      _ticker?.stop();
      _entry.value = 1;
    } else {
      _ticker ??= createTicker((elapsed) {
        _time.value = elapsed.inMicroseconds / 1e6;
      });
      if (!_ticker!.isActive) _ticker!.start();
    }
  }

  @override
  void didUpdateWidget(TideCallScreen old) {
    super.didUpdateWidget(old);
    if (widget.calls.isEmpty) return;
    if (widget.calls.any((c) => c.key == _currentKey)) return;
    // The call on screen has been retired and another is still ringing: it
    // comes up the way the first one did, with its own habit's idea of how
    // long a "later" is.
    _currentKey = widget.calls.first.key;
    _answer = _Answer.none;
    _minutes = widget.calls.first.options.snoozeMinutes;
    _water.value = 0;
    _slide.value = 0;
    _farewell.value = 0;
    if (_still) {
      _entry.value = 1;
    } else {
      _entry.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _ticker?.dispose();
    _entry.dispose();
    _water.dispose();
    _slide.dispose();
    _farewell.dispose();
    _time.dispose();
    _level.dispose();
    super.dispose();
  }

  void _syncLevel() {
    _level.value =
        _rest * TideMotion.callEntryCurve.transform(_entry.value) +
        _water.value;
  }

  Duration _motion(Duration duration) => _still ? Duration.zero : duration;

  void _flash(String hint) {
    _hintTimer?.cancel();
    setState(() => _hint = hint);
    _hintTimer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _hint = null);
    });
  }

  // --- Answers ----------------------------------------------------------------

  /// Heard: the ringing stops and the habit is still open. The surge is the
  /// whole celebration now — there is no streak to count up to, because
  /// nothing was kept.
  Future<void> _heard() async {
    if (_answer != _Answer.none) return;
    final call = _call;
    setState(() => _answer = _Answer.heard);
    unawaited(TideHaptics.heavyImpact());
    unawaited(widget.controller.resolve(call, const CallHeard()));
    await _water.animateTo(
      1.12 - _rest,
      duration: _motion(TideMotion.callSurge),
      curve: TideMotion.callSurgeCurve,
    );
    await _farewellThen(() => widget.controller.retire(call), ripple: true);
  }

  /// Every habit ringing at this minute, heard at once. Same as [ _heard] for
  /// each of them, and nothing logged.
  Future<void> _heardAll() async {
    if (_answer != _Answer.none) return;
    final calls = List.of(widget.calls);
    setState(() {
      _answer = _Answer.heardAll;
      _answeredCount = calls.length;
    });
    unawaited(TideHaptics.heavyImpact());
    for (final call in calls) {
      unawaited(widget.controller.resolve(call, const CallHeard()));
    }
    await _water.animateTo(
      1.12 - _rest,
      duration: _motion(TideMotion.callSurge),
      curve: TideMotion.callSurgeCurve,
    );
    await _farewellThen(() {
      for (final call in calls) {
        widget.controller.retire(call);
      }
    }, ripple: true);
  }

  /// Put off for [minutes] — the bar's choice, whether it came from a chip or
  /// from the orb being swiped away.
  Future<void> _later() async {
    if (_answer != _Answer.none) return;
    final call = _call;
    if (!widget.controller.canLater(call)) {
      _flash(ReminderCopy.lastLaterToday);
      await _springBack();
      return;
    }
    setState(() => _answer = _Answer.later);
    unawaited(TideHaptics.mediumImpact());
    unawaited(widget.controller.resolve(call, CallLater(_minutes)));
    final width = MediaQuery.sizeOf(context).width;
    await Future.wait([
      _water.animateTo(
        -_rest,
        duration: _motion(TideMotion.callDrain),
        curve: TideMotion.callDrainCurve,
      ),
      _slide.animateTo(
        -width,
        duration: _motion(TideMotion.callDrain),
        curve: TideMotion.callDrainCurve,
      ),
    ]);
    await _farewellThen(() => widget.controller.retire(call));
  }

  Future<void> _farewellThen(
    VoidCallback retire, {
    bool ripple = false,
    Duration hold = TideMotion.callFarewell,
  }) async {
    if (!mounted) return;
    if (ripple) setState(() => _ripple++);
    unawaited(_farewell.forward());
    await Future<void>.delayed(hold);
    if (mounted) retire();
  }

  Future<void> _springBack() => _slide.animateTo(
    0,
    duration: _motion(TideMotion.swipeCancel),
    curve: TideMotion.swipeCancelCurve,
  );

  // --- Gestures ---------------------------------------------------------------

  void _rideStart(DragStartDetails details) {
    if (_answer != _Answer.none) return;
    _water.stop();
    _rideOrigin = details.globalPosition.dy + _water.value * _rideSpan;
  }

  double get _rideSpan => MediaQuery.sizeOf(context).height * 0.5;

  void _rideUpdate(DragUpdateDetails details) {
    if (_answer != _Answer.none) return;
    final travel = _rideOrigin - details.globalPosition.dy;
    final fraction = (travel / _rideSpan).clamp(0.0, 1.0);
    _water.value = (1 - _rest) * fraction;
  }

  void _rideEnd(DragEndDetails details) {
    if (_answer != _Answer.none) return;
    final fraction = _water.value / (1 - _rest);
    final flung = (details.primaryVelocity ?? 0) < -900 && fraction > 0.2;
    if (fraction >= TideMotion.rideThreshold || flung) {
      unawaited(_heard());
      return;
    }
    _water.animateTo(
      0,
      duration: _motion(TideMotion.swipeCancel),
      curve: TideMotion.swipeCancelCurve,
    );
  }

  void _slideUpdate(DragUpdateDetails details) {
    if (_answer != _Answer.none) return;
    _slide.value = math.min(0, _slide.value + details.delta.dx);
  }

  void _slideEnd(DragEndDetails details) {
    if (_answer != _Answer.none) return;
    final width = MediaQuery.sizeOf(context).width;
    if (_slide.value < -width * 0.26 || (details.primaryVelocity ?? 0) < -800) {
      unawaited(_later());
    } else {
      unawaited(_springBack());
    }
  }

  // --- Build ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final call = _call;
    final answering = _answer != _Answer.none;

    return RippleBurst(
      trigger: _ripple,
      color: TideColors.lantern,
      accent: TideColors.palette.flare,
      particles: true,
      intensity: 2.2,
      clip: false,
      origin: const Alignment(0, -0.08),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: _rideStart,
        onVerticalDragUpdate: _rideUpdate,
        onVerticalDragEnd: _rideEnd,
        child: ColoredBox(
          color: TideColors.trench,
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: _entry,
              curve: TideMotion.callEntryCurve,
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: TideGradients.callDepth,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: CallWater(level: _level, time: _time, still: _still),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: answering,
                    child: AnimatedBuilder(
                      animation: _farewell,
                      builder: (context, child) =>
                          Opacity(opacity: 1 - _farewell.value, child: child),
                      child: SafeArea(child: _content(call)),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: FadeTransition(
                      opacity: _farewell,
                      child: SafeArea(
                        child: Center(child: _farewellCopy()),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(PlannedReminder call) {
    return LayoutBuilder(
      builder: (context, box) {
        final compact = box.maxHeight < 720;
        final orb = math
            .min(box.maxWidth * 0.5, box.maxHeight * 0.25)
            .clamp(120.0, 210.0);
        final day =
            HabitRows.parseDay(call.details['day']) ??
            DateUtils.dateOnly(call.dueAt);

        // Three groups spread down the screen. When large text will not fit,
        // the whole face is scaled down rather than scrolled: a scroll view
        // would take the upward swipe for itself, and the swipe is the call.
        // `spaceBetween` inside a minimum height rather than spacers inside
        // an intrinsic height, which cannot measure a layout builder.
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: box.maxWidth,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: box.maxHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        const SizedBox(height: 12),
                        _TopBar(
                          test: call.test,
                          onOpen: () => widget.controller.openApp(call),
                        ),
                        SizedBox(height: compact ? 8 : 16),
                        CallClock(size: compact ? 58 : 76),
                        if (widget.calls.length > 1) ...[
                          const SizedBox(height: 18),
                          _OrbStack(
                            calls: widget.calls,
                            current: call.key,
                            onSelect: (key) =>
                                setState(() => _currentKey = key),
                            onHeardAll: _heardAll,
                          ),
                        ],
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        children: [
                          _orb(call, orb),
                          SizedBox(height: compact ? 16 : 26),
                          Text(
                            call.title,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TideType.hero.copyWith(fontSize: 30),
                          ),
                          const SizedBox(height: 8),
                          AnimatedSwitcher(
                            duration: TideMotion.tabSwitch,
                            child: Text(
                              _hint ?? call.copy['subtitle'] ?? '',
                              key: ValueKey(_hint ?? 'subtitle'),
                              textAlign: TextAlign.center,
                              style: TideType.bodyMuted.copyWith(
                                color: _hint == null ? null : TideColors.bone,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          WaveMarks(
                            marks: WaveMarks.parse(call.details['week']),
                            lastDay: day,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        _RideHint(level: _level, rest: _rest, still: _still),
                        SizedBox(height: compact ? 10 : 16),
                        ReminderBar(
                          minutes: _minutes,
                          canLater: widget.controller.canLater(call),
                          onMinutes: (minutes) =>
                              setState(() => _minutes = minutes),
                          onLater: _later,
                          onHeard: _heard,
                        ),
                        const SizedBox(height: 6),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _orb(PlannedReminder call, double size) {
    final glyph =
        TideGlyph.values.asNameMap()[call.details['glyph']] ?? TideGlyph.dot;
    final canLater = widget.controller.canLater(call);

    return Semantics(
      container: true,
      button: true,
      label: '${call.title} reminder. Double-tap to say you have heard it.',
      onTap: _heard,
      customSemanticsActions: {
        if (canLater)
          CustomSemanticsAction(
            label: 'Put it off ${ReminderCopy.minutes(_minutes)}',
          ): _later,
        const CustomSemanticsAction(label: 'Got it, thanks'): _heard,
      },
      child: ExcludeSemantics(
        child: GestureDetector(
          onHorizontalDragUpdate: _slideUpdate,
          onHorizontalDragEnd: _slideEnd,
          onTap: () => _flash(
            'Swipe up to say you\'ve heard it · swipe the orb left to put it off',
          ),
          child: AnimatedBuilder(
            animation: Listenable.merge([_slide, _time]),
            builder: (context, child) {
              final period = TideMotion.callBob.inMilliseconds / 1000;
              final bob = _still
                  ? 0.0
                  : math.sin(_time.value * 2 * math.pi / period) * 4;
              final away = (-_slide.value / (size * 1.2)).clamp(0.0, 1.0);
              return Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // The "later" surfacing behind the orb as it is pushed
                  // away: whatever the bar under it is set to right now.
                  Opacity(
                    opacity:
                        (away * 2.4).clamp(0.0, 1.0) *
                        (_answer == _Answer.none ? 1 : 0),
                    child: Text(
                      canLater
                          ? 'Back in ${ReminderCopy.minutes(_minutes)}'
                          : ReminderCopy.lastLaterToday,
                      style: TideType.label.copyWith(color: TideColors.silt),
                    ),
                  ),
                  Transform.translate(
                    offset: Offset(_slide.value, bob),
                    child: Opacity(opacity: 1 - away * 0.85, child: child),
                  ),
                ],
              );
            },
            child: HabitOrb(
              glyph: glyph,
              size: size,
              time: _time,
              still: _still,
            ),
          ),
        ),
      ),
    );
  }

  /// What is said once the ringing has stopped: a time to come back to, or
  /// that it was heard and the habit is still there.
  Widget _farewellCopy() {
    return switch (_answer) {
      _Answer.later => _Line(
        ReminderCopy.backAt(_now().add(Duration(minutes: _minutes))),
      ),
      _Answer.heard => const _Line(ReminderCopy.heardHabit),
      _Answer.heardAll => _Line('All $_answeredCount heard'),
      _Answer.none => const SizedBox.shrink(),
    };
  }
}

class _Line extends StatelessWidget {
  const _Line(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TideType.hero.copyWith(fontSize: 26),
      ),
    );
  }
}

/// The test badge, when there is one, and the way into the app.
class _TopBar extends StatelessWidget {
  const _TopBar({required this.test, required this.onOpen});

  final bool test;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (test) const Flexible(child: CallTestBadge()) else const Spacer(),
        if (test) const SizedBox(width: 12),
        Semantics(
          button: true,
          label: 'Open Tide',
          child: ExcludeSemantics(
            child: PressScale(
              onTap: onOpen,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Open Tide', maxLines: 1, style: TideType.labelMuted),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.north_east_rounded,
                      size: 14,
                      color: TideColors.silt,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Several habits at the same minute: their orbs in a row, the one being
/// answered ringed, and one button to hear them all.
class _OrbStack extends StatelessWidget {
  const _OrbStack({
    required this.calls,
    required this.current,
    required this.onSelect,
    required this.onHeardAll,
  });

  final List<PlannedReminder> calls;
  final String current;
  final ValueChanged<String> onSelect;
  final VoidCallback onHeardAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final call in calls.take(5))
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Semantics(
              button: true,
              selected: call.key == current,
              label: call.title,
              child: ExcludeSemantics(
                child: PressScale(
                  onTap: () => onSelect(call.key),
                  child: AnimatedContainer(
                    duration: TideMotion.tabSwitch,
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: TideColors.shelf,
                      border: Border.all(
                        width: call.key == current ? 2 : 1,
                        color: call.key == current
                            ? TideColors.lantern
                            : TideColors.hairline,
                      ),
                    ),
                    child: HabitGlyph(
                      glyph:
                          TideGlyph.values.asNameMap()[call.details['glyph']] ??
                          TideGlyph.dot,
                      size: 17,
                    ),
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(width: 10),
        CallChip(
          label: 'Heard all',
          icon: Icons.hearing_rounded,
          accent: true,
          onTap: onHeardAll,
        ),
      ],
    );
  }
}

/// "Swipe up to ride the wave", and what the water is doing under the
/// finger once a swipe has started.
class _RideHint extends StatelessWidget {
  const _RideHint({
    required this.level,
    required this.rest,
    required this.still,
  });

  final ValueNotifier<double> level;
  final double rest;
  final bool still;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: level,
      builder: (context, value, _) {
        final fraction = ((value - rest) / (1 - rest)).clamp(0.0, 1.0);
        // "Ride the wave" is the old language: the water is not carrying
        // anything anywhere now. It rises because the call was heard.
        final text = fraction >= TideMotion.rideThreshold
            ? 'Let go when you\'ve heard it'
            : fraction > 0.08
            ? 'Keep going…'
            : 'Swipe up to say you\'ve heard it';
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.translate(
              offset: Offset(0, still ? 0 : -8 * fraction),
              child: Icon(
                Icons.keyboard_double_arrow_up_rounded,
                size: 22,
                color: TideColors.lantern.withValues(
                  alpha: 0.55 + 0.45 * fraction,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              text,
              style: TideType.label.copyWith(
                color: fraction >= TideMotion.rideThreshold
                    ? TideColors.lantern
                    : TideColors.bone,
              ),
            ),
          ],
        );
      },
    );
  }
}
