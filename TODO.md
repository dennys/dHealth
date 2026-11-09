# dHealth TODO

慣例：一個待辦一段，寫清「檔案:行」與「為什麼现在是這樣」，做完就刪掉這條。

---

## 本機建置（dgx1 = aarch64）— 2026-11-09

**這一節只講 dgx1 這台主機，別外推成「本專案不能出 release」**：Windows（x86-64）出 release 已實測裝機、
CI 也正常出 artifacts；卡住的只有 Linux/aarch64 —— AOT 的 `gen_snapshot`，Google 的 engine bucket 裡
**沒有 linux-arm64 host 版**（`android-arm64-release/artifacts.zip` 只有 flutter.jar），qemu 模擬 x86-64 那條
也試過行不通。所以在 dgx1 上日常就只出 **debug**：
`flutter build apk --debug --target-platform android-arm64`（實測 108 MiB，`CN=Android Debug`）。
需要的環境：`JAVA_HOME=~/jdk21`、`ANDROID_HOME=~/android-sdk`。

- **本機专用的依賴釘選放 `pubspec_overrides.yaml`（已 gitignore → CI／正式版零影響）**：
  `path_provider_android: 2.2.23`、`shared_preferences_android: 2.4.8`。原因：11-08 `d9bcde6`
  全數升級後這兩支會拉 `jni`（有 `CMakeLists.txt`）→ 觸發 CMake+NDK 原生編譯，而本機 SDK 的
  cmake 與 NDK 的 clang 都是 x86-64 檔（`Syntax error: ")" unexpected`）→ `:jni:configureCMakeDebug` 必敗。
  舊版不需原生編譯、pub-cache 也已有 → 零下載。
- 副作用：`pub get` 會把 `pubspec.lock` 與 `linux|windows/flutter/generated_plugins.cmake` 改髒
  （本地 overrides 的固有行為）。**build 完請 `git checkout` 這三支**，別 commit 進去 ——
  那等於把 11-08 的升級在 repo 層回退，CI 也會跟著用舊 plugin。
- `android/gradlew` 與 `gradle/wrapper/gradle-wrapper.jar` 不在版控**不是 bug**：flutter 會從
  `bin/cache/artifacts/gradle_wrapper` 自動注入。真正決定跑哪版 Gradle 的是有被追蹤的
  `android/gradle/wrapper/gradle-wrapper.properties`（現行 pin 9.3.1，實測 `./gradlew --version` = Gradle 9.3.1）。
- 另：NDK 的 `llvm-strip` 目前是 11-04 放的殼（GNU strip 代替，不認識的 arch 略過；原檔留檔
  `llvm-strip.x86-real`）→ 非 arm64 的 native 庫其實沒被 strip，debug 版無妨，但 APK 偏大與這有關。

---

## 2026-11-06 本輪已做（未 push，commit 見 `git log`）
- **minSdk 34 → 33（支援 Android 13）**。實測 `checkDebugAarMetadata` 過得去
  （`connect-client 1.2.0-alpha02` 的 AAR 只宣告 minSdk 26，gradle cache 內 140 個 AAR 無一要求 ≥28）。
- **修掉 3 個設定 setter 的 copy-paste bug**（`lib/settings_model.dart`）：
  `setActiveEndHour`（參數名打錯，賦值取自 getter 舊值 → 設定存不進去）、
  `setShowDailyStepGoal`（賦成 `showCumulative`）、`setStopOnTerminate`（寫到 `_startOnBoot`）。
- **新增 `test/settings_model_test.dart`**：24 個 setter 用一張表全掃（`InMemorySharedPreferencesAsync`），
  這類「賦值給錯欄位」的 bug 從此有網可接。dHealth 測試 20 → 43。
- **主題與 dNeko 對齊**：`ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.green))`
  （亮／暗都從同一顆 seed），拔掉 deprecated 的 `accentColor`，主頁 8 顆手調 `Colors.blue`
  的 `TextButton` 改成 `FilledButton` 交給 theme 上色。

---

## 2026-11-06 本輪已做（第三輪：重審自己上一輪的產出）

