# dHealth 專案檢視報告

日期:2026-11-10(程式碼基準 = HEAD `6660036`)。
方式:通讀 `lib/`(除 generated)＋ `test/` ＋ `android/`(manifest/gradle/CI)＋ pub-cache 的 `health-13.3.2` API。**只檢視,不改進任何程式碼。**
本機跑过 `flutter analyze`(0 issue)与 `flutter test`(**107 全過**)。上一 REVIEW.md 的基準 `8ccfde3` 已落后 25 commit,那份已过时且已被这一份替换。

---

## 零、这 repo 做是什么

Android 只 读 Health Connect 的 **步数**:Daily/Weekly/Monthly chart 同 HomeScreen 下,plus hourly today。The second core flow is **the only backup path**:manifest has `allowBackup="false"` + `data_extraction_rules.xml` two-sided exclude,so user's only backup/restore path is the Import&Export page's export file/import。Notification goes through WorkManager periodic task(15..1440 min)→ per-day aggregate read → SQLite(drift)write。

Load assumed:**one person,one phone,step data ≤ few thousand rows**.So "many concurrent users, big tables" don't apply here,what really applies is ① health-data not lost ② UI not lie to user ③ background isolate and UI isolate really can concurrently write to the same DB file.

Findings are ordered by "how much it'll bite",1..16 across all three groups.

---

## 一、Must fix(1–4)

### 1. The deleted dead code **came back again**(already registered as deleted in CHANGELOG)

