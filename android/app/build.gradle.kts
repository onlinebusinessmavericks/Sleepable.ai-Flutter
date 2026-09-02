plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

import java.util.Properties
import java.io.FileInputStream
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use {
        localProperties.load(it)
    }
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.sleepableai.sleepableai"
    compileSdk = 37
//    ndkVersion = "27.0.12077973"
    ndkVersion = "28.2.13676358"

    java {
        toolchain.languageVersion.set(JavaLanguageVersion.of(21))
    }

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }

    defaultConfig {
        applicationId = "com.sleepableai.sleepableai"
        minSdk = 24
        targetSdk = 36
        versionCode = 18
        versionName = "1.0.16"
        multiDexEnabled = true

        ndk {
            abiFilters.addAll(listOf("arm64-v8a", "x86_64"))
        }
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        getByName("debug") {
            isMinifyEnabled = false
            isShrinkResources = false
        }

        getByName("release") {
            isMinifyEnabled = true
            isShrinkResources = true
            signingConfig = signingConfigs.getByName("release")
            proguardFiles(
                getDefaultProguardFile("proguard-android.txt"),
                "proguard-rules.pro"
            )
        }
    }
    packaging {
        jniLibs {
            // CRITICAL: This ensures libraries are aligned and not compressed
            // so they can be memory-mapped on 16 KB page devices.
            useLegacyPackaging = false
        }
        resources {
            // Keep your existing excludes if any
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }

    // Explicitly tell the system not to compress .so files
    androidResources {
        noCompress.add("so")
    }

    defaultConfig {
        // ... existing config
        ndk {
            // Restrict to 64-bit for better 16KB compatibility
            abiFilters.addAll(listOf("arm64-v8a", "x86_64"))
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_21)
    }
}

flutter {
    source = "../.."
}

configurations.all {
    resolutionStrategy {
        eachDependency {
            if (requested.group == "org.jetbrains.kotlin") {
                useVersion("2.3.10")
                because("App module must read Firebase Auth / audio_session Kotlin 2.3 metadata")
            }
        }
        force("androidx.browser:browser:1.5.0")
        force("androidx.core:core-ktx:1.6.0")
        force("androidx.appcompat:appcompat:1.6.1")
    }
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:33.10.0"))
    implementation("com.google.firebase:firebase-messaging")// Add this line
    implementation("com.google.firebase:firebase-analytics") // Recommended for notifications
    implementation("androidx.multidex:multidex:2.0.1")
    implementation("com.google.android.material:material:1.5.0")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}