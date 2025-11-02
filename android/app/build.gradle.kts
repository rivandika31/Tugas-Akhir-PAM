plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services") // ✅ Sudah benar, ini cukup
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.aplikasi_chat"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true // ✅ Tambahkan baris ini
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.aplikasi_chat"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // Tambahan penting untuk desugaring
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    // Pastikan dependency Flutter lainnya tetap di sini
}


flutter {
    source = "../.."
}