上一輪改完後重讀一次全部程式碼，抓到的（含上一輪自己留下的）都修了；`flutter analyze` 0 issue、
`flutter test` 62 全過。

- **匯入中途失敗會吃掉資料**（`data_service.dart`）：舊寫法是「邊讀邊寫」，勾了「匯入前清除」時
  第一段就把整張表清空，第 2 段讀取失敗（Health Connect 很常見）→ 資料庫只剩第一段，
  而訊息只顯示「匯入失敗」。現在改成**全部讀成功 → 一次性 transaction 寫入**，
  任何一段讀不到就是「資料庫一個字節都沒動過」（有回歸測試）。順手刪掉沒人呼叫的 `refreshAllData()`
  （它也是「刪全部再只寫 30 天」的形狀，留著遲早有人按）。
- **備份可能是半套**（`database/util.dart`）：`createDatabaseSnapshot` 的註解寫 VACUUM INTO、
  實際是 `File.copy()` —— 對一個有活著連線的 SQLite 直接複製，可能複製到寫一半的內容，
  而 `allowBackup="false"` 之後這就是使用者唯一的備份路。現在真的走 `VACUUM INTO ?`（失敗才退回複製並留 log），
  匯出到目錄也共用同一條路。
- **「今天 0 步」不能是讀不到的代名詞**（`data_service.fetchStepPoints` + `charts.HourlyStepsChart`）：
  舊的回空清單同時代表「讀取失敗」與「真的 0 步」，主畫面因此會畫一條 0 步的線骗人。
  現在讀不到回 null，圖表顯示「讀不到今天的步數」。
- **背景 isolate 沒 initialize 通知插件**（`background_service.callbackDispatcher`）：
  `AwesomeNotifications` 是 per-isolate 的，只在 UI 那側 initialize 過 → 背景的通知永遠发不出去
  而且被 catch 吃掉。現在兩邊都 initialize（同 `configureDependencies()` 的教訓）。
- **節流槽被白燒**（`notification_service`）：`allowSending()` 在「判斷」的當下就寫時間戳，
  於是通知權限沒給、或建立通知失敗時，使用者一顆都沒看到卻要再等一個 frequencyMinutes。
  現在拆成 `canSend()`（只判斷）+ `markSent()`（真的顯示成功後才記）。
- **`executeTask` 跟自己的註解做反了**：註解寫「一律以 prefs 現值為準」，程式碼卻是 `inputData` 優先
  → 使用者改了每日目標要等排程被換掉才生效。改成 prefs 優先。
- **每次進場都被丟到系統設定頁**（`permission_service`）：權限永久拒絕時 `openAppSettings()` 是
  每支 app 啟動都會走的路徑 → 變成啟動迴圈。改成只記 log，由橫幅的 Retry 按鈕讓使用者自己按。
- **選單按鈕一點就 assertion**（`main.dart`）：`Scaffold.of(context)` 用的是 HomeScreen 自己的
  context（在 Scaffold **之上**）。改成包一層 `Builder`。
- **通知時段有兩個來源**（`notification_setup.dart` vs `setup.dart`）：通知頁那組 Start/End Time
  存進 `notification_start_time`/`notification_end_time`，而**沒有任何程式碼讀它**；真正生效的是
  設定頁的 `activeStartHour/EndHour`（而且那個時間選譯器還有「開起來是 end 的時間」的複製貼上 bug）。
  刪掉裝飾品那組（連 key 與 setter），通知頁留一行指路文字。
- **同一個開關控制兩個銷毀性動作**（`import_export.dart`）：一個 `_clearDataBeforeImport` 同時挂在
  「從手機匯入」與「從檔案還原」兩張卡上，動一個另一個也跟着變。拆成兩個，並在兩邊都加上
  「會先刪除全部現有資料」的警告文字。
- `getIt<Health>().configure()` 之前在 initState 裡 unawaited 丢出去，Health Connect 缺席的機器上
  會變成 unhandled exception；改成接住並 `appError`。權限橫幅也改成顯示**實際失敗的那一項**
  （之前恆顯示 healthRead 那句話）。
