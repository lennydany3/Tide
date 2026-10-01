import type { Metadata } from "next";
import { LegalPage } from "../_components/legal-page";
import { SiteFooter } from "../_components/site-footer";
import { SiteHeader } from "../_components/site-header";
import { legalDocument } from "@/lib/legal";

export const metadata: Metadata = {
  title: "Privacy Policy",
  description:
    "What Tide collects, what stays on your phone, and how to delete all of it. No analytics, no advertising, no tracking.",
};

export default function PrivacyPage() {
  return (
    <>
      <SiteHeader />
      <main id="main">
        <LegalPage
          document={legalDocument("privacy")}
          other={{ href: "/terms", title: "Terms of Use" }}
        />
      </main>
      <SiteFooter />
    </>
  );
}