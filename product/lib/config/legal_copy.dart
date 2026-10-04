// GENERATED FILE - DO NOT EDIT.
//
// Written by scripts/legal.mjs from lib/legal.json, which is the same copy
// the website renders at /terms and /privacy. Edit the JSON and run
// `npm run legal:sync`; `npm run legal:check` fails when the two differ.

/// One section of a legal document: a heading, its body copy, and the
/// bulleted list under it when it has one.
class LegalSection {
  const LegalSection({
    required this.heading,
    this.paragraphs = const <String>[],
    this.bullets = const <String>[],
  });

  /// The section title, already numbered for display.
  final String heading;

  /// Body copy, in order. Empty for a section that is only a list.
  final List<String> paragraphs;

  /// The list under the body copy. Most sections have none.
  final List<String> bullets;
}

/// A whole document.
class LegalDocument {
  const LegalDocument({
    required this.slug,
    required this.title,
    required this.updated,
    required this.sections,
  });

  /// `/terms` or `/privacy`, so a screen can route on it.
  final String slug;

  /// Display title.
  final String title;

  /// ISO date this version applies from.
  final String updated;

  /// The numbered sections, in order.
  final List<LegalSection> sections;
}

/// The legal copy, compiled in.
///
/// Offline by design. The app never fetches these, so the words here and the
/// words on the site are the same by construction rather than by discipline:
/// this file is generated from the site's own copy.
abstract final class LegalCopy {
  /// The date the current copy applies from.
  static const String effectiveDate = '2026-10-01';

  /// The terms of use.
  static const LegalDocument terms = LegalDocument(
    slug: 'terms',
    title: 'Terms of Use',
    updated: '2026-10-01',
    sections: <LegalSection>[
      LegalSection(
        heading: '1. What these terms cover',
        paragraphs: <String>[
          'These terms cover your use of Tide, a habit tracker for Android, distributed as a signed APK on GitHub rather than through an app store. By installing or using Tide you agree to them. If you do not agree, do not use the app.',
          'Tide is provided free of charge. There is no paid tier, no subscription and no purchase to make. Nothing in these terms obliges you to pay anything.',
        ],
      ),
      LegalSection(
        heading: '2. The service',
        paragraphs: <String>[
          'Tide helps you record which days you kept a habit and how long your runs last. It is a record-keeping tool. It does not give advice about your health, your habits or your life, and nothing in the app should be treated as professional advice.',
          'You are responsible for what you record and for how you use it. The app will not warn you that a plan is unrealistic; that judgement is yours.',
        ],
        bullets: <String>[
          'Tide runs on Android. It is not available for iOS or desktop.',
          'The app is distributed as a signed APK. Installing it means allowing your device to install applications from outside the Play Store.',
          'Android may ask you to allow installs from your browser the first time. This is Android’s own permission, not Tide’s.',
        ],
      ),
      LegalSection(
        heading: '3. Your account',
        paragraphs: <String>[
          'Tide works without an account. If you create one, you can reach the same data from more than one device. Creating an account needs a working email address, confirmed with a six-digit code, or a Google account.',
          'You are responsible for what happens under your account, including keeping your sign-in details to yourself. Tell us if you think someone else has used it.',
          'You can delete your account at any time from Settings, under Danger zone. Deleting is immediate and permanent.',
        ],
      ),
      LegalSection(
        heading: '4. Your data',
        paragraphs: <String>[
          'Your habits, their entries and your to-dos are yours. Tide claims no ownership of them and has no claim on them beyond the rights needed to store and sync them for you.',
          'You are responsible for your own backups. Tide syncs your data between your devices, which is not the same as archiving it. If you delete an entry, it is deleted.',
        ],
      ),
      LegalSection(
        heading: '5. Acceptable use',
        paragraphs: <String>[
          'Tide is provided for personal use. Do not use it to break the law, to interfere with the service or its users, or to send automated requests against the release host in a way that degrades it for others.',
        ],
      ),
      LegalSection(
        heading: '6. Availability',
        paragraphs: <String>[
          'Tide is offered as it is, with no promise that it will always be reachable. Updates are published as new releases and delivered from inside the app. A release can be withdrawn at any time.',
          'The app is designed to keep working without a connection. Logs you make offline are written to the device first and sent when the connection returns.',
        ],
      ),
      LegalSection(
        heading: '7. No warranty',
        paragraphs: <String>[
          'Tide is provided without warranties of any kind, express or implied, including fitness for a particular purpose. Streaks, heatmaps and totals are calculations over what you logged; a result Tide shows is not a guarantee that your record is accurate or complete.',
          'The app is open source and you are welcome to read it, modify it and build your own copy.',
        ],
      ),
      LegalSection(
        heading: '8. Limitation of liability',
        paragraphs: <String>[
          'To the fullest extent the law allows, the maintainers of Tide are not liable for any loss arising from your use of the app, including lost data, lost streaks, or damage to a device. Nothing in these terms excludes liability that cannot lawfully be excluded.',
        ],
      ),
      LegalSection(
        heading: '9. Ending use',
        paragraphs: <String>[
          'You can stop using Tide whenever you like, and delete your account at any time. We may withdraw a release or stop the project; deleting your account first means nothing is left behind.',
        ],
      ),
      LegalSection(
        heading: '10. Changes to these terms',
        paragraphs: <String>[
          'These terms may change as the app does. The date at the top of this document is the version that applies. Continuing to use Tide after a change means you accept it.',
        ],
      ),
    ],
  );

