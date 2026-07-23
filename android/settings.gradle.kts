pluginManagement {

    val flutterSdkPath: String = providers
        .gradleProperty("flutter.sdk")
        .orElse(
            file("local.properties")
                .readLines()
                .first { it.startsWith("flutter.sdk=") }
                .substringAfter("=")
        )
        .get()

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.9.1" apply false
    id("org.jetbrains.kotlin.android") version "2.3.10" apply false
    id("com.google.gms.google-services") version "4.4.2" apply false
}

include(":app")