- manifest 再拿掉 `RECEIVE_BOOT_COMPLETED`（本 app 沒有 boot receiver；WorkManager 的週期任務由
  JobScheduler 自己跨重開機保留）。

## 2026-11-06 第六輪：把「還留著」的項目清掉

- **About 頁的假信箱**：原本寫死 `support@dhealth.app` —— 那個網域不是我們的，使用者的抱怨信會進到
  陌生人收件匣（而我們永遠不會知道）。改成 `lib/widgets/about.dart` 的 `kSupportEmail`：
  **沒填就整段不顯示**，不放假的。上架前填進去（Play 控制台也要同一個）。
  `contactDesc` 也從「信箱寫死在翻譯字串裡」改成 ICU placeholder `{email}`。
- **補上 `dataExtractionRules`**：manifest 的 `allowBackup="false"` 在 Android 12+ 只管舊的後端備份，
  **雲端備份與「搬到新手機」(device-transfer) 是由 `res/xml/data_extraction_rules.xml` 另外管的** ——
  沒有這個檔案，步數資料庫（健康資料）會跟著新機移轉跑到別台裝置上。
  現在兩邊都排除，備份一律走 App 自己的「匯出到檔案／分享」。
  ⚠️ 這是權衡：使用者換新手機時步數**不會**跟著移轉，要自己匯出檔還原。要放行就只拿掉
  `<device-transfer>` 那組 exclude（`AndroidManifest.xml` 的 `android:dataExtractionRules`）。
  → XML 只能靠 build/真機驗（本機 JDK 8 build 不了 apk）。
- **`executeTask` 不再白讀 DB**：`_todayStepCount()` 移到「同步成功」判斷之後；失敗那次讀到的
  本來就是要被丟掉的舊資料。

`flutter analyze` 0 issue、`flutter test` 61 全過。

### 這一輪動不到（要人、要密鑰）
release 簽名（目前是 debug key）、CI 的 codecov token、真機驗收單整張。

---

## 2026-11-06 第五輪：自己改完再審一次（review again）的收穫

這一輪不是改新功能，是把前幾輪（包含我自己）寫出來的東西當陌生 code 讀。找到並修掉：

- **`setup.dart` 的「顯示每日目標」開關綁錯欄位**：`value: settings.showCumulative`（從上面那顆複製
  過來沒改），`onChanged` 卻是 `setShowDailyStepGoal`。後果：關掉「累計步數」後這顆永遠顯示 OFF，
  但目標線其實還開著 —— 點第一下只把顯示改成 ON、圖表毫無變化，看起來像壞掉。而 `charts.dart` 的
  `_MiniSwitch` 綁的是對的欄位，兩個畫面會互相打臉。
  → 新增 `test/setup_screen_test.dart`（3 條 widget 測試）：setter 表掃不到這種 bug（setter 是對的，
    錯的是 UI 讀的欄位），只能在 widget 層驗。已驗證「把 bug 塞回去測試會紅」。
- **從子頁面回來不會重抓圖表**：`_open()` 用 `Navigator.push`，底下的 tree 沒被 dispose，
  圖表是 FutureBuilder + `_refreshToken`，token 不變就不重查 → 使用者在匯入頁讀了 30 天按返回，
  看到的是匯入前的舊圖，會以為匯入沒生效（改每日目標/顯示開關回來也一样）。
  → `_open` 改 async，pop 回來 `_refreshToken++` + 重抓 hourly。
- **還有 4 處把例外內容攤在面板上**：`_sync` 的 catch、手機匯入 catch、檔案匯入 catch、分享 catch
  都是 `'${l10n.xxx}: $e'`。上一輪我說「例外堆疊不會再跑進 SnackBar」只講對了一半（只有 enum 那條路）。
  → 面板只給「失敗了」，`$e` 一律只進 `appError`。
- **`activeHoursRange` 產生出來的簽名是 `(Object, Object)`**：arb 沒宣告 placeholder 型別，
  傳字串進去也照收、照畫。→ 補 `@activeHoursRange` 的 placeholders type: int，現在是 `(int, int)`。
