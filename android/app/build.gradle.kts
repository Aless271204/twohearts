plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseStore = System.getenv("NIDO_KEYSTORE_PATH")
val allowTestSigning = System.getenv("NIDO_ALLOW_TEST_SIGNING") == "true"

android {
    namespace = "com.example.twohearts"
    compileSdk = maxOf(flutter.compileSdkVersion, 37)
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // Keep existing sideload builds compatible; Play uses a distinct, permanent ID.
        applicationId = System.getenv("NIDO_APPLICATION_ID") ?: "com.example.twohearts"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = maxOf(flutter.minSdkVersion, 24)
        targetSdk = maxOf(flutter.targetSdkVersion, 36)
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (!releaseStore.isNullOrBlank()) {
            create("nidoRelease") {
                storeFile = file(releaseStore)
                storeType = "PKCS12"
                storePassword = System.getenv("NIDO_STORE_PASSWORD")
                keyAlias = System.getenv("NIDO_KEY_ALIAS")
                keyPassword = System.getenv("NIDO_KEY_PASSWORD")
            }
        }
    }
    buildTypes {
        release {
            // Never silently publish with a debug certificate.
            signingConfig = if (!releaseStore.isNullOrBlank()) signingConfigs.getByName("nidoRelease")
                else if (allowTestSigning) signingConfigs.getByName("debug") else null
        }
    }
}

gradle.taskGraph.whenReady {
    if (allTasks.any { it.name == "packageRelease" || it.name == "bundleRelease" } &&
        releaseStore.isNullOrBlank() && !allowTestSigning) {
        throw GradleException("Configure the private NIDO release signing secrets. Debug signing is only allowed explicitly for CI tests.")
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
    implementation("androidx.multidex:multidex:2.0.1")
    implementation("com.google.android.material:material:1.13.0")
    implementation("androidx.concurrent:concurrent-futures:1.3.0")
}
