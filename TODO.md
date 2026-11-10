# dHealth TODO

慣例：一個待辦一段，寫清「檔案:行」與「為什麼现在是這樣」；**做完就搬到 `CHANGELOG.md`**（`git log` 才是權威）。

---

## 本機建置（aarch64 Linux）— 2026-11-09

**這一節只講 aarch64 Linux 這台主機，別外推成「本專案不能出 release」**：Windows（x86-64）出 release 已實測裝機、
CI 也正常出 artifacts；卡住的只有 Linux/aarch64 —— AOT 的 `gen_snapshot`，Google 的 engine bucket 裡
**沒有 linux-arm64 host 版**（`android-arm64-release/artifacts.zip` 只有 flutter.jar），qemu 模擬 x86-64 那條
也試過行不通。所以在 aarch64 Linux 上日常就只出 **debug**：
`flutter build apk --debug --target-platform android-arm64`。
主機環境（`JAVA_HOME`／`ANDROID_HOME`、實測 APK 大小、NDK `llvm-strip` 殼）記在 `~/dennys/AGENTS.md`。

- **本機专用的依賴釘選放 `pubspec_overrides.yaml`（已 gitignore → CI／正式版零影響）**：
  `path_provider_android: 2.2.23`、`shared_preferences_android: 2.4.8`。原因：11-08 `d9bcde6`
  全數升級後這兩支會拉 `jni`（有 `CMakeLists.txt`）→ 觸發 CMake+NDK 原生編譯，而 aarch64 主機的 SDK
  cmake 與 NDK 的 clang 都是 x86-64 檔（`Syntax error: ")" unexpected`）→ `:jni:configureCMakeDebug` 必敗。
  舊版不需原生編譯、pub-cache 也已有 → 零下載。
- 副作用：`pub get` 會把 `pubspec.lock` 與 `linux|windows/flutter/generated_plugins.cmake` 改髒
  （本地 overrides 的固有行為）。**build 完請 `git checkout` 這三支**，別 commit 進去 ——
  那等於把 11-08 的升級在 repo 層回退，CI 也會跟著用舊 plugin。
- `android/gradlew` 與 `gradle/wrapper/gradle-wrapper.jar` 不在版控**不是 bug**：flutter 會從
  `bin/cache/artifacts/gradle_wrapper` 自動注入。真正決定跑哪版 Gradle 的是有被追蹤的
  `android/gradle/wrapper/gradle-wrapper.properties`（現行 pin 9.3.1，實測 `./gradlew --version` = Gradle 9.3.1）。

---

## 待辦（按優先序）

### 1. 真機驗收單 → 已搬到 **`../DEVICE_TEST.md`**（跨 dHealth／dNeko 一份）

**至今仍是零**，尤其這兩組：
- **B-1 背景排程**：殺 app 後 `stepTrackerTask` 還跑不跑、有沒有寫進 DB、重開機後會不會自己回來。
  「不會自己回來」是**實作缺口**（要嘛靠 `BOOT_COMPLETED`，要嘛明確接受「重開機後要開一次 app」），
  不是「ROM 壞」，驗之前別先假設是對方的問題。
- **B-2 通知**：三種通知真的彈出來 + 節流（同類之間至少隔 `frequencyMinutes`）+ 只在時段視窗內
  （含跨午夜那一支）。決策的純邏輯已有測試，但「真的彈出來」只有真機看得見。

人類 2026-11-09 口頭回報「Android 13 裝得上、含 overlay 等都正常」，但沒有逐項記錄，
所以單裡其餘項目（Health Connect 狀態/安裝、授權讀步數、中文缺字串、匯出可用、資料持久化）
也留在單裡同場再掃一次就好，成本很低。本輪新增的**分批併發同步**與**備份過期提醒**的
驗收步驟（含匯出前後應該看到什麼）也寫在同一份。

### 2. 兩個超大檔案該拆
- `lib/widgets/charts.dart` 651 行單檔 → 圖表元件按類型拆（現況：4 個圖表類別同一檔，但已無死碼）
- `lib/widgets/import_export.dart` 457 行 → 匯入/匯出/分享三塊可分

### 3. 測試覆蓋的洞
現在有：`database`、`data_service`（同步安全回歸 + **同步 serialize** + **小時曲線的容忍行為**）、
`step_calculator`（含 0 步天/週/月補零）、`settings_model`、`decideStepAlert`、`chart_range`（incl. the month-page day clamp）、
**`notification_service`（時段視窗含跨午夜、節流、判斷不燒節流槽）**、**備份提醒的天數算法**、
**`background_service`（executeTask 全分支 + 備份提醒天級節流）**、**`permission_service`**（關鍵權限失敗必回
PermissionFailure）、**`importStepsFromFile`**（成敗六條路，DB 已注入）。
新增的斷言都做過變異檢查（把舊行為塞回去會紅），不是怎麼跑都過的假測試。

完全沒有：**`Workmanager` 排程本身**、`charts` 的取數路徑（widget 層）。
- **`openStepDatabase` recovery path** (a corrupt file -> `.corrupt` + fresh db): untestable today because the path is hard-wired to path_provider; inject the path if you want a test.

