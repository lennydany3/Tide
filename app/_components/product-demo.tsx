"use client";

import { motion, useReducedMotion, useSpring, useTransform } from "motion/react";
import { useCallback, useState } from "react";

/**
 * The live demo: one phone, running Tide's actual logging gesture.
 *
 * This is a working re-implementation of the interaction, not a picture of
 * it. Every number on screen is computed from the taps you make — the ring is
 * the share of habits kept, the figure under it is the sum of the live
 * streaks, and unlogging a habit really does drop its streak to zero. That is
 * the whole argument the app makes, and a screenshot of it proves nothing.
 *
 * It is labelled as a browser simulation on the device itself, because it is
 * one: the product is Android, and this is the same arithmetic running on a
 * different substrate so a visitor with no phone can try it before installing
 * anything.
 *
 * The mechanic worth demonstrating is the freeze. Logging is one tap and
 * proves nothing — the thing that makes Tide different from a checklist is
 * that a missed day does not cost you the run, so that is the interaction the
 * rail is built around.
 */
type Habit = {
  id: string;
  name: string;
  /** Runs of kept days. Reset to zero by an unprotected miss. */
  streak: number;
  logged: boolean;
  /** Freeze tokens this habit can still spend. */
  frost: number;
  /** Whether the current day is held rather than earned. */
  protectedDay: boolean;
};

const OPENING: Habit[] = [
  { id: "water", name: "Water", streak: 12, logged: true, frost: 2, protectedDay: false },
  { id: "move", name: "Move", streak: 4, logged: true, frost: 2, protectedDay: false },
  { id: "read", name: "Read", streak: 0, logged: false, frost: 2, protectedDay: false },
  { id: "meditate", name: "Meditate", streak: 7, logged: false, frost: 0, protectedDay: true },
];

const RADIUS = 52;
const CIRCUMFERENCE = 2 * Math.PI * RADIUS;

