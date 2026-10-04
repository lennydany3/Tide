import legal from "./legal.json";

/*
 * One source of truth for the legal copy.
 *
 * The copy lives in legal.json rather than in JSX because it has two readers:
 * the website renders it at /terms and /privacy, and scripts/legal.mjs writes
 * it into product/lib/config/legal_copy.dart so the app can show the same
 * words offline. JSON is the only format Node can read without a TypeScript
 * runtime, and a policy that can drift between the site and the app is worse
 * than no policy at all.
 *
 * The site is the canonical copy. Edit the JSON, run `npm run legal:sync`, and
 * commit both files. Never hand-edit the Dart.
 */

export type LegalSection = {
  heading: string;
  paragraphs: string[];
  bullets: string[];
};

export type LegalDocument = {
  slug: "terms" | "privacy";
  title: string;
  updated: string;
  sections: LegalSection[];
};

export type LegalCopy = {
  effectiveDate: string;
  entity: { name: string; address: string };
  contact: { email: string; repository: string; issues: string };
  documents: LegalDocument[];
};

const copy = legal as LegalCopy;

/** Every document, in the order the site lists them. */
export const legalDocuments = copy.documents;

/** One document by slug. Throws rather than returning undefined: a missing
 *  legal page should fail the build, not render an empty one. */
export function legalDocument(slug: string): LegalDocument {
  const document = copy.documents.find((d) => d.slug === slug);
  if (!document) throw new Error(`No legal document for slug "${slug}"`);
  return document;
}

/**
 * Where a reader should send a question or a takedown request.
 *
 * The GitHub issue tracker is the primary channel because it is the one that
 * is verifiably real for this project: the repository is public and its
 * addresses are monitored. An email address is used when one has been set;
 * until then the reader is pointed at the tracker rather than at an address
 * nobody reads.
 */
export const legalContact = copy.contact;

/** The publishing entity, once it has been filled in. */
export const legalEntity = copy.entity;

/** The date the current copy applies from. */
export const legalEffectiveDate = copy.effectiveDate;