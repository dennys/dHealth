# dsteps

[![Flutter CI](https://github.com/dennys/dsteps/actions/workflows/github_action.yaml/badge.svg)](https://github.com/dennys/dHealth/actions/workflows/github_action.yaml)
[![codecov](https://codecov.io/gh/dennys/dHealth/graph/badge.svg?token=IGNEDCQ0g2)](https://codecov.io/gh/dennys/dHealth)
![GitHub Repo stars](https://img.shields.io/github/stars/:dennys/:dstep)

A new Flutter project.

# Requirement

- Android 9.0 (API 28) or above, because [Health Connect app](https://play.google.com/store/apps/details?id=com.google.android.apps.healthdata) only support Android 9.0 or above.
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

1. Code

Permission.activityRecognition.request(): access "體能活動紀錄"
health.requestAuthorization([HealthDataType.STEPS]);: access step data
health.requestHealthDataHistoryAuthorization(): access history data more than 30 days

# Development

1. flutter >=3.27.0
1. Check [document](https://pub.dev/packages/health) and [example app](https://github.com/cph-cachet/flutter-plugins/tree/master/packages/health/example)

# Platform

- Android: I only enable `arm64-v8a`, if you need `armeabi-v7a`, please include it in build.gradle.kts.
- iOS: this app is built by Flutter, it works theoretically, but still need to implement iOS dependent code and test. For example, how to get health data and import/export data are platform dependent.

# VSCode

1. Recommand to enable automatically generation for i18n in `settings.json`

```json
    "dart.flutterGenerateLocalizationsOnSave": "manual",
```

# iOS

App widget
Notification

# ToDo

- Regenerate icons, consider to use flutter_launcher_icons
- data.dart 的 setState() 被 comment, 要再補回. 裡面也有重複的 code
