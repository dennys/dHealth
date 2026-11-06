# dHealth TODO

慣例：一個待辦一段，寫清「檔案:行」與「為什麼现在是這樣」，做完就刪掉這條。

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

## 待辦（按優先序）

### 1. 真機 Android 13 驗收單（minSdk 33 之後必跑，目前一項都沒驗過）
1. Android 13 裝得上（`apks.zip` 解出來的 `app-release.apk`，別把 zip 直接拿去裝）
2. 「Check Health Connect Status」應顯示 **不可用**（13 上 Health Connect 不是系統元件）
3. 按「Install Health Connect」要跳到 Play Store 的那個 APK（`lib/main.dart:454` 那條分支）
4. 裝好 Health Connect 後：授權流程 → 讀到今日步數 → 與 Health Connect 顯示一致
5. 背景排程：殺 app 後 `Workmanager` 的 `stepTrackerTask` 還跑不跑、有没有寫進 DB；重開機後會不會自己回來
6. 被電池最佳化後是否失靈（`REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` / 精確鬧鐘 `USE_EXACT_ALARM` 要不要白名單）
7. 四種通知真的彈出來：Goal Reached / Almost There / Error / Headless Mode（`notification_service.dart:50-90`）
8. 切中文介面看 `endTimeError`／`selectStartTime`／`selectEndTime` 還有沒有英文
9. 匯出／分享 DB 可用（`allowBackup="false"` 之後，匯出是唯一的備份路）
10. 資料持久化：寫一筆 → 殺 app 重開還在
> 沒有 Google Play services 的機型（國內常見 ROM）讀不到步數，這是平台限制，不是 bug。

### 2. 「每日目標」有 4 個來源，改一處漏三處
- `lib/settings_model.dart` 預設 `6000`
- `lib/services/background_service.dart:49` 預設 `300`
- `lib/services/background_service.dart:80` 預設 `327`
- `lib/services/background_service.dart:89` 的 magic `1000`（「差 1000 步就鼓勵」）
→ 統一成一個常數檔或一律從 `SettingsModel`/prefs 單一读取來源。

### 3. `SettingsModel` 兩處結構問題
- `SettingsModel()` ctor 裡 `_loadPreferences()` 沒 await（`settings_model.dart:78`）
  → 首幀用預設值，設定頁會「先跳一下」。改成 `Future<void> load()` 由 app 啟動時 await，
  或保留但要等它完成後再進入首頁。
- setter 完全沒有範圍驗證（`setSyncFrequency`、`setDailyStepGoal`、`setMotivationTimeLimit`
  都接受任何 int）；UI 靠 dropdown 限制，但髒的 prefs 值會直通 Workmanager 間隔。

### 4. 兩個超大檔案該拆
- `lib/main.dart` 826 行（其中約 173 行是純註解死碼，含整個被註解掉的 `showDialog` 區塊與
  舊 DB 開法 `:171/:174/:243`）→ 首頁、選單、圖表列表分檔，死碼直接刪（git 有紀錄）
- `lib/widgets/charts.dart` 1018 行單檔 → 圖表元件按類型拆

### 5. 測試覆蓋的洞
現在有：`database`、`data_service`、`step_calculator`、`weekday_utils`、`settings_model`。
完全沒有：**`background_service`（排程與區間聚合）、`notification_service`、`permission_service`、
`health_service`、`charts` 的取數路徑**。真要補，先補 `background_service` 的區間聚合（純邏輯、最容易測）。

### 6. 一致性 / 上架前
- l10n 取字串慣例：本案到处是 `AppLocalizations.of(context)?.xxx ?? '英文 fallback'`，
  缺字串時會**靜靜顯示英文**（上批中文缺字串就是被它掩蓋掉的）。建議統一成 dNeko 那套
  `AppLocalizations.of(context)!`，讓缺字串在開發期就爆出來。
- release 簽名仍是 debug key（`android/app/build.gradle.kts` 的 `signingConfig`）。
- CI 的 `codecov/codecov-action@v4` 沒帶 token：public repo 沒事，**轉 private 會紅**。
- 尚無 `dataExtractionRules`（`allowBackup="false"` 已設，健康資料已不进雲備份；
  要上架就得把 Play 的資料安全聲明對上實際行為）。
