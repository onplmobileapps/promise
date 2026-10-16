import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // Firebase: reads google-services.json, and tags each build for
    // Crashlytics and uploads its R8 mapping so crashes read as source.
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// The upload key that signs releases, from android/key.properties, which is
// kept out of git: storeFile, storePassword, keyAlias and keyPassword.
val keyProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) FileInputStream(file).use { load(it) }
}
val hasUploadKey = keyProperties.getProperty("storeFile") != null

android {
    namespace = "com.onnetwork.hrms.app"
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // The app's ID on Google Play and in Firebase.
        applicationId = "com.onnetwork.hrms.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasUploadKey) {
            create("release") {
                storeFile = file(keyProperties.getProperty("storeFile"))
                storePassword = keyProperties.getProperty("storePassword")
                keyAlias = keyProperties.getProperty("keyAlias")
                keyPassword = keyProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasUploadKey) signingConfigs.getByName("release") else null
            // R8 shrinks, optimizes and obfuscates the Java/Kotlin code and
            // drops unused resources. Crashlytics uploads its mapping, and it
            // goes into the app bundle for Play too.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

// A release is never signed with a debug key by mistake: without the upload
// key it stops and says why.
gradle.taskGraph.whenReady {
    val releasing = allTasks.any { task ->
        task.project == project &&
            (task.name.startsWith("assembleRelease") || task.name.startsWith("bundleRelease"))
    }
    if (releasing && !hasUploadKey) {
        throw GradleException(
            "Release signing needs android/key.properties with storeFile, " +
                "storePassword, keyAlias and keyPassword.",
        )
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_21)
    }
}

flutter {
    source = "../.."
}

// Phones only in a release: the x86 builds of the native libraries (ONNX
// Runtime, MapLibre, ML Kit) are for emulators and would add about 45 MB.
// Debug builds keep them for the emulator.
androidComponents {
    onVariants(selector().withBuildType("release")) { variant ->
        variant.packaging.jniLibs.excludes.addAll(listOf("lib/x86/**", "lib/x86_64/**"))
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
