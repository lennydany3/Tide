#!/usr/bin/env node
/**
 * Writes the site's legal copy into the Flutter app.
 *
 * The app shows Terms and Privacy offline, with no network call and no
 * bundled HTML, because a policy you cannot read when you have no signal is
 * not much of a policy. So the Dart is generated from lib/legal.json, which
 * is the same file the website renders — there is one set of words, and the
 * site is canonical.
 *
 * Never hand-edit product/lib/config/legal_copy.dart. Edit the JSON, run
 * `npm run legal:sync`, and commit both files. `npm run legal:check` fails
 * when the two have drifted, which is the whole point of generating it.
 *
 *   node scripts/legal.mjs            write the Dart
 *   node scripts/legal.mjs --check    fail if it is out of date, write nothing
 */

import { readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const source = join(root, "lib", "legal.json");
const target = join(root, "product", "lib", "config", "legal_copy.dart");

const check = process.argv.includes("--check");
const legal = JSON.parse(readFileSync(source, "utf8"));

/**
 * Dart string literals, with the escaping done here rather than by hand.
 *
 * The copy is plain prose, but it contains apostrophes ("Tide's"), and a
 * policy that fails to compile is worse than no policy at all. The dollar
 * sign is escaped too because it opens an interpolation in Dart, and the
 * JSON is not trusted to stay away from it.
 */
function dartString(value) {
  return `'${value
    .replace(/\\/g, "\\\\")
    .replace(/'/g, "\\'")
    .replace(/\$/g, "\\$")}'`;
}

/** One document as a Dart expression. */
function dartDocument(doc, indent) {
  if (!doc) throw new Error(`legal.json is missing a required document`);

  const pad = " ".repeat(indent);
  const inner = " ".repeat(indent + 2);
  const lines = [
    "LegalDocument(",
    `${inner}slug: ${dartString(doc.slug)},`,
    `${inner}title: ${dartString(doc.title)},`,
    `${inner}updated: ${dartString(doc.updated)},`,
    `${inner}sections: <LegalSection>[`,
  ];

  for (const section of doc.sections) {
    const deep = " ".repeat(indent + 6);
    lines.push(`${" ".repeat(indent + 4)}LegalSection(`);
    lines.push(`${deep}heading: ${dartString(section.heading)},`);

    for (const [field, items] of [
      ["paragraphs", section.paragraphs],
      ["bullets", section.bullets],
    ]) {
      if (!items?.length) continue;
      lines.push(`${deep}${field}: <String>[`);
      for (const item of items) {
        lines.push(`${" ".repeat(indent + 8)}${dartString(item)},`);
      }
      lines.push(`${deep}],`);
    }

    lines.push(`${" ".repeat(indent + 4)}),`);
  }

  lines.push(`${inner}],`);
  lines.push(`${pad})`);
  return lines.join("\n");
}

const contents = `// GENERATED FILE - DO NOT EDIT.
//
// Written by scripts/legal.mjs from lib/legal.json, which is the same copy
// the website renders at /terms and /privacy. Edit the JSON and run
// \`npm run legal:sync\`; \`npm run legal:check\` fails when the two differ.

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

  /// \`/terms\` or \`/privacy\`, so a screen can route on it.
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
  static const String effectiveDate = ${dartString(legal.effectiveDate)};

  /// The terms of use.
  static const LegalDocument terms = ${dartDocument(
    legal.documents.find((d) => d.slug === "terms"),
    2,
  )};

  /// The privacy policy.
  static const LegalDocument privacy = ${dartDocument(
    legal.documents.find((d) => d.slug === "privacy"),
    2,
  )};

  /// The document for [slug], or null when [slug] is not one of the two.
  static LegalDocument? bySlug(String slug) {
    if (slug == terms.slug) return terms;
    if (slug == privacy.slug) return privacy;
    return null;
  }
}
`;

if (check) {
  let current = "";
  try {
    current = readFileSync(target, "utf8");
  } catch {
    console.error(
      "product/lib/config/legal_copy.dart is missing. Run `npm run legal:sync`.",
    );
    process.exit(1);
  }

  if (current !== contents) {
    console.error(
      "product/lib/config/legal_copy.dart is out of date with lib/legal.json.\n" +
        "Run `npm run legal:sync` and commit the result.",
    );
    process.exit(1);
  }

  console.log("legal_copy.dart is up to date with lib/legal.json.");
} else {
  writeFileSync(target, contents, "utf8");
  console.log(
    `Wrote product/lib/config/legal_copy.dart (${legal.documents.length} documents).`,
  );
}