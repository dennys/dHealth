import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// release 簽章檔與密碼都放 android/key.properties（gitignored，絕不進 repo）。
// CI 由 KEYSTORE_B64 / KEY_PASSWORD secrets 生成它；沒有就退回 debug 簽章，
// 讓 fork 和沒設 secret 的 CI 照样能 build。
val keystoreProps = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) FileInputStream(f).use { load(it) }
}

extensions.configure<com.android.build.api.dsl.ApplicationExtension> {
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
        // Health Connect 的真正下限是 Android 9（API 28）+ Play services：14 以上是系統
        // framework module，13 及以下要從 Play Store 裝 Health Connect APK（app 內的
        // 「Install Health Connect」按鈕就是那條路）。取 33 是因為這是目前唯一有真機可測的
        // 較舊版本；要再往下就不能低於 28，否則裝得上但永遠讀不到資料。
        minSdk = 33
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        ndk {
          // minSdk 33（Android 13）的装置实质上是 arm64 世代；README 也寫只 enable arm64。
          // 要支援 armeabi-v7a 的老装置再把它加回來（APK 體積與 AOT 時間都會上去）。
          // https://developer.android.com/ndk/guides/abis#sa
          abiFilters.addAll(listOf("arm64-v8a"))
        }
    }

    signingConfigs {
        if (keystoreProps.isNotEmpty()) {
            create("release") {
                storeFile = file(keystoreProps["storeFile"] as String)
                storePassword = keystoreProps["storePassword"] as String
                keyAlias = keystoreProps["keyAlias"] as String
                keyPassword = keystoreProps["keyPassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystoreProps.isNotEmpty()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
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