export function ProductDemo() {
  const reduce = useReducedMotion();
  const [habits, setHabits] = useState<Habit[]>(OPENING);
  const [log, setLog] = useState<string[]>([]);

  const kept = habits.filter((h) => h.logged).length;
  const total = habits.length;
  const streakSum = habits.reduce((sum, h) => sum + h.streak, 0);
  const share = total === 0 ? 0 : kept / total;

  // Springs rather than tweens, so tapping two habits quickly piles the
  // motion up instead of restarting it. The numerals are transforms of these,
  // never React state, so a rolling figure costs no renders.
  const ringSpring = useSpring(share, { stiffness: 120, damping: 18 });
  const sumSpring = useSpring(streakSum, { stiffness: 90, damping: 20 });
  const keptSpring = useSpring(kept, { stiffness: 140, damping: 20 });

  const dashOffset = useTransform(ringSpring, (v) => CIRCUMFERENCE * (1 - v));
  const streakText = useTransform(sumSpring, (v) => String(Math.round(v)));
  const keptText = useTransform(keptSpring, (v) => `${Math.round(v)}/${total}`);

  const toggle = useCallback((id: string) => {
    setHabits((prev) =>
      prev.map((habit) => {
        if (habit.id !== id) return habit;

        if (habit.logged) {
          // Unlogging is what a miss costs. With a token spent on the day the
          // run survives; without one it goes to nothing.
          const held = habit.protectedDay && habit.frost > 0;
          return {
            ...habit,
            logged: false,
            streak: held ? habit.streak : 0,
            protectedDay: habit.protectedDay,
          };
        }
        return { ...habit, logged: true, streak: habit.streak + 1 };
      }),
    );
    setLog((prev) => [id, ...prev].slice(0, 4));
  }, []);

  const toggleFrost = useCallback((id: string) => {
    setHabits((prev) =>
      prev.map((habit) => {
        if (habit.id !== id || habit.frost === 0) return habit;
        const spending = !habit.protectedDay;
        return {
          ...habit,
          protectedDay: spending,
          frost: spending ? habit.frost - 1 : habit.frost + 1,
          // Unprotecting a day you were already missing takes the run with it,
          // which is the honest reading: the token is what was holding it.
          streak: spending || habit.logged ? habit.streak : 0,
        };
      }),
    );
  }, []);

  const reset = useCallback(() => {
    setHabits(OPENING);
    setLog([]);
  }, []);

  return (
    <div className="grid gap-px border border-hairline bg-hairline lg:grid-cols-12">
      {/* --- The device ------------------------------------------------- */}
      <div className="flex justify-center bg-shelf p-5 sm:p-8 lg:col-span-5 lg:p-10">
        <div className="w-full max-w-[290px]">
          <Device header="TODAY">
            {/* The share of the day, as a ring and as a figure. */}
            <div className="flex items-center gap-4 border-b border-hairline px-4 py-4">
              <svg
                viewBox="0 0 120 120"
                className="size-16 shrink-0"
                role="img"
                aria-label={`${kept} of ${total} habits kept today`}
              >
                {/* The track, cut into the surface. */}
                <circle
                  cx="60"
                  cy="60"
                  r={RADIUS}
                  fill="none"
                  stroke="currentColor"
                  strokeWidth="6"
                  className="text-trench"
                />
                <motion.circle
                  cx="60"
                  cy="60"
                  r={RADIUS}
                  fill="none"
                  stroke="var(--lantern)"
                  strokeWidth="6"
                  strokeLinecap="butt"
                  transform="rotate(-90 60 60)"
                  strokeDasharray={CIRCUMFERENCE}
                  style={{ strokeDashoffset: dashOffset }}
                />
              </svg>
              <div>
                <motion.output className="figure block text-4xl text-bone">
                  {keptText}
                </motion.output>
                <p className="telemetry mt-1 text-silt">Kept today</p>
                <p className="telemetry mt-2 flex items-center gap-2 text-lantern">
                  <span aria-hidden className="beacon" />
                  <motion.span className="figure text-base">
                    {streakText}
                  </motion.span>
                  <span className="text-silt">day run</span>
                </p>
              </div>
            </div>

            {/* The habits. */}
            <ul className="flex flex-col">
              {habits.map((habit, i) => (
                <HabitRow
                  key={habit.id}
                  habit={habit}
                  index={i}
                  reduce={reduce}
                  onToggle={() => toggle(habit.id)}
                  onFrost={() => toggleFrost(habit.id)}
                />
              ))}
            </ul>
          </Device>

          <p className="telemetry mt-3 text-silt">
            Simulated in your browser · Android build is the product
          </p>
        </div>
      </div>

      {/* --- The readout rail ------------------------------------------- */}
      <div className="flex flex-col bg-shelf p-5 sm:p-8 lg:col-span-7 lg:p-10">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <h3 className="section-marker">Live readout</h3>
          <button
            type="button"
            onClick={reset}
            className="telemetry border border-hairline px-3 py-1.5 text-silt transition-colors hover:bg-shoal hover:text-bone focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-lantern"
          >
            Reset
          </button>
        </div>

        {/* A terminal, not a card list: newest first, monospaced, and empty
            until you touch something. The zero state says what to do rather
            than showing a placeholder. */}
        <div className="mt-4 flex min-h-[164px] flex-col border border-hairline">
          {log.length === 0 ? (
            <p className="flex flex-1 items-center justify-center px-4 text-center text-sm leading-relaxed text-silt">
              Tap a habit on the left to keep it. Come back to it tomorrow and
              the run is the thing that survives.
            </p>
          ) : (
            <ul className="compartment flex-1">
              {log.map((id, i) => {
                const habit = habits.find((h) => h.id === id)!;
                return (
                  <motion.li
                    key={`${id}-${log.length - i}`}
                    className="compartment grid-cols-[auto_1fr_auto] bg-shelf"
                    initial={{ opacity: 0, x: -8 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ duration: 0.24, ease: [0.16, 1, 0.3, 1] }}
                  >
                    <span className="telemetry bg-shoal px-2.5 py-2 text-silt">
                      &gt;
                    </span>
                    <span className="telemetry px-2.5 py-2 text-bone">
                      {habit.name} {habit.logged ? "kept" : "missed"}
                    </span>
                    <span className="telemetry px-2.5 py-2 text-lantern">
                      {habit.protectedDay ? "held" : `run ${habit.streak}`}
                    </span>
                  </motion.li>
                );
              })}
            </ul>
          )}
        </div>

        <dl className="compartment mt-4 grid-cols-2 sm:grid-cols-4">
          <Cell label="Kept" value={`${kept}/${total}`} />
          <Cell label="Run" value={String(streakSum)} />
          <Cell
            label="Frozen"
            value={String(habits.filter((h) => h.protectedDay).length)}
            tone="frost"
          />
          <Cell
            label="Tokens"
            value={String(habits.reduce((s, h) => s + h.frost, 0))}
            tone="lantern"
          />
        </dl>

        <p className="mt-4 max-w-prose text-sm leading-relaxed text-silt">
          Freeze tokens are the whole point. A missed day does not reset a
          streak while you hold one — it only costs you the token. Tap{" "}
          <span className="text-bone">Frost</span> on a habit, then untick it:
          the run survives.
        </p>
      </div>
    </div>
  );
}

