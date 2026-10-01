"use client";

import { AnimatePresence, motion, useReducedMotion } from "motion/react";
import Image from "next/image";
import { useEffect, useRef, useState } from "react";

/** Marks on the boot bar. The site is a readout, so the wait is a readout. */
const TICKS = 28;

const STEPS = [
  { id: "01", label: "Reading the manifest", at: 0.06 },
  { id: "02", label: "Mounting three screens", at: 0.34 },
  { id: "03", label: "Palette locked", at: 0.66 },
  { id: "04", label: "Ready", at: 0.94 },
];

/** Long enough to read the mark arriving, short enough to never be waited on. */
const HOLD_MS = 1500;

/** How long the fade-out runs before the overlay unmounts. */
const EXIT_MS = 620;

/** Where the "already played" flag lives, for this browser session only. */
const DONE_KEY = "tide:booted";

type Phase = "idle" | "loading" | "leaving";

/**
 * The boot sequence.
 *
 * A first-load overlay that draws the mark, fills a tick bar and clears in
 * three stages. It exists for one reason: the page underneath is a hard cut
 * from nothing, and a hard cut with no run-up reads as a flash rather than an
 * arrival. Giving the mark a moment of its own before the headline lands is
 * the difference between "the site loaded" and "something opened".
 *
 * Three constraints keep it from becoming the thing people hate about sites:
 *
 * - **It cannot be waited on.** [HOLD_MS] is a ceiling, not a duration, and
 *   it is walked from `document.readyState` plus `document.fonts.ready`, so a
 *   warm cache cuts it to a few hundred milliseconds.
 * - **It plays once per session.** Back-navigation and repeat visits go
 *   straight to the page. A loader that re-runs on every click is a loader
 *   people route around.
 * - **It gets out of the way.** Any key or pointer press skips it, and once
 *   dismissed it stops intercepting entirely — no invisible click-blocker
 *   left over from a `pointer-events` mistake.
 *
 * Reduced motion does not get a shortened version of this; it gets none of
 * it. The run-up is the entire point of the overlay, so a cross-fade would be
 * the same wait with less to look at. Anyone who asks for less motion goes
 * straight to the page.
 *
 * The three phases are three effects rather than one, each owning only its
 * own timers. That is not tidiness: a single effect keyed on the phase tears
 * down its cleanup the instant the phase moves, which cancels the very timer
 * that was going to unmount the overlay — and the overlay then never leaves.
 */