- **每日目標輸入框靜默吃掉不合法輸入**：`if (合法) 才 set`，不合法就什麼都不做，欄位下次 build
  跳回舊值 → 使用者看到的是「打了數字沒反應」。→ 加一句範圍提示（新 key `dailyStepGoalRange`）。
- 我上一輪寫的註解裡有個 placeholder 殘留（「自己要的-notification 時段」），改成正常句子。

### 還留著的小東西（不是 bug，看到了再說）
- `charts.dart` 651 行、`import_export.dart` 457 行：要拆就拆，純搬家（第六輪決定不動，等有實作需求再說）。
- `_todayStepCount()` 多讀一次 DB 的問題已在第六輪修掉。

---

## 2026-11-06 第四輪：把上一輪列出的「要人類決定」全部做掉

`flutter analyze` 0 issue、`flutter test` 58 全過（少的 4 條是刪掉已不存在設定的測試）。

- **四顆會騙人的開關整組刪除**：`setup.dart` 的 Start on Boot / Stop on Terminate / Persistent Sync
  與 `notification_setup.dart` 的 New Accomplishment —— 它們只把值寫進 prefs，全案 0 個讀取者，
  而 Persistent Sync 在 Android 上本來就做不到「使用者強制停止後仍同步」。
  連同 `SettingsModel` 的欄位/getter/setter、`Prefs` 的 key 與預設值、l10n 的六個 key 一起拔除
  （背景同步真正的開關是 Enable Background Sync，它真的會去重排 WorkManager）。
- **通知時段終於可以跨午夜**：`showActiveHoursPicker` 原本用 `endMinutes <= startMinutes` 把
  22:00 → 07:00 也一起擋掉，但 `NotificationWindow.contains()` 本來就支援跨午夜 → 夜貓子設不了
  自己要的時段。現在只擋「開始＝結束」（資料庫只有「時」的解析度），并把字幕與錯誤訊息放進 l10n
  （新增 `activeHoursRange`、`activeHoursSameHourError`、`oneHour`，刪掉 `endTimeError`）。
- **服務層不再吐使用者文字**：`StepSyncResult` 的 `message`（硬編中文）改成 `status` + `detail`，
  `detail` 只進 log；新增 `StepSyncStatus.invalidRange`（「日期選錯」與「Health Connect 讀不到」
  是兩件事，一個要重選日期、一個要去開權限/裝 APK）；檔案匯入改回傳 `ImportFailure`。
  字串集中在 `lib/utils/sync_reason.dart` 的 label 擴充（跟 `PermissionFailure` 同一個模式），
  UI 與背景 isolate 都走它 → 英文介面不會再混出中文，例外堆疊也不會再跑進 SnackBar。
- **about 頁**：`localizations?.x ?? '英文'` 這種「缺字串就靜靜顯示英文」的慣例全部拔掉
  （setup / notification_setup / about 三頁都改成 `AppLocalizations.of(context)!`）；
  文案改成事實 —— 本來寫「追蹤步數與其他健康數據」、「支援 Health Connect 與 HealthKit」，
  但本 app 現在只讀步數、iOS 也沒有實作。

### 還留著的（不是 bug，是要人做的事）
- **About 頁的聯絡信箱是假信箱** `support@dhealth.app`：上架前一定要換成真的（Play 審查會看）。
- release 簽名仍是 debug key；CI 的 codecov action 沒帶 token；尚無 `dataExtractionRules`。
- 真機驗收單（上面第 1 節）一項都還沒跑過；本機沒有 JDK 17+（只有 1.8），`flutter build apk`
  在這裡跑不了，manifest/Kotlin/WorkManager/通知這一路只有 CI 會幫我們驗。
- `charts.dart` 651 行、`import_export.dart` 457 行：要拆就拆，但那是純搬家，等有實作需求再說。

---

## 2026-11-06 本輪已做（第二輪：上架前全項目重審）