### 4. 一致性 / 上架前
- l10n 取字串慣例：本案到处是 `AppLocalizations.of(context)?.xxx ?? '英文 fallback'`，
  缺字串時會**靜靜顯示英文**（上批中文缺字串就是被它掩蓋掉的）。建議統一成 dNeko 那套
  `AppLocalizations.of(context)!`，讓缺字串在開發期就爆出來。
- release 簽名仍是 debug key（`android/app/build.gradle.kts` 的 `signingConfig`）。
- 尚無 `dataExtractionRules`（`allowBackup="false"` 已設，健康資料已不进雲備份；
  要上架就得把 Play 的資料安全聲明對上實際行為）。

## 2026-11-09 審查後仍開著的（代碼面；已做的都進 CHANGELOG 了）

### 1. 聚合 API 還沒用（M1 剩下的那一半）
現在是「分批併發的逐小時」（一批 6 個）。真正一次拿回全天逐小時桶的是
`getHealthAggregateDataFromTypes(..., activitySegmentDuration: Duration(hours: 1))`
—— 注意審查報告写的 `getTotalStepsInInterval(..., HealthIntervalArgument(timeUnitPolicy:))`
**在 health 13.3.2 並不存在**（實查 pub-cache：`health_plugin.dart:1248` 只有兩個位置參數）。
換過去之前要在真機確認回傳的時間桶邊界與時區，否則可能把「整天讀不到」换成「整天錯位」；
驗收見 `../DEVICE_TEST.md` B-4（前後各測一輪冷啟動/下拉刷新/匯入 365 天）。

### 2. 通知 channel 只在啟動時建（M4）
聲音／震動／重要性屬於 channel 層，Android 會快取，所以設定的開關要重啟才生效。
代碼註解講了，**UI 沒講** —— 使用者會以為關掉就安靜了。補法二選一：三個 setter 去
`createNotificationChannel()` 更新既有 channel，或在 subtitle 寫「重啟後生效」
（要一個新的 l10n 字串）。真機 B-2e 就是驗這個。

### 3. `setup.dart` Active Hours 只取小時（L3）
- Active Hours 用 TimePicker 但只取 `.hour`，分鐘悄悄丟棄（選 7:30 變 7:00）。
  改成「小時下拉 ×2」講清楚，或乾脆把設定做成分鐘解析度。

### 4. 節流時間戳的裸字串 key（L6）
`notification_service.dart` 用 `'notification_last_sent_' + kind` 直接寫 prefs，繞過
`settings_keys.dart` 的「全案唯一定義」慣例。收進 `Prefs` 就好（鍵名不変，不動既有安裝）。

---

## 2026-11-09 待辦：遷移到 Flutter Built-in Kotlin（三案共同，先拿 d2048 試）

每次 build 都噴 `applies the Kotlin Gradle Plugin, which will cause build failures in future versions
of Flutter`（guide：docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin）。
現在靠 `android/gradle.properties` 的 `android.builtInKotlin=false`／`android.newDsl=false`
（Flutter migrator 自動加的）壓住，還跑得動；等它變成 error 就會被卡死在不能升 Flutter 版，到時是被動改。

細節與步驟方向写在 **`../d2048/TODO.md`**（同一時間寫的同一件事）。【2026-11-09 現況】**本案短期升不了**：有 7 個上游插件還在自己的 `android/build.gradle(.kts)` 裡套 KGP（`android_file_picker`、`device_info_plus`、`share_plus`、`package_info_plus`、`health`、`shared_preferences_android`、`workmanager_android`），而且這幾個我們鎖的都是 pub.dev 最新版，沒有「升一下就好」的路；上游 main 只有 `shared_preferences_android` 已改好待發版。別排程，定期重查即可。查證方式與 dNeko 那 1 個 blocker 的取捨見 `../dNeko/TODO.md`。

**d2048 已於 2026-11-09 試通**（AGP 9.1.0；用 init script 實測 `:app` 的 `pluginManager.hasPlugin("org.jetbrains.kotlin.android")` 由 true 變 false，就真的生效了），可以照抄——
本案有本地 fork 的原生插件／drift／health 等原生依賴，直接動風險高得多。驗收要含一次 release build
（AOT 只能在 x86-64 機器或 CI 驗）。


## 零碎備忘（2026-11-09 整理，不是 bug，看到了再說）

- **上架前必填**：`lib/widgets/about.dart` 的 `kSupportEmail`（沒填 About 頁就不顯示聯絡信箱，
  故意不放假信箱）；Play 控制台要填同一個。
- **CI 簽章**：`KEYSTORE_B64` / `KEY_PROPERTIES` 要確認有設 —— 沒設時 workflow 直接
  `::error::` + `exit 1`（2026-11-10 REVIEW 輪改的；以前是 `::warning::` 後靜默用 debug 簽章，
  那種 APK 每版簽名不同，只能砍掉重裝）。
- **`android.newDsl`** 仍未翻（AGP 舊 DSL 型別），不要跟 `android.builtInKotlin` 同時動。
- 本機（aarch64 Linux）**已經能 build debug**：環境與 `pubspec_overrides.yaml` 見上面「本機建置」節（主機細節在 `~/dennys/AGENTS.md`）；
  CHANGELOG 裡舊輪次寫的「本機只有 JDK 8、build 不了 apk」是當時的狀態，已過時。
