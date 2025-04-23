# dHealth

[![Build](https://github.com/dennys/dsteps/actions/workflows/github_action.yaml/badge.svg)](https://github.com/dennys/dHealth/actions/workflows/github_action.yaml)
[![codecov](https://codecov.io/gh/dennys/dHealth/graph/badge.svg?token=IGNEDCQ0g2)](https://codecov.io/gh/dennys/dHealth)
![GitHub Repo stars](https://img.shields.io/github/stars/:dennys/:dstep)

Commit:
![GitHub last commit](https://img.shields.io/github/last-commit/dennys/hMoney)
![GitHub commit activity](https://img.shields.io/github/commit-activity/w/dennys/hMoney)
![GitHub commit activity](https://img.shields.io/github/commit-activity/m/dennys/hMoney)
![GitHub commit activity](https://img.shields.io/github/commit-activity/y/dennys/hMoney)

GitHub (Size):
![Lines of code](https://img.shields.io/tokei/lines/github/dennys/hMoney)
![GitHub code size in bytes](https://img.shields.io/github/languages/code-size/dennys/hMoney)
![GitHub repo size](https://img.shields.io/github/repo-size/dennys/hMoney)
![GitHub repo file count](https://img.shields.io/github/directory-file-count/dennys/hMoney)

Code scan:
[![Maintainability](https://api.codeclimate.com/v1/badges/9263841b69330e2a91d5/maintainability)](https://codeclimate.com/github/dennys/hMoney/maintainability)
[![Codacy Badge](https://api.codacy.com/project/badge/Grade/9654ae0d5f024ba7b49233e72b4b0685)](https://app.codacy.com/gh/dennys/hMoney?utm_source=github.com&utm_medium=referral&utm_content=dennys/hMoney&utm_campaign=Badge_Grade_Settings)
[![CodeQL](https://github.com/dennys/hMoney/actions/workflows/codeql-analysis.yml/badge.svg)](https://github.com/dennys/hMoney/actions/workflows/codeql-analysis.yml)

Android:
![Android](https://img.shields.io/badge/Android-API%2033-green?logo=android)
![Flutter](https://img.shields.io/badge/Flutter-3.29.0-blue?logo=flutter)
![Material UI](https://img.shields.io/badge/UI-Material%20Design-blueviolet?logo=material-design)

iOS: ![No iOS](https://img.shields.io/badge/iOS-Not%20Supported%20Yet-lightgrey?logo=apple)

Features: 
![Step Tracker](https://img.shields.io/badge/Feature-Step%20Tracking-brightgreen?logo=walkman)
![Fitness App](https://img.shields.io/badge/Fitness-Step%20Counter-orange?logo=google-fit)


# A Health Project.

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