原则：只把「會銷毁資料 / 骗使用者」的路徑改掉，不換架構。重點是**同步流程改成「先讀到、再刪寫」**，
讀取失敗一律不刪資料庫（舊版是先 delete 再 read，Health Connect 一晃眼那個區間的資料就永久消失）。

- **刪掉會寫假資料的入口**：`lib/data.dart`（Add Data 按鈕寫入隨機血糖/心率等假健康資料）、
  `lib/util.dart`、`lib/appstate.dart`、`lib/database/exporter.dart`（死碼，且參考的是錯的 DB 檔名）、
  `lib/services/health_service.dart`。主畫面現在是我們的首頁，不是 health 套件的範例 app。
- **匯入／匯出全部回傳真正的結果**（`StepSyncResult`／`ImportResult`），UI 照實顯示成敗；
  之前 4 條路有 3 條是 `//TODO` 空殼卻彈「success」。
- **`getQ1` 的 `999` sentinel 拿掉**（它跟 `dailyStepGoal` 預設 300 比就會彈「Goal Reached」），
  成功的步數讀取也不再走 `showErrorNotification("debug for steps:...")`。
- **排程/目標等 prefs  key 全部集中到 `lib/settings_keys.dart`**（同一把 key 以前散落各處、
  預設值有四份：6000/300/327/1000），預設值只在 `PrefsDefaults` 定義一次。
- **依賴用 GetIt 註冊**（`lib/di.dart`），背景 isolate 的 `callbackDispatcher` 也補了 `configureDependencies()`
  ——之前那個 isolate 從來沒 register 過，所以背景同步的結果根本沒寫進 DB。
- **權限收收**：manifest 從 33 種 READ_WRITE + Location 改成只 `READ_STEPS`（+ 需要 30 天以上時的
  `READ_HEALTH_DATA_HISTORY`）；`PermissionService.authorize()` 不再永遠回 true（之前所有 `return false`
  都被註解掉了），必要權限失敗會回 `PermissionFailure` 讓 UI 顯示橫幅。
- **`main()` 不再在 `runApp()` 之前同步跑 `BackgroundService.executeTask()`**（冷啟動卡在那條平台上），
  設定與依賴先 `await` 完成再進首頁（首幀不再跳一下）。
- **圖表**：`charts.dart` 1018 → 651 行（删掉整個没人用的 `Chart2` 家族）；`FutureBuilder` 放在 build 裡
  造成的閃爍改成 `refreshToken` 重取；小時長條的分配邏輯移到 `StepCalculator.hourlyDistribution`（有測試）。
- **release 的可觀察性**：新增 `lib/utils/log.dart`（`appLog`/`appError`），之前唯一的 log 管道是
  被关掉的 `debugPrint`，出事時什麼都看不到。
- `main.dart` 826 → 294 行（約 173 行的註解死碼與舊 DB 開法全删）。
- **測試 43 → 62**（第三輪又拿掉 2 條測已刪除設定的測試）：新增同步安全回歸（讀取失敗不得刪資料、0 步是正當結果、刪除不得超過結束日、
  `getLastDate` 空库回 null 而不是 now-7d）、`decideStepAlert` 纯函式、hourlyDistribution、
  週首日改成由呼叫端交給 `MaterialLocalizations`（之前是 `Intl.getCurrentLocale()` 恆為 'en_US' 的假判斷）。

---

## 待辦（按優先序）

### 1. 真機 Android 13 驗收單（minSdk 33 之後必跑，目前一項都沒驗過）
1. Android 13 裝得上（`apks.zip` 解出來的 `app-release.apk`，別把 zip 直接拿去裝）
2. 「Check Health Connect Status」應顯示 **不可用**（13 上 Health Connect 不是系統元件）
3. 按「Install Health Connect」要跳到 Play Store 的那個 APK（`lib/main.dart:160` `_installHealthConnect`）
4. 裝好 Health Connect 後：授權流程 → 讀到今日步數 → 與 Health Connect 顯示一致
5. 背景排程：殺 app 後 `Workmanager` 的 `stepTrackerTask` 還跑不跑、有没有寫進 DB；重開機後會不會自己回來
6. 被電池最佳化後是否失靈（`REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` / 精確鬧鐘 `USE_EXACT_ALARM` 要不要白名單）
7. 三種通知真的弹出來：Goal Reached / Almost There / Error（`notification_service.dart:95-110`）；
   同時驗節流與通知時段：同類之間至少隔 `frequencyMinutes`、且只在 startHour–endHour 視窗内發
   （`NotificationService.allowSending`，`notification_service.dart:76`；決策本身是
   `decideStepAlert`，已有測試）
