
import org.gradle.api.tasks.compile.JavaCompile
import org.gradle.api.tasks.Delete

allprojects {
    repositories {
        google()
        mavenCentral()
    }

    tasks.withType<JavaCompile>().configureEach {
        options.compilerArgs.add("-Xlint:-options")
    }
}

rootProject.buildDir = file("../build")

subprojects {
    buildDir = file("${rootProject.buildDir}/${name}")
}
//subprojects {
//    afterEvaluate {
//        val android = extensions.findByName("android") as? com.android.build.gradle.BaseExtension
//        android?.apply {
//            // Force every plugin to use your specified NDK version
//            ndkVersion = "28.2.13676358"
//
//            // Ensure no plugin is using a minSdk lower than 21 (required for 16KB)
//            defaultConfig.minSdkVersion(project.findProperty("flutter.minSdkVersion")?.toString()?.toInt() ?: 24)
//        }
//    }
//}
subprojects {
    afterEvaluate {
        val android = extensions.findByName("android") as? com.android.build.gradle.BaseExtension
        android?.apply {
            // NDK 28 is very new. Agar build fail ho toh 27.0.12077973 use karein.
            ndkVersion = "28.2.13676358"

            defaultConfig {
                // Ensure minSdk is consistent
                minSdkVersion(24)
                targetSdkVersion(35) // Play Store targets usually 34 or 35
            }
        }
    }
}
subprojects {
    evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}
