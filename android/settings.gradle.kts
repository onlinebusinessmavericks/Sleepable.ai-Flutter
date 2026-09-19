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

    // Force every Flutter plugin onto the same Kotlin Gradle Plugin,
    // including legacy ids like "kotlin-android".
    resolutionStrategy {
        eachPlugin {
            val id = requested.id.id
            if (id.startsWith("org.jetbrains.kotlin") ||
                id == "kotlin-android" ||
                id == "kotlin" ||
                id == "kotlin-kapt"
            ) {
                useVersion("2.4.0")
            }
        }
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.1.0" apply false
    id("org.jetbrains.kotlin.android") version "2.4.0" apply false
    id("com.google.gms.google-services") version "4.4.2" apply false
}

include(":app")