8. 切中文介面看 `endTimeError`／`selectStartTime`／`selectEndTime` 還有沒有英文
9. 匯出／分享 DB 可用（`allowBackup="false"` 之後，匯出是唯一的備份路）
10. 資料持久化：寫一筆 → 殺 app 重開還在
> 沒有 Google Play services 的機型（國內常見 ROM）讀不到步數，這是平台限制，不是 bug。

### 2. 兩個超大檔案該拆
- `lib/widgets/charts.dart` 651 行單檔 → 圖表元件按類型拆（現況：4 個圖表類別同一檔，但已無死碼）
- `lib/widgets/import_export.dart` 457 行 → 匯入/匯出/分享三塊可分

### 3. 測試覆蓋的洞
現在有：`database`、`data_service`（含同步安全回歸）、`step_calculator`、`weekday_utils`、
`settings_model`、`decideStepAlert`（通知決策的纯邏輯）。
完全沒有：**`Workmanager` 排程本身、`notification_service`（频道建立/節流）、`permission_service`、
`charts` 的取數路徑**。真要进一步補，先補 `permission_service`（它是唯一還沒被測過的入口邏輯）。

### 4. 一致性 / 上架前
- l10n 取字串慣例：本案到处是 `AppLocalizations.of(context)?.xxx ?? '英文 fallback'`，
  缺字串時會**靜靜顯示英文**（上批中文缺字串就是被它掩蓋掉的）。建議統一成 dNeko 那套
  `AppLocalizations.of(context)!`，讓缺字串在開發期就爆出來。
- release 簽名仍是 debug key（`android/app/build.gradle.kts` 的 `signingConfig`）。- CI 的 `codecov/codecov-action@v4` 沒帶 token：public repo 沒事，**轉 private 會紅**。
- 尚無 `dataExtractionRules`（`allowBackup="false"` 已設，健康資料已不进雲備份；
  要上架就得把 Play 的資料安全聲明對上實際行為）。

## 2026-11-09 待辦：遷移到 Flutter Built-in Kotlin（三案共同，先拿 d2048 試）

每次 build 都噴 `applies the Kotlin Gradle Plugin, which will cause build failures in future versions
of Flutter`（guide：docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin）。
現在靠 `android/gradle.properties` 的 `android.builtInKotlin=false`／`android.newDsl=false`
（Flutter migrator 自動加的）壓住，還跑得動；等它變成 error 就會被卡死在不能升 Flutter 版，到時是被動改。

細節與步驟方向写在 **`../d2048/TODO.md`**（同一時間寫的同一件事）。【2026-11-09 現況】**本案短期升不了**：有 7 個上游插件還在自己的 `android/build.gradle(.kts)` 裡套 KGP（`android_file_picker`、`device_info_plus`、`share_plus`、`package_info_plus`、`health`、`shared_preferences_android`、`workmanager_android`），而且這幾個我們鎖的都是 pub.dev 最新版，沒有「升一下就好」的路；上游 main 只有 `shared_preferences_android` 已改好待發版。別排程，定期重查即可。查證方式與 dNeko 那 1 個 blocker 的取捨見 `../dNeko/TODO.md`。

**d2048 已於 2026-11-09 試通**（AGP 9.1.0；用 init script 實測 `:app` 的 `pluginManager.hasPlugin("org.jetbrains.kotlin.android")` 由 true 變 false，就真的生效了），可以照抄——
本案有本地 fork 的原生插件／drift／health 等原生依賴，直接動風險高得多。驗收要含一次 release build
（AOT 只能在 x86-64 機器或 CI 驗）。
