# dHealth 專案檢視報告

日期:2026-11-08(程式碼基準 ≈ commit `8ccfde3`)。
方式:通讀 `lib/`(除 generated)＋ `test/` ＋ CI/gradle 設定。**只檢視,不改進任何程式碼。**
與 `TODO.md` 重複的舊待辦不重列;真機驗收單、拆檔等已在 TODO.md 的項目只在附錄提一句。

---

## 一、潛在問題

### 高

| # | 位置 | 問題 | 建議 |
|---|------|------|------|
| H1 | `lib/data.dart`、`lib/util.dart`、`lib/services/health_service.dart`、`lib/database/exporter.dart` 全檔 | **死碼四件套還在 repo**,但 TODO.md(第二輪)宣稱已刪除。全是 health 套件範例殘留:`data.dart` 會寫入隨機血糖/心率/經期等**假健康資料**;`health_service.dart` 請求 **Location 權限**(違反本專案「只讀步數」原則)且 `hasPermissions = false` 硬覆蓋;`exporter.dart` 最危險——`await database.close()` 關掉 **GetIt 裡活著的連線**,`finally` 呼叫 `openStepDatabase()` 卻把新連線**丟掉不重新註冊**(匯出一次整個 app 拿著已關閉的 DB),且參考不存在的 `steps_database.sqlite`、method channel 是 `com.example.app/*`。目前四檔 0 個呼叫者,純屬地雷 | 刪除四個檔案(死碼直接刪,git 會記住) |
| H2 | `lib/widgets/notification_setup.dart:44-52` | `DropdownButton<int>(value: settings.notificationFrequency)`:選「自訂」存了非預設值(如 45)後,45 不在 `items` 裡 → debug 模式 **DropdownButton assertion 直接炸**,release 顯示空白、看不到目前值。同專案 `setup.dart:149-153` 已經有正確寫法(value 不在清單時傳 null + hint),這頁漏了 | 比照 setup.dart 的 hint 寫法;順帶 `motivationTimeLimit` 的 dropdown 也補上同款防護 |

### 中

| # | 位置 | 問題 | 建議 |
|------|------|------|------|
| M1 | `lib/services/data_service.dart:165-171` | 小時曲線**逐小時串行呼叫 Health Connect**(最多 24 次 IPC),而進場、下拉刷新、從子頁面返回(`main.dart _open`)都會觸發 → 冷啟動明顯變慢;且任何一個小時回 null 就 `throw`,整天曲線降級成「讀不到」(`:169`),一個小時的抖動犧牲 23 個小時的資料 | 用 `getTotalStepsInInterval(from, to, HealthIntervalArgument(timeUnitPolicy: TimeUnit.hour))` 一次拿回全天;單小時失敗改成該小時填 0 或補插一次,別丟整天 |
| M2 | `lib/services/data_service.dart:48-53` | `_fetchDailySteps` 逐日串行 IPC:首次同步 31 天=31 次、匯入 365 天=365 次( chunk 只分組、沒減少呼叫)。Health Connect 慢的機器上匯入一年會非常久 | 保留逐日语意,但用 `Future.wait` 分組併發(Health Connect 可承受少量並行),或至少把 hourly+daily 兩條路共用一套節流 |
| M3 | `lib/services/background_service.dart` 與 `main.dart _sync` | 手動/下拉同步與 WorkManager 背景同步可能**同時跑**:`_syncing` 只擋 UI 自己。雨者各自 transaction(先刪段再寫入),交錯時理論上可能出現半套狀態(同源資料,機率與傷害都低,但存在) | StepDataService 加一把簡單互斥鎖(一個 `Completer`/`synchronized`),同步全程 serialize |
| M4 | `lib/services/notification_service.dart:41-69` | 音訊/震動/重要性的 channel 只在**啟動時**建一次;設定頁的開關看起來即時生效,實際要重啟才生效(平台限制,已註解,但 UI 沒說) | 在三個 setter 觸發 `createNotificationChannel()` 更新既有 channel,或在 subtitle 寫「重啟後生效」 |
| M5 | `lib/database/database.dart:30` | `schemaVersion=1` 且無 `migration` 策略。下次改 schema(加欄位)時,老使用者升級直接例外崩潰 | 現在就把 `MigrationStrategy`(onUpgrade + `ALTER TABLE`)的骨架放好,哪怕目前是空的 |
| M6 | `lib/widgets/import_export.dart:252-258` | 「最近 N 天」輸入框無上限驗證:9999 = 9999 次串行 IPC(見 M2),0/負數要靠下游 invalidRange 報錯兜底 | `onChanged` 夾到 1..3650,或驗證器直接擋 |
| M7 | `test/` 缺口 | `permission_service`、`notification_service`(`NotificationWindow.contains` 跨午夜、`canSend` 節流)、`BackgroundService.executeTask`、`importStepsFromFile` 完全沒測。其中 window/節流是**純邏輯**,最便宜的高價值補測點 | 優先補 `NotificationWindow`+`canSend`(純函數級),再 `executeTask`(用 mocks,已有 mockito) |

### 低

