import 'package:flutter/material.dart';

import '../../../config/app_constants.dart';
import '../../../config/reminder_copy.dart';
import '../../../theme/tide_colors.dart';
import '../../../theme/tide_elevation.dart';
import '../../../theme/tide_typography.dart';
import '../../../widgets/press_scale.dart';
import 'call_chip.dart';
import 'later_sheet.dart';

/// The controls under a call: put it off, or say you heard it.
///
/// **A call asks one question, so this asks one question.** Put it off by how
/// much, or hear it and go back to sleep. There is no done, no skip and no
/// tomorrow here, and that is the design rather than a missing feature: being
/// reminded is not a decision about the day, and a reminder that logs a habit
/// is a reminder that gets switched off.
///
/// The same bar is under both calls, because the question does not change
/// with the scene. What changes is only the wording of the two answers — what
/// a habit hears back is not what a to-do hears back.
class ReminderBar extends StatelessWidget {
  const ReminderBar({
    super.key,
    required this.minutes,
    required this.canLater,
    required this.onMinutes,
    required this.onLater,
    required this.onHeard,
  });

  /// The "later" the bar is currently offering, in minutes.
  final int minutes;

  /// False once [AppConstants.maxReminderSnoozes] laters are spent: the
  /// presets go quiet and only hearing it is left.
  final bool canLater;

  final ValueChanged<int> onMinutes;
  final VoidCallback onLater;
  final VoidCallback onHeard;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (canLater) ...[
          Text('Remind me in', style: TideType.labelMuted),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final choice in AppConstants.reminderLaterChoices)
                CallChip(
                  label: ReminderCopy.minutes(choice),
                  icon: Icons.schedule_rounded,
                  selected: choice == minutes,
                  onTap: () {
                    onMinutes(choice);
                    onLater();
                  },
                ),
              CallChip(
                label: 'Later…',
                icon: Icons.more_time_rounded,
                selected: !AppConstants.reminderLaterChoices.contains(minutes),
                onTap: () => _custom(context),
              ),
            ],
          ),
          const SizedBox(height: 14),
        ] else ...[
          // The last later is spent. Said once, quietly, and the bar is left
          // with the one answer that is still real.
          Text(
            ReminderCopy.lastLaterToday,
            textAlign: TextAlign.center,
            style: TideType.bodyMuted,
          ),
          const SizedBox(height: 14),
        ],
        Semantics(
          button: true,
          label: 'Got it, thanks',
          child: ExcludeSemantics(
            child: PressScale(
              onTap: onHeard,
              child: Container(
                height: 56,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: TideColors.lantern.withValues(alpha: 0.14),
                  borderRadius: TideElevation.radius12,
                  border: Border.all(
                    color: TideColors.lantern.withValues(alpha: 0.45),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_rounded,
                      size: 19,
                      color: TideColors.lantern,
                    ),
                    const SizedBox(width: 9),
                    Flexible(
                      child: Text(
                        'Got it, thanks',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TideType.heading.copyWith(
                          color: TideColors.lantern,
                          fontSize: 16,
                        ),
                      ),
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

  /// Any number up to [AppConstants.reminderLaterMaxMinutes], typed rather
  /// than picked: the presets cover the usual afternoon, and the rest is
  /// somebody's own number.
  Future<void> _custom(BuildContext context) async {
    final picked = await showLaterSheet(context, minutes: minutes);
    if (picked == null) return;
    onMinutes(picked);
    onLater();
  }
}
