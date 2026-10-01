import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tide/config/legal_copy.dart';
import 'package:tide/main.dart';
import 'package:tide/widgets/tide_tab_bar.dart';

import 'support/flow.dart';

/// The legal copy, reached from Settings.
///
/// Three things worth holding down here, because each is a way this can
/// quietly stop being true:
///
/// - the row exists and opens the screen,
/// - the screen shows real copy rather than a placeholder,
/// - the copy in the binary is the copy in lib/legal.json, which
///   `npm run legal:check` enforces on the other side.
///
/// The last one is checked here against the generated constants themselves,
/// so a forgotten `npm run legal:sync` fails the Dart suite too rather than
/// only the Node one.
void main() {
  Future<void> openFromSettings(WidgetTester tester) async {
    await tester.pumpWidget(TideApp(startOnboarded: true));
    await settle(tester);

    // Scoped to the tab bar: the Settings screen titles itself "Settings"
    // too, so a bare text finder is ambiguous once that screen is up.
    await tester.tap(
      find.descendant(
        of: find.byType(TideTabBar),
        matching: find.text('Settings'),
      ),
    );
    await settle(tester);

    final row = find.text('Terms and privacy');
    await tester.scrollUntilVisible(
      row,
      300,
      scrollable: find
          .ancestor(
            of: find.text('Your account, and how Tide behaves.'),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    // The scroll is animated, so the row can be on screen but not yet
    // hittable when scrollUntilVisible returns.
    await settle(tester, 300);
    await tester.tap(row);
    await pumpFor(tester, const Duration(milliseconds: 600));
    // Settle out the entrance stagger, or a test that stops here leaves a
    // timer pending and the binding fails the case on teardown.
    await settle(tester);
  }

  testWidgets('Settings opens the legal screen with the Terms showing', (
    tester,
  ) async {
    await openFromSettings(tester);

    expect(find.text('Legal'), findsOneWidget);
    expect(find.text(LegalCopy.terms.title), findsOneWidget);
    expect(find.text(LegalCopy.terms.sections.first.heading), findsOneWidget);
  });

  testWidgets('the policy is one tap away and swaps the whole document', (
    tester,
  ) async {
    await openFromSettings(tester);

    expect(find.text(LegalCopy.privacy.title), findsNothing);

    await tester.tap(find.text('Privacy'));
    await settle(tester);

    expect(find.text(LegalCopy.privacy.title), findsOneWidget);
    expect(
      find.text(LegalCopy.privacy.sections.first.heading),
      findsOneWidget,
    );
    expect(find.text(LegalCopy.terms.title), findsNothing);
  });

  testWidgets('the privacy bullets a reader needs are on the screen', (
    tester,
  ) async {
    await openFromSettings(tester);

    await tester.tap(find.text('Privacy'));
    await settle(tester);

    // The section that carries the whole promise of the document. If the
    // generator ever drops bullets, this is the sentence that goes missing.
    expect(
      find.text(
        LegalCopy.privacy.sections
            .firstWhere((section) => section.bullets.isNotEmpty)
            .bullets
            .first,
      ),
      findsOneWidget,
    );
  });

  test('the generated copy is complete on both sides', () {
    for (final document in [LegalCopy.terms, LegalCopy.privacy]) {
      expect(document.sections, isNotEmpty, reason: document.slug);
      expect(document.updated, isNotEmpty, reason: document.slug);
      expect(document.updated, LegalCopy.effectiveDate, reason: document.slug);

      for (final section in document.sections) {
        expect(section.heading, isNotEmpty);
        // A section with neither body copy nor a list is a heading over
        // nothing, which is what a mis-shaped generator produces.
        expect(
          section.paragraphs.isNotEmpty || section.bullets.isNotEmpty,
          isTrue,
          reason: section.heading,
        );
      }
    }

    expect(LegalCopy.bySlug('terms'), same(LegalCopy.terms));
    expect(LegalCopy.bySlug('privacy'), same(LegalCopy.privacy));
    expect(LegalCopy.bySlug('nope'), isNull);
  });
}