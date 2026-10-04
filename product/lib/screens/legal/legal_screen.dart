import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/legal_copy.dart';
import '../../theme/tide_colors.dart';
import '../../theme/tide_typography.dart';
import '../../widgets/press_scale.dart';
import '../../widgets/segmented_pill.dart';
import '../../widgets/stagger_list.dart';
import '../../widgets/tide_backdrop.dart';

/// The Terms and the Privacy Policy, on the device, offline.
///
/// Not a web view and not a link out. Both reasons the obvious answers are
/// wrong: the app is sideloaded and a reader may have no browser and no
/// signal, and a policy you cannot reach when you have no connection is not
/// much of a policy. So the copy is compiled into the binary — generated from
/// lib/legal.json, the same file the website renders, by
/// `npm run legal:sync`. The words here and the words online are the same by
/// construction rather than by remembering to update both.
///
/// One screen and two documents, not two screens. Nothing separates a reader
/// from the other document by more than a tap, and the pair is genuinely one
/// reading: the Terms say what the app is, the Privacy Policy says what it
/// does with your data.
///
/// The section list is not a table of contents. This is a screen people arrive
/// at deliberately, usually looking for one particular section, so the
/// sections lay out in order and the whole document scrolls as one column —
/// which is what a policy is expected to be.
class LegalScreen extends StatefulWidget {
  const LegalScreen({super.key, this.initial = 0});

  /// Which document opens first: 0 for the Terms, 1 for the Privacy Policy.
  final int initial;

  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen> {
  late int _index = widget.initial.clamp(0, 1);

  @override
  Widget build(BuildContext context) {
    final document = _index == 0 ? LegalCopy.terms : LegalCopy.privacy;

    return Scaffold(
      backgroundColor: TideColors.deepWater,
      body: Stack(
        children: [
          const Positioned.fill(child: TideBackdrop()),
          ListView(
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.viewPaddingOf(context).top + 16,
              20,
              40 + MediaQuery.paddingOf(context).bottom,
            ),
            children: [
              Row(
                children: [
                  Semantics(
                    button: true,
                    label: 'Back',
                    child: PressScale(
                      onTap: () => context.pop(),
                      child: SizedBox(
                        width: 38,
                        height: 38,
                        child: Icon(
                          Icons.arrow_back_rounded,
                          size: 21,
                          color: TideColors.bone,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Legal',
                      style: TideType.screenTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Offline · applies from ${LegalCopy.effectiveDate}',
                style: TideType.labelMuted,
              ),
              const SizedBox(height: 20),

              SegmentedPill(
                labels: const ['Terms', 'Privacy'],
                selectedIndex: _index,
                onChanged: (value) => setState(() => _index = value),
              ),
              const SizedBox(height: 28),

              StaggerColumn(
                spacing: 26,
                children: [
                  Text(document.title, style: TideType.heading),
                  for (final section in document.sections)
                    _Section(section: section),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One numbered section: its heading, then the body copy, then the list when
/// it has one.
class _Section extends StatelessWidget {
  const _Section({required this.section});

  final LegalSection section;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(section.heading, style: TideType.sectionHeader),
        const SizedBox(height: 12),
        for (final paragraph in section.paragraphs) ...[
          Text(paragraph, style: TideType.bodyMuted),
          const SizedBox(height: 12),
        ],
        if (section.bullets.isNotEmpty) ...[
          // A rule the length of the column, not a row of dots. This is body
          // copy in a list, and the app draws the rest of its lists that way —
          // a bullet glyph here would read as a to-do.
          for (final bullet in section.bullets)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 14,
                    height: 1,
                    margin: const EdgeInsets.only(top: 12),
                    color: TideColors.hairline,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(bullet, style: TideType.bodyMuted),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}