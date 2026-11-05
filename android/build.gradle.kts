// AGP 9 turns checkDebugAarMetadata into a hard error when a library module compiles
// against an older SDK than one of its dependency AARs requires: here
// flutter_plugin_android_lifecycle 2.0.27 declares minCompileSdk 36 while file_picker
// 9.2.2 and awesome_notifications 0.10.1 still pin compileSdk 34 in their own build
// files. Lift every library module to the app's compileSdk (which is
// flutter.compileSdkVersion) instead of patching plugin sources or pinning a number.
// Must be registered before any project gets evaluated (the evaluationDependsOn(":app")
// block below evaluates :app during root configuration) and before AGP locks its DSL.
subprojects {
    afterEvaluate {
        if (pluginManager.hasPlugin("com.android.library")) {
            val appCompileSdk = rootProject.project(":app").extensions
                .getByType(com.flutter.gradle.FlutterExtension::class.java)
                .compileSdkVersion
            extensions.configure<com.android.build.gradle.LibraryExtension>("android") {
                if ((compileSdk ?: 0) < appCompileSdk) {
                    compileSdk = appCompileSdk
                }
            }
        }
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