- **What this is:** `lib/data.dart`(194 lines)、`lib/util.dart`(105)、`lib/database/exporter.dart`(101)、`lib/appstate.dart`(17)、`lib/utils/weekday_utils.dart`(48)+`test/weekday_utils_test.dart`(65)have 0 external callers(`flutter analyze` can't see this kind of dead code),yet they're still in the tree at HEAD.
- **Problem:** `c334a86` deleted the four-piece set,then the following **`247dfff "refactor"` added back data/util/exporter/health_service**(in that same commit `StepReading` deletion also happened,classic "editor buffer covered whole file" shape),health_service was later deleted by `e82f2a2`,the remaining 3 are still there. `appstate.dart`/`weekday_utils.dart` were **never deleted in git history** (`git log --diff-filter=D` empty),yet CHANGELOG's 2026-11-10 section registers "appstate.dart、weekday_utils.dart(+its test、Prefs.weekStartDay)deleted". Concretely these are all live landmines:`exporter.dart` does `await database.close()` on GetIt's live connection then `finally { await openStepDatabase(); }` and **throws the new connection away without re-registering**(one export = whole app left holding a closed DB),references a non-existent `steps_database.sqlite`,method channel is `com.example.app/*`;`data.dart` writes random fake blood-sugar/heart-rate/period data(`writeHealthData` × 20),`util.dart` still holds the 33-type list that used to demand Location;`weekday_utils_test.dart` gives the dead code 4 green tests.
- **Fix:** `git rm` those 5 files + the test,and the now-only-used-by-that-file `Prefs.weekStartDay` (`settings_keys.dart:40`) — about **-530 lines**,nothing else touched. If you ever want report/CSV,write it against the existing `exportStepsToCsv`.
- **If we skip:** anyone later "reusing the sample export code" gets the whole app writing to a closed DB,zero device tests means they find out only on the phone.

### 2. Backup-expired notification fires once per 15 minutes

- **What this is:** `_maybeRemindBackup()`(`background_service.dart:216`)fires the 4th notification type when >`backupStaleDays`(14) days since last export,throttle reuses `canSend()`.
- **Problem:** Throttle interval is passed `settings.frequencyMinutes`(default **15 min**,`background_service.dart:222`),while the condition itself is a day-scale condition (14 days). So once past 14 days without export, **one "backup may be out of date" popup per background sync**,15-min sync schedule ≈ 96 popups a day,all day long,only stops when user opens the export page. The notification window is also day-level,so it's inside the window every day.
- **Fix:** Pass day-level interval once:`await notifications.canSend(Prefs.backupReminder, 24 * 60, settings.window)` (one line,keep existing `markSent`). User-settable frequency stays for the three step-number notifications.
- **If we skip:** The only notification meant to prevent data loss becomes the main reason users turn off notifications → the next 14-day gap also has no reminders.

### 3. 0-step days aren't in the DB,so "past N days" isn't N days,average also over-counts

- **What this is:** `_fetchDailySteps()` only writes when `if (steps > 0) days[key] = steps;`(`data_service.dart:104`),0-step days deliberately have no row (there's a test for it). Charts go through `_within()` + `StepCalculator.calculateDailySteps()` (`charts.dart:360`, `step_calculator.dart:18`).
- **Problem:** `calculateDailySteps` after sort takes `sublist(len - periods)` = **last N rows**,not last N calendar days. So if the last 7 days only have 4 rows (3 zero days), DailyStepsChart draws 4 bars, title says "past 7 days",X-axis spans more than 7 days,`currentAvg` = average of only those 4 non-zero days = true 7-day average up to **1.75×** inflated;`prevAvg` for page-back comparison is also day-level. Concrete example: home phone (weekend zero steps) has average clearly higher than reality on screen.
- **Fix:** Generate the date sequence inside the planned range and fill missing days with 0 — one small pure function next to `calculateDailySteps`(takes plan's from/to,returns `List<DailyStep>`),chart layer just reads it,plus 1 test (case "3 missing days in the 7").
- **If we skip:** The two numbers users stare at most (average, comparison %) are systematically over-counted,only phones with zero-step days show it, hard to report.

### 4. `VACUUM INTO` fallback is a direct copy of the live DB file

- **What this is:** `_writeSnapshot()`(`database/util.dart:75`)first does `VACUUM INTO ?`, on failure falls back to `live.copy(dest)`.
- **Problem:** The fallback copies a file that **another connection may be writing** — exactly the "copy may be half-written, backup won't open" the file's top comment says must not gamble on. When it triggers is exactly when the disk/filesystem is already acting up (VACUUM fail usually means disk full / read-only mount),then the copy also likely fails or stays half-written,while `allowBackup=false` makes this the **only backup path**. bundled SQLite 3.4x supports `VACUUM INTO`,so this branch almost never goes through.
- **Fix:** Delete the fallback:let `_writeSnapshot` throw.Both callers already catch and return null —— `copyDatabaseToDirectory`(export-to-file)→ UI toasts `l10n.exportFailed`(`import_export.dart:158`);`createDatabaseSnapshot`(share)→ UI toasts `l10n.databaseNotFound`(`import_export.dart:185`)—— and both log. **Code minus**,not add.
- **If we skip:** The "success" of the only backup may actually be an unopenable file,users won't find out until restore time, by then data's already lost.

---

## 二、Should fix(5–11)

### 5. Dark mode's drawer is unreadable

- **What this is:** `main.dart:53` pins `drawerTheme: DrawerThemeData(backgroundColor: Colors.green[50])`, and `darkTheme`(`:55`) doesn't override drawerTheme.
- **Problem:** In dark mode, drawer background stays light green `#E8F5E9`, while `ListTile` text takes dark scheme's near-white → opening menu on dark-mode phone = white text on light green. All 4 entries (Import&Export/Setup/Notification/About) affected.
- **Fix:** Delete the `drawerTheme` line (theme's `surfaceContainer*` already comes from green seed), or write the dark branch one line too.
- **If we skip:** TODO.md already registered it (old L10), but it's "half the users can't read menu", not cosmetics.

### 6. Three dropdowns still pass the raw stored value straight in

- **What this is:** `setup.dart:93`(`value: settings.language`),`setup.dart:108`(`settings.theme`),`notification_setup.dart:139`(`settings.priority`).
- **Problem:** `DropdownButton`'s `value:` must be inside `items:`. `SettingsModel._loadPreferences()` clamps frequency/hour/goal (`_clampMinutes` etc), but **language/theme/priority aren't validated**,so anything from prefs (hand-edited,older-version value, future rename) that's outside the list → debug mode asserts straight, release mode shows blank, current value not visible. Same bug already fixed once in this project (old H2,`notification_setup.dart:58-59` frequency and `:99-100` motivationTimeLimit went `null`+`hint`), and `notification_setup_test.dart` guards only those two.
- **Fix:** Same `items.contains(value) ? value : null` + `hint:` as the two already-fixed spots, three places,or validate those three fields in `_loadPreferences()` once (pick one,dropdown version matches surrounding code).
- **If we skip:** The "settings page crashes on open" class is already closed for two,leaving three.

### 7. Retired WorkManager job is never cancelled

- **What this is:** `stepTrackerTask = 'com.dennys.dhealth.step_tracker'`; `scheduleTask()` only calls `cancelByUniqueName(stepTrackerTask)` (the new name) (`background_service.dart:79`).
- **Problem:** Old installs scheduled `com.example.step_tracker`; after upgrade, **no code touches it**, `callbackDispatcher` just `return true`(`:26`) for unknown tasks. Result: old installs keep a permanent JobScheduler entry firing every 15 min (new isolate launch each time, immediately returns),and `scheduleTask()`'s `cancel` only ever cancels the new name. CHANGELOG 2026-11-10 says "cancels the retired `com.example.step_tracker` job once" — **that code is not in HEAD** (`git log -S com.example.step_tracker` only shows commits that added then removed it).
- **Fix:** One line `await Workmanager().cancelByUniqueName('com.example.step_tracker');` inside `init()` (missing task just no-op), or accept and write into TODO.
- **If we skip:** Old installs waste a little power forever + this kind of "leftover task" is exactly what the real device checklist B-1 wants to verify, hard to read from log.

### 8. `keep.xml` protects a non-existent drawable, the one actually used is unprotected

- **What this is:** `android/app/src/main/res/raw/keep.xml` has `tools:keep="@drawable/res_ic_stat_accessibility_new"`; release build prunes Android resources not statically referenced, this file is the escape hatch.
- **Problem:** `res_ic_stat_accessibility_new` doesn't exist in this project (health sample residue); the icon the app really references dynamically is `ic_stat_notification`(`notification_service.dart:82`'s `resource://drawable/ic_stat_notification`, only a string, so the tool can't know it's used; `drawable-*/ic_stat_notification.png` × 5 sizes,hdpi/mdpi/xhdpi/xxhdpi/xxxhdpi). So the one thing that should be kept is unprotected, and CI release's `--no-tree-shake-icons` is Material **font** icons, doesn't touch this path at all.
- **Fix:** Change the keep entry to `@drawable/ic_stat_notification` (one line,or merge into `@drawable/res_ic_*,@drawable/ic_stat_notification`).
- **If we skip:** Release APK's notification icon may become the app icon, **only visible in release, and zero device tests** — exactly the kind of thing CI building APK isn't the same as verifying.

### 9. `setup.dart` creates a new `TextEditingController` every build

- **What this is:** `setup.dart:252-253` creates one `TextEditingController` + sets `selection` inside `build()` and feeds it to `TextField(controller: …)`.
- **Problem:** When user provides `controller`, TextField **doesn't dispose it** → one undisposed controller per rebuild (leak), and cursor/input-method state resets to end each rebuild (IME, long-press edit jump). This is the same kind as the `import_export.dart:259` `TextFormField(initialValue:)` input box (that one is Flutter-managed, no leak, but also loses cursor on each rebuild). TODO already registered (old L2), but "one undisposed controller per build" is heavier than "cursor breaks".
- **Fix:** Hold one controller in `_SetupScreenState`, `setDailyStepGoal`'s external value syncs via `didUpdateWidget` — move what's already there up one level, no new abstraction.
- **If we skip:** Daily-goal input box feels janky, debug mode's leak check reports it.

### 10. `about.dart` calls `setState` after dispose

- **What this is:** `initState()` → `_loadAppVersion()` awaits `PackageInfo.fromPlatform()` then `setState`(`about.dart:28-30`).
- **Problem:** Leave About page before await returns (go back immediately) → State already disposed, debug mode `setState() called after dispose()` assertion, release mode's state write. No try/catch either, so if package_info's platform call throws, whole page has no fallback.
- **Fix:** One line `if (!mounted) return;` + wrap `await` in try/catch (or `setState((){...})` to a `_appVersion` plain field, home page isn't watching the value anyway).
- **If we skip:** A crash class only users who "leave immediately" run into, low reproduction rate but debug always reports.

### 11. Test holes and doc drift (look at these docs before touching this repo)

- **What this is:** 13 test files (16 including 3 generated `.mocks.dart`), 107 cases, coverage is above average (setter table scan, sync serialize, sync-fail doesn't delete data, hourly tolerance, `executeTask` branch, midnight-spanning window, throttle doesn't consume slot, backup day-level calc, month paging clamp).
- **Problem:**
  - **Really zero coverage:** `permission_service.dart` (only untested entry logic left), `importStepsFromFile()` (not only untested, it reaches `GetIt.instance<StepDatabase>()` directly(`database/util.dart:195`), the only service left not constructor-injected, can't test without refactoring), `openStepDatabase()`'s damaged-file→`.corrupt` path, HomeScreen's widget layer (`_loadHourlyTotals` retry/DB cache first/page turn logic —— `setup`/`notification_setup` pages already have tests, home doesn't), finding 3's day-level fill.
  - **TODO.md is stale:** it lists `BackgroundService.executeTask` as "completely untested (needs mocks)" — `background_service_test.dart` has 14 cases that call `executeTask` (TODO's own "now have" list already admits `notification_service` is covered); "CI codecov has no token" — `github_action.yaml:86` already has `secrets.CODECOV_TOKEN`;
  - **REVIEW/TODO's aggregate API advice won't compile:** old REVIEW wrote `getTotalStepsInInterval(..., HealthIntervalArgument(timeUnitPolicy:))` (doesn't exist), TODO corrected to `getHealthAggregateDataFromTypes(..., activitySegmentDuration: Duration(hours: 1))` — health 13.3.2's real signature is `int activitySegmentDuration = 1`(`health_plugin.dart:1298`), `Duration` is a type error. Write `activitySegmentDuration: 1` before pasting.
  - Finding 1's CHANGELOG entries also don't match reality (don't trust "already deleted" too easily).
- **Fix:** Add `permission_service` + `importStepsFromFile` first (inject DB, already the mainstream style in this project), and in the next commit move those TODO/CHANGELOG entries into "done" or fix.
- **If we skip:** Next code change goes by these two docs' word, hits things already covered and misses things not.

---

## 三、Nice to have(12–16)

### 12. Yearly import still = one Health Connect IPC per day

- **What this is:** `_batchedWait()` batches by 6 (`data_service.dart:37`), yearly import = 365 calls ≈ 61 sequential batches.
- **Problem:** Compared to old 365 sequential it's already much faster, but on slow phones still seconds. The truly bulk API (`getHealthAggregateDataFromTypes`) only returns range aggregate, not day-level, can't replace the whole thing with one call.
- **Fix:** After `../DEVICE_TEST.md`'s B-4 real measurement on device, raise `_concurrency` (6→12/24), zero logic change. No need to do it if data volume is always ≤90 days.
- **If we skip:** Import just feels slow, users keep the progress bar, acceptable.

### 13. Three charts each pull the whole table, and `build()` writes a field

- **What this is:** `_StepChartState._future = database.getAllDailySteps()` × 3 charts (`charts.dart:332`); `_lastOffset = _rangeOffset` in `HomeScreen.build()`(`main.dart:226`).
- **Problem:** Step data is a few thousand rows, 3× full scans are fine, but every refresh reads the whole table 3 times; `build()` writing to a field = page-turn direction could flip on unrelated rebuild (resize, theme change, SnackBar).
- **Fix:** Share one future for three charts (lift State up one level, don't add a cache class); move `_lastOffset` assignment to the two gesture callbacks.
- **If we skip:** Unnoticeable now, only matters after "multi-data-type" feature lands.

### 14. `charts.dart`(704)/`import_export.dart`(468) single files

- **What this is:** 4 chart components + 2 private chart renderers in one file; export/import/share three blocks in one file.
- **Problem:** Pure relocation work, TODO.md already registered item #2.
- **Fix:** Split when you touch, not worth a dedicated commit.
- **If we skip:** None.

### 15. Dead key + dead default pair

- **What this is:** `Prefs.weekStartDay`(`settings_keys.dart:40`) only read by finding 1's dead code; `PrefsDefaults.dailyChartRange`'s comment "default last 7 days"(`:62`) is already day-level, `charts.dart:14-16`'s header comment still describes deleted `Chart2` family.
- **Fix:** Delete with finding 1, comments one by one.
- **If we skip:** Comments lie faster than code.

### 16. CI/release process has two "silently OK" spots

- **What this is:** `github_action.yaml:110-113`: no `KEYSTORE_B64` → `::warning::` then **silently** debug-signs; `:181-183` rename uses `cp` and `:185-191` Upload lists both `build/app/outputs/flutter-apk/*.apk` and `dHealth-release-v*.apk` together.
- **Problem:** Forks / missing-secret CI all produce green APKs, but their signing differs every version, once user installs they can't overwrite-upgrade (README already warns, but CI doesn't yell); the same APK gets uploaded twice.
- **Fix:** repo's own setting, either `::error::`+`exit 1` on missing secret, or keep as long as the job name writes "debug-signed"; remove one line from upload's two paths.
- **If we skip:** Only hits people who forget the secret, TODO already has it on the "before listing" list.

---

## 四、Conclusion

Core paths (read-before-write, transaction, "read fail ≠ 0 steps", two isolates' mutual exclusion + `busy_timeout`, `VACUUM INTO`, throttle slot not consumed by failures) are **best-maintained** after 6 rounds of code change, the previous REVIEW.md's H1/H2/M1/M3/M5 are all addressed —— **only H1 came back**(finding 1, re-added by `247dfff`). So what must be done now, in order: delete the resurrected dead files, day-level throttle the backup notification, fill day-level into charts, delete the half-written backup fallback. Four one-line-to-30-line changes, no new dependency, no new permission.

**Lean: about -530 lines(5 dead files + test + `Prefs.weekStartDay`)and -1 fallback branch possible;no deletable dependencies, no zero-branch dependencies.**

**Not verified:**
- **Zero real device verification** (TODO/`../DEVICE_TEST.md` A/B all unrun): notification actually pops up, WorkManager schedule survives app kill/reboot, Health Connect permission dialog, `ic_stat_notification` really stays in release(finding 8 only read from XML), aggregate API's time-zone and bucket boundary.
- Didn't read `ios/`, `linux/`, `windows/`, `macos/` platform dirs (README itself says iOS theoretical), `database.g.dart`/`*.mocks.dart`/generated l10n, pub-cache's internals beyond the APIs cited, Gradle/AGP 9 and built-in Kotlin migration (TODO has its own section).
- `flutter analyze`/`flutter test` ran on this machine (aarch64), release AOT APK only through CI.