| # | 位置 | 問題 | 建議 |
|----|------|------|------|
| L1 | `lib/database/database.dart:78-142` | `getStepsMap`/`getDailyAverageSteps`/`getAllWeeklySteps`/`getAllMonthlySteps` 零外部呼叫(圖表全部走 `StepCalculator`)。且 `:98` 註解引用不存在的 `WeekdayUtils` | 刪除;要留 CSV/報表功能時再寫 |
| L2 | `lib/widgets/setup.dart:252-253` | 每次 build 現做 `TextEditingController`(游標/IME 狀態脆),目標輸入框輸入感偶發不順 | 收進 State 持有 controller,`didUpdateWidget` 同步外部值 |
| L3 | `lib/widgets/setup.dart:284-336` | Active Hours 用 TimePicker 但只取 `.hour`,分鐘悄悄丟棄(選 7:30 變 7:00) | 改「小時下拉×2」,或乾脆把設定做成分鐘解析度 |
| L4 | `lib/widgets/notification_setup.dart:47` | 頻率選項有「5 分鐘」,但背景一律 `clamp(15, …)`(`background_service.dart:202`)→ 5 分鐘是選項謊言 | 移除 5,或在 UI 標「最低 15(系統限制)」 |
| L5 | `lib/database/util.dart:96` | CSV 的 `LastUpdated` 用當地時間 ISO 但**無時區suffix**,跨機還原無礙、匯出給別人看會曖昧 | 改 `toUtc().toIso8601String()` |
| L6 | `lib/services/notification_service.dart:39,85` | 節流時間戳用裸字串 key `notification_last_sent_*` 寫 prefs,繞過 `settings_keys.dart` 的「全案唯一定義」慣例 | 收進 `Prefs` |
| L7 | `lib/settings_keys.dart:58` | 註解還寫「預設最近 7 天」,期數制後應是「最近 7 期」;`charts.dart:14` 的檔案備忘行數也過時 | 順手改註解 |
| L8 | `lib/widgets/import_export.dart:98` | `onProgress: (p) => {if (mounted) setState(...)}` 用 Set 字面量當 lambda 回傳,湊巧能動但易誤讀 | 改成 `(p) { if (mounted) setState(...); }` |
| L9 | `lib/widgets/about.dart:10` | `kSupportEmail = null`(上架前要填)——機制正確(寧可不顯示),記得上架清單 | 上架前處理 |
| L10 | `lib/main.dart:52` | `DrawerThemeData(backgroundColor: Colors.green[50])`:暗色模式下 drawer 若走 `theme`(亮色)分支會被 seed 暗色覆蓋?——實測 `darkTheme` 有建才沒事;這裡写死亮色綠對 `theme` 而言 OK,但**亮色模式 drawer 上的文字對比**沒走 colorScheme,低頭檢 | 改用 `surfaceContainerLow` 之類 colorScheme 色 |

---

## 二、可加的功能(按「CP 值 / 與現有架構的贴合度」排序)

### 低成本、純本地資料就能做
1. **連續達標 streak**:日誌頁/首頁顯示「連續 N 天達標」;`isComplete` 欄位已在,DB 掃描即可。
2. **tap bar → 歷史当日的小時曲線**:點日圖任何一根,把首頁小時圖切到那一天(`getTotalStepsInInterval` 本来就能查過去日期),比現在只能看「今天」實用得多。
3. **同weekday 對比/移動平均線**:日圖加一條「近 28 天同週日平均」虛線,fl_chart 加一條 line 就夠。
4. **匯入提醒**:超過 N 天沒匯出 → 通知「備份可能過期」(`allowBackup=false` 下這是唯一備份路,現在完全沒提醒)。
5. **CSV 匯入**:目前只能回還 sqlite 檔;CSV 是人們實際會留著的格式(`exportStepsToCsv` 的逆函數,欄位已定)。

### 中等
6. **主畫面桌面 widget**(步數+目標環):`home_widget` 或 Glance;健康類 app 的標配,也能順帶拉高「非同步时段看到新數字」的體感。
7. **每日定時提醒**:「20:00 了還不到 3000 步」— 用現有 WorkManager 排一個當日 one-off 檢查即可,通知三路(`goalReached/almostThere/exception`)之外加第四種。
8. **自適應目標**:目標設為「近 14 天日均 ×1.1」可選開關(純 `StepCalculator` 邏輯,好測)。
9. **app 內自診頁 + log 匯出**:`appError` 現在只能 logcat;加一個 in-memory ring buffer,About 頁加「最近錯誤/最後同步時間/下次排程/Health Connect 狀態」+ 一鍵附 log 回報。對只有 CI 沒有後端的專案,這是唯一的支持管道。
10. **日曆視圖**:月曆上每格顯示步數+顏色深淺(現有 `_getStepBasedColor` 直接 reuse),補「翻頁找某天」的空白。

### 大工程(先想清楚要不要)
11. **iOS/HealthKit**:health 套件已支援,但權限流程、通知(workmanager 換、drift 路徑)、UI 適配全是活;README 自己也標了 theoretical。
12. **多資料類型**(距離/-active energy/睡眠):會連動權限範圍、同步管線(現在是 steps 專用的單一寫入路徑)、圖表資料模型——違反目前「只做步數、做深不做大」的定位,建議 YAGNI,除非有真實需求。
13. **PIN/生物辨識鎖**:健康資料敏感性配上「借手機」場景有意義;`local_auth` 半天工作量。

### 順帶一提(已在 TODO.md,不重複展開)
真機 Android 13 驗收單、charts/import_export 拆檔、`AppLocalizations.of(context)!` 慣例統一。

---

## 三、結論

經過前幾輪清洗,這個 codebase 的「會吃資料/騙使用者」路徑已經封得不錯(同步先讀後寫、transaction、節流、GetIt 雙 isolate 都修過)。**目前真正的火警只剩 H1(死碼四件套,尤其是 export 關連線那顆)和 H2(通知頁 dropdown assertion)**;其餘是性能體感(M1/M2)與升級防呆(M5)。功能面最便宜的好貨是 streak、歷史小時曲線、和匯出提醒三個——全部不需要新權限、新依賴。