  /// The privacy policy.
  static const LegalDocument privacy = LegalDocument(
    slug: 'privacy',
    title: 'Privacy Policy',
    updated: '2026-10-01',
    sections: <LegalSection>[
      LegalSection(
        heading: '1. The short version',
        paragraphs: <String>[
          'Tide contains no analytics, no advertising and no tracking of any kind. Nothing about you is sold, shared or profiled.',
          'Your habits stay on your phone unless you sign in, in which case they are held on your own server so your devices can agree with each other. You can delete everything, from your phone, at any time.',
        ],
      ),
      LegalSection(
        heading: '2. What is collected',
        paragraphs: <String>[
          'Only what you put in. Tide has no telemetry pipeline and no crash reporting service, so there is no record of your use of the app beyond the data described here.',
        ],
        bullets: <String>[
          'Habits you create: their name, type, schedule and any notes or tags.',
          'Entries you log: the days you kept a habit, any amount or duration, and any streak freeze you spend.',
          'To-dos you create: title, notes, due date, repeat rule, steps and tags.',
          'Pauses and freezes: the days you paused a habit or held a missed day with a freeze.',
          'Your email address and password hash, if you create an account. Passwords are never stored by Tide.',
          'Your Google account identifier, if you sign in with Google.',
        ],
      ),
      LegalSection(
        heading: '3. What stays on your device',
        paragraphs: <String>[
          'The following never leave the phone. They exist so the app opens instantly and works with no connection, and you can remove them by clearing the app’s storage.',
          'Reminders are planned and delivered by the phone itself, outside the app, which is why they still arrive when Tide is not running.',
        ],
        bullets: <String>[
          'Which palette you chose, whether you have seen the introduction, and which local reminders you configured.',
          'A local cache of your habits and to-dos, so the app opens without waiting for the network.',
          'A queue of writes that have not reached the server yet. It is drained on every sync and cleared when you sign out.',
          'Answers you give to a reminder from the lock screen, waiting to be applied when the app next runs.',
        ],
      ),
      LegalSection(
        heading: '4. What is sent to the server, and when',
        paragraphs: <String>[
          'If you sign in, your habits, their entries and your to-dos are stored on a Supabase project so that signing in on a second device restores what the first had. If you do not sign in, none of this is sent anywhere: the app keeps everything locally and sync is off.',
          'Even offline, a write is committed to the device before anything is sent, so no entry is lost to a dropped connection. Reads and writes are protected by row-level security, so a device can only reach the rows belonging to its own account.',
          'The app listens on a private realtime channel scoped to your own account for changes made on your other devices. It does not subscribe to any shared channel.',
        ],
      ),
      LegalSection(
        heading: '5. Accounts and sign-in',
        paragraphs: <String>[
          'Tide uses Supabase for authentication. Email sign-up is confirmed with a six-digit code rather than a link. Sign-in with Google passes an identity token to Supabase so that the address is known before an account is created; Tide never receives your Google password.',
          'A confirmation code is emailed to the address you gave. That address is used for authentication and to send that code, and for nothing else. It is not sold, and it is not used for marketing.',
        ],
      ),
      LegalSection(
        heading: '6. Permissions',
        paragraphs: <String>[
          'Permissions are asked for one at a time, each on its own screen, and none of them blocks the app. Declining one leaves the rest of Tide working; only the feature that needs it is unavailable.',
          'Tide asks only for permissions it uses. It does not request contacts, location, camera, microphone, call logs or storage outside its own sandbox.',
        ],
        bullets: <String>[
          'Notifications, to deliver a reminder. Declining it turns reminders off and nothing else.',
          'Installation of updates, so a new build can install itself. Declining it means you install updates by hand.',
        ],
      ),
      LegalSection(
        heading: '7. Home screen widgets and quick actions',
        paragraphs: <String>[
          'The home screen widgets and the launcher shortcut read from Tide’s own storage on your device to draw themselves. What a widget shows is the data already on your phone; it does not send anything anywhere. Tapping a widget to log an entry applies that entry the same way a tap inside the app would.',
        ],
      ),
      LegalSection(
        heading: '8. Network requests',
        paragraphs: <String>[
          'Tide makes outbound requests for three reasons, and nothing else. There is no background beacon, no fingerprinting and no third-party advertising or analytics request.',
        ],
        bullets: <String>[
          'To authenticate and to sync your own data, when you are signed in.',
          'To fetch a small JSON manifest that says whether a newer build exists.',
          'To download that build, if you accept the update.',
        ],
      ),
      LegalSection(
        heading: '9. Third parties',
        paragraphs: <String>[
          'Two services are involved when you sign in. Supabase hosts authentication and the database and applies the access rules. Google is involved only if you choose to sign in with Google.',
          'These processors act on your data to provide the service. Neither is given your habits to use for its own purposes.',
        ],
      ),
      LegalSection(
        heading: '10. Deleting your account and your data',
        paragraphs: <String>[
          'Settings, then Danger zone, deletes your account. The deletion is immediate: it removes your profile, your sign-in sessions, your habits, every entry and every to-do, in one operation, and signs the device out.',
          'Deletion needs a working connection, so that it cannot half-finish and leave an orphaned account. After it completes there is nothing left on the server to retrieve.',
          'Clearing the app’s storage on your device removes the local cache and any queued writes, which is the whole of Tide’s footprint on that phone.',
        ],
      ),
      LegalSection(
        heading: '11. Children',
        paragraphs: <String>[
          'Tide is not directed at children under 13 and is not intended to collect data from them. If you believe a child has created an account, delete it from Settings or report it and it will be removed.',
        ],
      ),
      LegalSection(
        heading: '12. Changes to this policy',
        paragraphs: <String>[
          'This policy may change as the app does. The date at the top of this document is the version that applies. If a change alters what is collected, the app’s release notes will say so.',
        ],
      ),
    ],
  );

  /// The document for [slug], or null when [slug] is not one of the two.
  static LegalDocument? bySlug(String slug) {
    if (slug == terms.slug) return terms;
    if (slug == privacy.slug) return privacy;
    return null;
  }
}
