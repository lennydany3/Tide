import 'package:flutter/material.dart';

import '../../../config/app_constants.dart';
import '../../../services/models/habit.dart';
import '../../../theme/tide_colors.dart';
import '../../../theme/tide_elevation.dart';
import '../../../theme/tide_motion.dart';
import '../../../theme/tide_typography.dart';
import '../../../widgets/press_scale.dart';
import '../../../widgets/tide_button.dart';
import '../../../widgets/tide_sheet.dart';

/// A number pad for "how long until I come back", raised from a call.
///
/// A pad rather than a picker because the answers are not a small set: a
/// reminder can be put off by anything from a minute to an afternoon, and
/// typing the number is quicker than scrolling a wheel for somebody only half
/// awake. Capped at [AppConstants.reminderLaterMaxMinutes] for the same
/// reason the presets stop at an hour: past an afternoon a reminder is not
/// interrupting anybody any more, it is just late.
///
/// **The five presets are not repeated here.** They are on the bar this was
/// raised from, a tap away and still visible behind the sheet; listing them
/// again would put two answers to the same question on one screen and push the
/// pad — the only thing in here that is not a preset — off the bottom of it.
Future<int?> showLaterSheet(BuildContext context, {required int minutes}) {
  return Navigator.of(context, rootNavigator: true).push<int>(
    PageRouteBuilder<int>(
      opaque: false,
      barrierColor: null,
      transitionDuration: TideMotion.sheetIn,
      reverseTransitionDuration: TideMotion.sheetIn,
      pageBuilder: (_, animation, _) => tideSheetTransition(
        context,
        animation,
        animation,
        _Route(minutes),
      ),
    ),
  );
}

class _Route extends StatefulWidget {
  const _Route(this.initial);

  /// What the call was already offering, so the sheet opens on it.
  final int initial;

  @override
  State<_Route> createState() => _RouteState();
}

class _RouteState extends State<_Route> {
  String _entry = '';

  int? get _typed => _entry.isEmpty ? null : int.tryParse(_entry);

  /// What the pad is proposing: the typed digits while there are any, and the
  /// number the call came in with until then.
  int get _minutes => (_typed ?? widget.initial).clamp(
    1,
    AppConstants.reminderLaterMaxMinutes,
  );

  void _digit(String digit) {
    if (_entry.length >= 3) return;
    setState(() => _entry = _entry == '0' ? digit : _entry + digit);
  }

  void _delete() {
    if (_entry.isEmpty) return;
    setState(() => _entry = _entry.substring(0, _entry.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    return _LaterSheet(
      entry: _entry,
      minutes: _minutes,
      typing: _typed != null,
      onDigit: _digit,
      onDelete: _delete,
      onPick: (minutes) => Navigator.of(context).pop(minutes),
    );
  }
}

class _LaterSheet extends StatelessWidget {
  const _LaterSheet({
    required this.entry,
    required this.minutes,
    required this.typing,
    required this.onDigit,
    required this.onDelete,
    required this.onPick,
  });

  final String entry;
  final int minutes;
  final bool typing;
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    return TideSheet(
      eyebrow: 'Put it off',
      title: 'Remind me in',
      onDismiss: () => Navigator.of(context).pop(),
      maxHeightFactor: 0.72,
      footer: TideButton(
        label: 'Set for ${Minutes.label(minutes)}',
        onPressed: () => onPick(minutes),
      ),
      // No scroll view: a pad that has to be scrolled to is a pad nobody
      // reaches, and this much of it always fits — the sheet is capped at
      // 72% of the screen, and the four rows of keys are fixed height.
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          4,
          20,
          12 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Readout(entry: entry, minutes: minutes, typing: typing),
            const SizedBox(height: 16),
            Text(
              'Any time up to '
              '${Minutes.label(AppConstants.reminderLaterMaxMinutes)}.',
              textAlign: TextAlign.center,
              style: TideType.bodyMuted,
            ),
            const SizedBox(height: 16),
            _Keypad(
              canDelete: entry.isNotEmpty,
              onDigit: onDigit,
              onDelete: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

/// The number the pad is proposing, big enough to read across a room.
class _Readout extends StatelessWidget {
  const _Readout({required this.entry, required this.minutes, required this.typing});

  final String entry;
  final int minutes;
  final bool typing;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: TideMotion.tabSwitch,
      curve: TideMotion.tabCurve,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: typing
            ? TideColors.lantern.withValues(alpha: 0.12)
            : TideColors.trench,
        borderRadius: TideElevation.radius12,
        border: Border.all(
          color: typing ? TideColors.lantern.withValues(alpha: 0.4) : Colors.transparent,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            entry.isEmpty ? '—' : entry,
            style: TideType.gauge(34, color: TideColors.bone),
          ),
          const SizedBox(height: 2),
          Text(
            Minutes.label(minutes),
            style: TideType.label.copyWith(
              color: typing ? TideColors.lantern : TideColors.silt,
            ),
          ),
        ],
      ),
    );
  }
}

/// Three rows of digits, then a blank where a phone's own pad leaves one, 0,
/// and delete. A thumb that knows one pad already knows this one.
class _Keypad extends StatelessWidget {
  const _Keypad({
    required this.canDelete,
    required this.onDigit,
    required this.onDelete,
  });

  final bool canDelete;
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;

  static const List<List<String>> _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
  ];

  Widget _row(List<Widget> keys) => Row(
    children: [
      for (var i = 0; i < keys.length; i++) ...[
        if (i > 0) const SizedBox(width: 8),
        Expanded(child: keys[i]),
      ],
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in _rows) ...[
          _row([
            for (final digit in row)
              _Key(
                key: ValueKey('later-$digit'),
                semanticLabel: digit,
                onTap: () => onDigit(digit),
                child: Text(
                  digit,
                  style: TideType.gauge(20, color: TideColors.bone),
                ),
              ),
          ]),
          const SizedBox(height: 8),
        ],
        _row([
          // The gap a phone's own pad leaves where a function key would go.
          const SizedBox.shrink(),
          _Key(
            key: const ValueKey('later-0'),
            semanticLabel: '0',
            onTap: () => onDigit('0'),
            child: Text('0', style: TideType.gauge(20, color: TideColors.bone)),
          ),
          _Key(
            key: const ValueKey('later-delete'),
            semanticLabel: 'Delete',
            enabled: canDelete,
            onTap: onDelete,
            child: Icon(
              Icons.backspace_outlined,
              size: 19,
              color: TideColors.silt,
            ),
          ),
        ]),
      ],
    );
  }
}

/// One key. Recessed like every well in a sheet, so the pad reads as part of
/// it rather than a keyboard that slid over it.
class _Key extends StatelessWidget {
  const _Key({
    super.key,
    required this.semanticLabel,
    required this.onTap,
    required this.child,
    this.enabled = true,
  });

  final String semanticLabel;
  final VoidCallback onTap;
  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      enabled: enabled,
      onTap: onTap,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: semanticLabel,
        excludeSemantics: true,
        child: AnimatedOpacity(
          opacity: enabled ? 1 : 0.4,
          duration: TideMotion.tabSwitch,
          child: Container(
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: TideColors.trench,
              borderRadius: TideElevation.radius12,
              border: Border.all(color: TideColors.hairline),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
