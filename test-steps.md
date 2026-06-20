  ---
  Test 1 — Run all unit tests

  1. In Xcode, press Cmd + U (or Product → Test).
  2. Open the Test Navigator (⌘6) when done.
  3. Confirm that all tests in ReadyKitAlertTests are green — especially:
    - CreateEmergencyKitUseCaseTests/testCreateEmergencyKitWithPhoto
    - DuplicateItemInEmergencyKitUseCaseTests (all methods)
    - FetchAllEmergencyKitsUseCaseTests (all methods)

  ✅ Pass criteria: No red tests. If testCreateEmergencyKitWithPhoto was previously failing when running all tests together, it should now pass.

  ---
  Test 2 — Batch notifications are scheduled for a future item

  Setup (do this before the test):
  1. Run the app on Simulator.
  2. When the notification permission prompt appears, tap Allow.
  3. Navigate to Reminder Settings (the Settings/Bell tab).
  4. Use the Expiry Reminder Lead stepper to confirm it is at 30 days (the default). Leave it there.
  5. Note the Daily Notification Time — default is 12:00 PM. Leave it for now.

  Steps:
  1. Go to any Emergency Kit (or create one if none exists).
  2. Add a new item with an expiration date 60 days from today (well beyond the 30-day lead window). Save the item.
  3. Background the app — press Cmd + Shift + H (Home button) on the Simulator.
  4. Foreground the app — tap its icon to bring it back. This triggers scheduleReminders().

  Verify in console — filter on expiry batch:
  [INFO] Scheduled expiry batch[0] for <date ~30 days from now>
  [INFO] Scheduled expiry batch[1] for <date ~31 days from now>
  [INFO] Scheduled expiry batch[2] for <date ~32 days from now>
  [INFO] Scheduled expiry last-chance for <date ~59 days from now>

  ✅ Pass criteria: You see 3 expiry batch lines and 1 expiry last-chance line. The dates should start approximately 30 days from today (when the lead window begins).

  ---
  Test 3 — "Keep reminding me" transitions from batch to persistent

  This test requires a batch notification to be delivered to the Simulator. Since batch triggers are scheduled days in the future, use the LLDB console to inject a test notification instantly.

  Steps:
  1. With the app running and foregrounded in Simulator, click Debug → Pause in Xcode (or press the pause button in the debug bar) to pause execution.
  2. In the LLDB console, run this import first (required — UserNotifications is not in scope by default):
  expr -l swift -- import UserNotifications
  3. Then paste and run this line:
  expr -l swift -O -- { let c = UNMutableNotificationContent(); c.title = "Expiring items detected"; c.body = "Expiring/Expired items detected. Please check your emergency kits."; c.categoryIdentifier = "EXPIRY_BATCH_CATEGORY"; c.sound = .default; UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "expiry-batch-0", content: c, trigger: UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)), withCompletionHandler: nil) }()
  4. Click Continue (▶) to resume the app.
  5. Background the app (Cmd + Shift + H) — the notification only appears when the app is not in the foreground, or the app's willPresent delegate will show it as a banner anyway.
  6. Within 5 seconds, the notification banner appears. Long-press the banner (or swipe down to expand) to reveal the action buttons.
  7. Tap "Keep reminding me".

  Verify in console — filter on reminding:
  [INFO] User tapped 'Keep reminding me'; transitioning to persistent expiry reminder.
  [INFO] Persistent expiry reminder established after 'Keep reminding me' tap.

  Also filter on expiry-batch and persistent to confirm batch IDs were removed and one persistent reminder was added.

  ✅ Pass criteria: You see both log lines above. The batch notification IDs are removed and a single persistent reminder is scheduled.

  ---
  Test 4 — Persistent reminder is scheduled when items are expiring/expired

  Steps:
  1. Add a new item to any Emergency Kit with an expiration date of yesterday (or today, using the date picker).
  2. Background the app (Cmd + Shift + H), then foreground it again. This triggers scheduleReminders().

  Verify in console — filter on persistent:
  [INFO] Scheduled persistent expiry reminder (repeats daily at user's notification time)

  Also confirm that expiry batch lines do not appear — the persistent path should be taken instead.

  ✅ Pass criteria: One persistent expiry reminder log line appears. No expiry batch lines.

  ---
  Test 5 — Changing the notification time updates the trigger

  Steps:
  1. Go to Reminder Settings.
  2. Change the Daily Notification Time pickers to a different time — for example, 3:30 PM.
  3. Tap Save in the top-right corner. This saves preferences and reschedules all reminders.

  Verify in console — filter on scheduled:
  - You should see notifications being scheduled again (batch or persistent, depending on your item data from the previous tests).
  - The log lines will show new dates reflecting the 3:30 PM time.

  To confirm the time specifically, filter on batch or persistent and read the date in the log. It should contain the hour and minute you selected.

  ✅ Pass criteria: New scheduling log lines appear immediately after saving. If you still have a future item from Test 2, the batch lines should show dates with the newly chosen time of day.

  ---
  Test 6 — Background task re-registers after kill and relaunch

  Steps:
  1. In the Simulator, with the app foregrounded, press Cmd + Shift + H to go to the Home screen.
  2. Force-quit the app: on the Simulator, double-press the Home button (or swipe up and hold if using a modern iPhone Simulator skin) to open the app switcher, then swipe the ReadyKit card upward to close it.
    - Shortcut: in Xcode, press Stop (■) to kill the app process, then re-run with Cmd + R.
  3. The app launches fresh. Watch the console.

  Verify in console — filter on background task:
  [INFO] Background task registered successfully: io.wdy.ReadyKitApp.refresh
  This line is printed in ReadyKitApp.init(), confirming registerTask() ran on launch.

  Optional — simulate background task execution:
  1. Pause the app in LLDB.
  2. Run:
  e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"io.wdy.ReadyKitApp.refresh"]
  3. Resume the app. Filter console on background and confirm the task handler fires and reschedules reminders.

  ✅ Pass criteria: The registration log line appears every time the app is (re)launched. Background task simulation triggers reminder rescheduling.

  ---
  Quick reference — console filter keywords

  ┌──────┬─────────────────┬────────────────────────────────────────────────────────┐
  │ Test │ Filter keyword  │                 What you expect to see                 │
  ├──────┼─────────────────┼────────────────────────────────────────────────────────┤
  │ 2    │ expiry batch    │ 3 batch lines + 1 last-chance line                     │
  ├──────┼─────────────────┼────────────────────────────────────────────────────────┤
  │ 3    │ reminding       │ Transition logged, batch IDs removed, persistent added │
  ├──────┼─────────────────┼────────────────────────────────────────────────────────┤
  │ 4    │ persistent      │ One persistent reminder line; no batch lines           │
  ├──────┼─────────────────┼────────────────────────────────────────────────────────┤
  │ 5    │ scheduled       │ New scheduling lines with the updated time             │
  ├──────┼─────────────────┼────────────────────────────────────────────────────────┤
  │ 6    │ background task │ Registration success on every launch                   │
  └──────┴─────────────────┴────────────────────────────────────────────────────────┘
