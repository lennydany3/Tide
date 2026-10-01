import type { Metadata } from "next";
import { LegalPage } from "../_components/legal-page";
import { SiteFooter } from "../_components/site-footer";
import { SiteHeader } from "../_components/site-header";
import { legalDocument } from "@/lib/legal";

export const metadata: Metadata = {
  title: "Terms of Use",
  description:
    "The terms that cover your use of Tide, a free habit tracker for Android distributed as a signed APK.",
};

export default function TermsPage() {
  return (
    <>
      <SiteHeader />
      <main id="main">
        <LegalPage
          document={legalDocument("terms")}
          other={{ href: "/privacy", title: "Privacy Policy" }}
        />
      </main>
      <SiteFooter />
    </>
  );
}