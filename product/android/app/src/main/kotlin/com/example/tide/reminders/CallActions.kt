package com.example.tide.reminders

import android.content.Context

/**
 * What answering a reminder does, wherever it was answered: on the lock
 * screen, or with a button on a notification with the app closed.
 *
 * Native code never changes a habit or a to-do. An answer here is one of two
 * things — the ringing stops, or it stops and comes back in a while — and
 * both are the phone's to keep, because the screen has to be answerable with
 * no app running at all. Nothing given to a reminder reaches the day's
 * records: those are written by the app, or by the hands on it.
 */
object CallActions {
    /** Put it off. [minutes] is 0 when the caller had no number to give. */
    const val LATER = "later"

    /** Heard, and nothing more asked for. */
    const val DISMISS = "dismiss"

    /** What a button with no number of its own puts a reminder off by. */
    const val LATER_DEFAULT_MINUTES = 10

    /** An afternoon. Past that a reminder is not interrupting anybody. */
    const val LATER_MAX_MINUTES = 240

    fun resolve(context: Context, item: ReminderItem, outcome: String, minutes: Int = 0) {
        when (outcome) {
            LATER -> later(context, item, minutes)
            DISMISS -> Unit
        }
        ReminderNotifications.cancelFor(context, item)
        TideCallService.answered(context, item.key)
        ReminderScheduler.rearm(context)
    }

    /**
     * Put [item] off by [minutes], from the call or a notification's button.
     *
     * The last one allowed is the end of it, and it is deliberately quiet:
     * the reminder is spent, and a fourth "you can still put this off" on the
     * lock screen at twenty past eight in the morning is only noise. What is
     * left in the shade is the missed reminder, and nothing is added to it.
     */
    fun later(context: Context, item: ReminderItem, minutes: Int = LATER_DEFAULT_MINUTES) {
        if (item.snoozes >= ReminderBook.timing(context).maxSnoozes) return
        if (item.test) return
        val after = minutes.coerceIn(1, LATER_MAX_MINUTES)
        val at = System.currentTimeMillis() + after * 60_000L
        ReminderBook.addSnoozed(
            context,
            item.movedTo(at).with("snoozes", item.snoozes + 1).with("floating", false),
        )
        ReminderScheduler.rearm(context)
    }

    /**
     * A "later" chosen inside the app, where the app counted the ones it sent.
     *
     * The book is asked, and the item's own count is what decides: the "laters"
     * the app sends can only ever be one, because the app is answering a
     * single call and then forgetting it. So the next count is the item's own
     * plus that one, and the [ReminderBook.timing] cap is applied to the
     * result — which is what stops a "later" given in the app from being a
     * fourth after three, or from resetting the count back down each time.
     */
    fun laterFromApp(context: Context, item: ReminderItem, after: Long, laters: Int) {
        if (item.test) return
        val count = maxOf(laters, item.snoozes + 1)
        if (count > ReminderBook.timing(context).maxSnoozes) return
        val at = System.currentTimeMillis() + after.coerceIn(1, LATER_MAX_MINUTES * 60_000L)
        ReminderBook.addSnoozed(
            context,
            item.movedTo(at).with("snoozes", count).with("floating", false),
        )
        ReminderScheduler.rearm(context)
    }
}