export function BootSequence() {
  const reduce = useReducedMotion();
  const [phase, setPhase] = useState<Phase>("idle");

  // Two things can reach `finish` at once — the load promise resolving and
  // the ceiling timer — so it has to be safe to call twice.
  const finished = useRef(false);

  // Arm. The session flag is read in a task rather than in the effect body:
  // reading it synchronously and then flipping state would cascade a render
  // on the very first commit, before anything has painted.
  useEffect(() => {
    if (reduce) return;

    const id = window.setTimeout(() => {
      try {
        if (sessionStorage.getItem(DONE_KEY) === "1") return;
      } catch {
        // Storage can be blocked entirely (private mode, embedded webview).
        // Running the sequence is a worse experience than skipping it, so a
        // storage failure means skip.
        return;
      }
      setPhase("loading");
    }, 0);

    return () => window.clearTimeout(id);
  }, [reduce]);

  // The run-up.
  useEffect(() => {
    if (phase !== "loading") return;

    const finish = () => {
      if (finished.current) return;
      finished.current = true;
      setPhase("leaving");
      try {
        sessionStorage.setItem(DONE_KEY, "1");
      } catch {
        // Nothing to do: the worst case is the sequence plays again next
        // load, which is what happens on a browser with no storage anyway.
      }
    };

    // Start from whatever is already true. A fully warm load (second
    // navigation in, prefetched HTML, cached font) resolves both promises
    // before the first frame, and then this is a short mark and nothing else.
    Promise.all([
      document.fonts?.ready ?? Promise.resolve(),
      new Promise<void>((resolve) => {
        if (document.readyState === "complete") resolve();
        else window.addEventListener("load", () => resolve(), { once: true });
      }),
    ]).then(() => {
      // 62% of the budget for the work, the rest for the two frames the
      // marks need so the last tick lands on something rather than mid-air.
      window.setTimeout(finish, HOLD_MS * 0.62);
    });

    // The absolute ceiling. Nothing on this page takes 1.5s to be ready on a
    // warm cache, so reaching it means something is wrong and the page is
    // more useful than the overlay.
    const ceiling = window.setTimeout(finish, HOLD_MS);

    const skip = () => finish();
    window.addEventListener("keydown", skip, { once: true });
    window.addEventListener("pointerdown", skip, { once: true });

    return () => {
      clearTimeout(ceiling);
      window.removeEventListener("keydown", skip);
      window.removeEventListener("pointerdown", skip);
    };
  }, [phase]);

  // The exit. Its own effect on purpose — see the note above.
  useEffect(() => {
    if (phase !== "leaving") return;
    const id = window.setTimeout(() => setPhase("idle"), EXIT_MS);
    return () => window.clearTimeout(id);
  }, [phase]);

  return (
    <AnimatePresence>
      {phase !== "idle" && (
        <motion.div
          // Off the accessibility tree entirely: it names nothing, controls
          // nothing, and the page it covers is already in the tree behind it.
          aria-hidden
          key="boot"
          className="fixed inset-0 z-50 flex flex-col justify-between bg-ground"
          initial={{ opacity: 1 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          transition={{ duration: 0.5, ease: [0.65, 0, 0.35, 1] }}
        >
          <BootBar leaving={phase === "leaving"} />
          <BootMark leaving={phase === "leaving"} />
          <BootSteps leaving={phase === "leaving"} />
        </motion.div>
      )}
    </AnimatePresence>
  );
}

/**
 * The tick bar.
 *
 * Not a percentage. A bar that counts to 100 is a lie the moment it is not
 * measuring anything, and every site that has done it has been quietly
 * pretending. Twenty-eight discrete ticks filling left to right read as what
 * they are: discrete units of progress through a fixed sequence.
 *
 * Each tick is a dim cell with a lit cell on top, and it is the lit cell's
 * opacity that moves. Animating the tick's own background colour would be
 * twenty-eight paint animations rather than twenty-eight compositor ones,
 * which is the difference between the bar being free and the bar costing a
 * frame on the mid-range Android phone this site exists to sell to.
 */
function BootBar({ leaving }: { leaving: boolean }) {
  return (
    <motion.div
      className="flex w-full shrink-0"
      animate={{ opacity: leaving ? 0 : 1 }}
      transition={{ duration: 0.3 }}
    >
      {Array.from({ length: TICKS }, (_, i) => (
        <div key={i} className="h-1.5 flex-1 bg-shoal">
          <motion.span
            className="block h-full w-full bg-lantern"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{
              duration: 0.12,
              // Staggered from the left rather than timed independently, so the
              // bar always fills as one edge advancing. Uniform delays would
              // look like a fade rather than a sweep.
              delay: leaving ? 0 : (i / TICKS) * (HOLD_MS * 0.62) / 1000,
              ease: "linear",
            }}
          />
        </div>
      ))}
    </motion.div>
  );
}

/** The mark, and the crosshairs it is read against. */
function BootMark({ leaving }: { leaving: boolean }) {
  return (
    <motion.div
      className="flex flex-1 items-center justify-center"
      animate={{ opacity: leaving ? 0 : 1 }}
      transition={{ duration: 0.25 }}
    >
      <motion.div
        className="relative flex size-40 items-center justify-center border border-hairline"
        initial={{ scale: 0.86, opacity: 0 }}
        animate={
          leaving
            ? { scale: 1, opacity: 0 }
            : {
                scale: 1,
                opacity: 1,
                transition: { duration: 0.7, ease: [0.16, 1, 0.3, 1] },
              }
        }
      >
        {/* Crosshairs at the intersections, drawn as a background rather
            than four elements: the frame is a reading point, not a target. */}
        <span
          aria-hidden
          className="absolute inset-0 bg-[linear-gradient(to_right,transparent_calc(50%_-_0.5px),var(--rule)_50%,transparent_calc(50%_+0.5px)),linear-gradient(to_bottom,transparent_calc(50%_-_0.5px),var(--rule)_50%,transparent_calc(50%_+0.5px))]"
        />
        <motion.div
          className="relative"
          initial={{ scale: 0.7 }}
          animate={{ scale: leaving ? 1.08 : 1 }}
          transition={{ duration: 0.8, ease: [0.16, 1, 0.3, 1] }}
        >
          <Image
            src="/tide-mark.png"
            alt=""
            width={72}
            height={72}
            priority
            className="size-18"
          />
        </motion.div>
      </motion.div>
    </motion.div>
  );
}

/** The read-out lines, one per stage. */
function BootSteps({ leaving }: { leaving: boolean }) {
  return (
    <motion.div
      className="mx-auto flex w-full max-w-7xl flex-col gap-2 px-4 pb-10 sm:px-6 lg:px-8"
      animate={{ opacity: leaving ? 0 : 1 }}
      transition={{ duration: 0.2 }}
    >
      {STEPS.map((step, i) => (
        <motion.div
          key={step.id}
          className="compartment grid-cols-[auto_1fr_auto]"
          initial={{ opacity: 0 }}
          animate={{ opacity: leaving ? 0 : 1 }}
          transition={{
            duration: 0.2,
            delay: leaving ? 0 : (i * HOLD_MS * 0.14) / 1000,
          }}
        >
          <data value={step.id} className="telemetry bg-shoal px-3 py-2 text-lantern">
            {step.id}
          </data>
          <span className="telemetry bg-shelf px-3 py-2 text-silt">
            {step.label}
          </span>
          <span className="telemetry bg-shelf px-3 py-2 text-bone">
            {i === STEPS.length - 1 ? "OK" : "·· "}
          </span>
        </motion.div>
      ))}
      <motion.p
        className="telemetry mt-2 flex items-center gap-2 text-silt"
        animate={{ opacity: leaving ? 0 : 1 }}
        transition={{ duration: 0.2 }}
      >
        <span aria-hidden className="beacon" />
        <span translate="no">Tide</span> · Android
      </motion.p>
    </motion.div>
  );
}