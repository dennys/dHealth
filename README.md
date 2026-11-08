# dHealth

[![GitHub Actions](https://github.com/dennys/dhealth/actions/workflows/github_action.yaml/badge.svg)](https://github.com/dennys/dHealth/actions/workflows/github_action.yaml)
[![codecov](https://codecov.io/gh/dennys/dHealth/graph/badge.svg?token=IGNEDCQ0g2)](https://codecov.io/gh/dennys/dHealth)
![GitHub Repo stars](https://img.shields.io/github/stars/:dennys/:dstep)

Just another Health App.

# Features

# Requirement

- [Health Connect](https://play.google.com/store/apps/details?id=com.google.android.apps.healthdata): because I use [Health](https://pub.dev/packages/health) package and it's based on Health Connect
- **Android 13 (API 33) or above** —— 這是 `minSdk`，也是目前唯一有真機可測的較舊版本。
  Health Connect 本身的下限是 Android 9（API 28）+ Google Play services：Android 14 以上是
  系統 framework module，13 與以下要從 Play Store 裝 Health Connect APK（主畫面的
  「Install Health Connect」按鈕就是那條路）。要再往下調 `minSdk`，不能低於 28。
- 沒有 Google Play services 的 ROM 讀不到步數，這是平台限制，不是 bug。

# Permission (Android)

0. 權限原則：**只宣告程式碼真的用到的**。本 app 只讀步數，所以是 READ 而不是 READ_WRITE，
   也不要求 Location（計步不需要，Health Connect 也不拿它作條件）。

1. In `AndroidManifest.xml`, these permission are required.

   ```xml
   <uses-permission android:name="android.permission.ACTIVITY_RECOGNITION" />
   <uses-permission android:name="android.permission.health.READ_STEPS" />
   ```

1. Because this app needs to access data more than 30 days, it needs this permission, reference: https://developer.android.com/reference/androidx/health/connect/client/permission/HealthPermission#PERMISSION_READ_HEALTH_DATA_HISTORY()

   ```xml
   <uses-permission android:name="android.permission.health.READ_HEALTH_DATA_HISTORY" />
   ```

1. If you want to see notification, need this permission.

   ```xml
   <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
   ```

# Platform

- Android: only `arm64-v8a`（minSdk 33 的裝置實質上是 arm64 世代）。需要 `armeabi-v7a` 請在
  `android/app/build.gradle.kts` 的 `abiFilters` 加回去。
- iOS: this app is built by Flutter, it works theoretically, but still need to implement iOS dependent code and test. For example, how to get health data and import/export data are platform dependent.

# iOS

App widget
Notification

# ToDo

待辦都移到 [TODO.md](TODO.md)（慣例：一個待辦一段，寫清「檔案:行」與「為什麼现在是這樣」）。

# For Developers

# Development

1. flutter >=3.27.0

## VSCode

1. Recommand to enable automatically generation for i18n in `settings.json`

```json
    "dart.flutterGenerateLocalizationsOnSave": "manual",
```

## How to build drawable png files for notification

1. Convert colored file to black/write file
   1. Upload file to https://www.photopea.com/
   1. Go to Image → Adjustments → Black & White.
   1. Invert if needed (you want a white shape on a transparent background).
   1. Export as PNG.
1. Remove Background
   1. Use https://www.remove.bg

Download file and copy / resize it to `android\app\src\main\res\drawable-\*\*\*hdpi`

## Release signing（APK 簽章）

本 repo 是 public，**簽章檔與密碼一律不進版控**（`android/.gitignore` 已擋 `*.keystore`、
`key.properties`）。機制與 dNeko 相同：

| 位置 | 存放方式 |
|---|---|
| 本地開發 | `android/app/dhealth.keystore` + `android/key.properties`（自行生成，gitignored） |
| GitHub Actions | secrets：`KEYSTORE_B64`（keystore 檔的 base64）、`KEY_PROPERTIES`（key.properties 全文） |
| 兩者都沒有（如 fork） | release 退回 debug 簽章，CI 不會紅 |

`android/key.properties` 格式：

```properties
storeFile=dhealth.keystore
storePassword=<密碼>
keyAlias=dhealth
keyPassword=<密碼>
```

新環境生成 keystore（密碼請換掉）：

```powershell
keytool -genkeypair -keystore android\app\dhealth.keystore -storetype PKCS12 `
  -keyalg RSA -keysize 2048 -validity 10000 -alias dhealth `
  -storepass <密碼> -keypass <密碼> -dname "CN=dHealth, OU=dev, O=denny, L=TP, C=TW"
```

CI 的 `Restore signing key` 步驟會清洗 secret 被判貼帶入的空白/`\r`，再用 `keytool -list`
預檢 keystore 與密碼是否同鑰——不對就一步報錯，不會等 Gradle 三分鐘後才炸
`keystore password was incorrect`。CI 另外產出 `dHealth-release-v<pubspec版本>.apk`。

建置（本地與 CI 相同，只出 arm64，APK 約 22MB；不帶 flag 會把三個 ABI 全塞進去變 61MB）：

```powershell
flutter build apk --release --target-platform android-arm64
```

> ⚠️ 洩密處理：public repo 中只要 keystore 或密碼進過 commit，視為該鑰作廢——
> 重新生成 keystore 並更新 secrets，舊鑰丟棄（歷史 commit 改不掉，洩漏無法回收）。
> 正式上过 Play 的 app 換鑰要走 upload key rotation，所以趁 0.x 就簽對。
