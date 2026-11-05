# dHealth

[![GitHub Actions](https://github.com/dennys/dhealth/actions/workflows/github_action.yaml/badge.svg)](https://github.com/dennys/dHealth/actions/workflows/github_action.yaml)
[![codecov](https://codecov.io/gh/dennys/dHealth/graph/badge.svg?token=IGNEDCQ0g2)](https://codecov.io/gh/dennys/dHealth)
![GitHub Repo stars](https://img.shields.io/github/stars/:dennys/:dstep)

Just another Health App.

# Features

# Requirement

- [Health Connect](https://play.google.com/store/apps/details?id=com.google.android.apps.healthdata): because I use [Health](https://pub.dev/packages/health) package and it's based on Health Connect
- Android 9.0 (API 28) or above, because `Health Connect` only support Android 9.0 or above.
- But if you use Anrdoid 14 (API Level 35, ), Health Connect app is build-in.

# Permission (Android)

1. In `AndroidManifest.xml`, these permission are required.

   ```xml
   <uses-permission android:name="android.permission.ACTIVITY_RECOGNITION" />
   <uses-permission android:name="android.permission.health.READ_STEPS" />
   <uses-permission android:name="android.permission.health.WRITE_STEPS" />
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

- Android: I only enable `arm64-v8a`, if you need `armeabi-v7a`, please include it in build.gradle.kts.
- iOS: this app is built by Flutter, it works theoretically, but still need to implement iOS dependent code and test. For example, how to get health data and import/export data are platform dependent.

# iOS

App widget
Notification

# ToDo

- data.dart 的 setState() 被 comment, 要再補回. 裡面也有重複的 code

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