/** The squared device the demo runs inside. */
function Device({ header, children }: { header: string; children: React.ReactNode }) {
  return (
    <div className="border border-hairline bg-ground">
      <div className="flex items-center justify-between border border-b-0 border-hairline bg-shoal px-3 py-2">
        <span className="telemetry text-silt">{header}</span>
        <span aria-hidden className="beacon" />
        <span className="telemetry text-silt">Demo</span>
      </div>
      <div className="border border-hairline">{children}</div>
    </div>
  );
}

/**
 * One habit.
 *
 * The row is the button — the whole 56px target, not a tick in the corner of
 * it, because the app's own answer is that logging is one swipe anywhere on
 * the card. `aria-pressed` carries the state so it is not colour-only.
 */
function HabitRow({
  habit,
  index,
  reduce,
  onToggle,
  onFrost,
}: {
  habit: Habit;
  index: number;
  reduce: boolean | null;
  onToggle: () => void;
  onFrost: () => void;
}) {
  const [press, setPress] = useState(false);

  return (
    <motion.li
      className="border-b border-hairline last:border-b-0"
      initial={reduce ? false : { opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{
        duration: 0.4,
        delay: reduce ? 0 : index * 0.07,
        ease: [0.16, 1, 0.3, 1],
      }}
    >
      <button
        type="button"
        aria-pressed={habit.logged}
        onPointerDown={() => setPress(true)}
        onPointerUp={() => setPress(false)}
        onPointerCancel={() => setPress(false)}
        onClick={onToggle}
        className="relative flex w-full items-center gap-3 overflow-hidden px-4 py-3.5 text-left transition-colors hover:bg-shelf focus-visible:outline-2 focus-visible:-outline-offset-2 focus-visible:outline-lantern"
      >
        {/* The fill sweeps left to right on keep. A colour swap would be
            instant and the sweep is what tells you it counted. */}
        <motion.span
          aria-hidden
          className="absolute inset-y-0 left-0 w-full bg-lantern/12"
          initial={false}
          animate={{ scaleX: habit.logged ? 1 : 0 }}
          transition={{ duration: 0.32, ease: [0.16, 1, 0.3, 1] }}
          style={{ transformOrigin: "left" }}
        />
        <motion.span
          aria-hidden
          className="relative size-5 shrink-0 border border-lantern"
          animate={{ scale: press ? 0.9 : 1 }}
          transition={{ type: "spring", stiffness: 320, damping: 20 }}
        >
          <motion.span
            className="absolute inset-0 bg-lantern"
            initial={false}
            animate={{ scale: habit.logged ? 1 : 0 }}
            transition={{ type: "spring", stiffness: 380, damping: 24 }}
          />
        </motion.span>

        <span className="relative flex-1">
          <span
            className={`block font-display text-[0.95rem] font-medium tracking-tight ${
              habit.logged ? "text-bone" : "text-silt"
            }`}
          >
            {habit.name}
          </span>
          <span className="telemetry mt-1 flex items-center gap-2 text-silt">
            <span className="figure text-[0.8rem] text-bone">{habit.streak}</span>
            <span>day run</span>
            {habit.protectedDay ? <span className="text-frost">· frozen</span> : null}
          </span>
        </span>

        <span className="telemetry relative text-silt">
          {habit.logged ? "Kept" : "Due"}
        </span>
      </button>

      {/* The token. Separate from the row because it is a different decision:
        one is "is today done", the other is "am I spending a hold on it". */}
      <div className="flex items-center gap-2 px-4 pb-3">
        <button
          type="button"
          disabled={habit.frost === 0}
          aria-pressed={habit.protectedDay}
          onClick={onFrost}
          className="telemetry border border-hairline px-2.5 py-1 text-silt transition-colors hover:text-bone focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-lantern disabled:cursor-not-allowed disabled:opacity-40 aria-pressed:border-frost aria-pressed:text-frost"
        >
          {habit.frost > 0 ? `Frost ×${habit.frost}` : "No tokens"}
        </button>
        <span className="telemetry text-silt">
          {habit.protectedDay ? "Day held" : "Day unprotected"}
        </span>
      </div>
    </motion.li>
  );
}

/** One cell of the summary grid. */
function Cell({
  label,
  value,
  tone = "bone",
}: {
  label: string;
  value: string;
  tone?: "bone" | "lantern" | "frost";
}) {
  const color = {
    bone: "text-bone",
    lantern: "text-lantern",
    frost: "text-frost",
  }[tone];

  return (
    <div className="bg-shelf px-4 py-3">
      <dt className="telemetry text-silt">{label}</dt>
      <dd className={`figure mt-1.5 text-xl ${color}`}>
        <data value={value}>{value}</data>
      </dd>
    </div>
  );
}
