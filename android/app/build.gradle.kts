plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.dennys.dhealth"
    // permission_handler_android 14.1.1（permission_handler 13）要求依赖它的模組用 compileSdk >= 37，
    // 而 flutter.compileSdkVersion 仍是 36，會卡在 :app:checkDebugAarMetadata。
    // 用 maxOf 而不是硬钉 37，等 Flutter 的 compileSdkVersion 超過 37 時自動跟進。
    compileSdk = maxOf(37, flutter.compileSdkVersion)

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.dennys.dhealth"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // Health Connect requires Android 14.
        minSdk = 34
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        ndk {
            // https://developer.android.com/ndk/guides/abis#sa
            abiFilters.addAll( listOf("armeabi-v7a", "arm64-v8a", "x86", "x86_64"))
            // abiFilters.addAll( listOf("arm64-v8a"))
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
