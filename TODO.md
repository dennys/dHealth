# dHealth TODO

慣例：一個待辦一段，寫清「檔案:行」與「為什麼现在是這樣」；**做完就搬到 `CHANGELOG.md`**（`git log` 才是權威）。

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


## 零碎備忘（2026-11-09 整理，不是 bug，看到了再說）

- **上架前必填**：`lib/widgets/about.dart` 的 `kSupportEmail`（沒填 About 頁就不顯示聯絡信箱，
  故意不放假信箱）；Play 控制台要填同一個。
- **CI 簽章**：`KEYSTORE_B64` / `KEY_PROPERTIES` 要確認有設 —— 沒設時 workflow 會 `::warning::`
  然後**靜默用 debug 簽章**（fork 友善的設計），那種 APK 每版簽名不同，只能砍掉重裝。
- **CI 覆蓋率**：codecov action 沒帶 token。
- **`android.newDsl`** 仍未翻（AGP 舊 DSL 型別），不要跟 `android.builtInKotlin` 同時動。
- 本機（dgx1）**已經能 build debug**：`JAVA_HOME=~/jdk21` + `pubspec_overrides.yaml`（見上面「本機建置」節）；
  CHANGELOG 裡舊輪次寫的「本機只有 JDK 8、build 不了 apk」是當時的狀態，已過時。
