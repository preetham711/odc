plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Google Services plugin for Firebase
    id("com.google.gms.google-services")
    // Firebase Crashlytics plugin
    id("com.google.firebase.crashlytics")
    // Firebase Performance Monitoring plugin
    id("com.google.firebase.firebase-perf")
}

android {
    namespace = "com.odctracker.odc_tracker_ai"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    // ── Release signing ──────────────────────────────────────────────────────
    // To create a keystore, run:
    //   keytool -genkey -v -keystore android/app/odc_tracker_release.jks \
    //           -keyalg RSA -keysize 2048 -validity 10000 \
    //           -alias odc_tracker
    //
    // Then set these environment variables (or a local.properties entry):
    //   KEYSTORE_PASSWORD  = <your keystore password>
    //   KEY_PASSWORD       = <your key password>
    //
    // The keystore FILE itself should NOT be committed to git.
    // Add it to .gitignore: android/app/*.jks
    signingConfigs {
        create("release") {
            val keystoreFile = file("odc_tracker_release.jks")
            if (keystoreFile.exists()) {
                storeFile = keystoreFile
                storePassword = System.getenv("KEYSTORE_PASSWORD") ?: "changeme"
                keyAlias = "odc_tracker"
                keyPassword = System.getenv("KEY_PASSWORD") ?: "changeme"
            }
            // If the keystore is absent, gradle falls back to debug signing
            // so `flutter build apk --release` still works locally.
        }
    }

    defaultConfig {
        applicationId = "com.odctracker.odc_tracker_ai"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            val keystoreFile = file("odc_tracker_release.jks")
            signingConfig = if (keystoreFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                // Keystore not present — use debug keys so the build succeeds.
                // Create the keystore (see comment above) before a production release.
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Core library desugaring
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    
    // Import the Firebase BoM (use 33.x for Kotlin 2.1 compatibility)
    implementation(platform("com.google.firebase:firebase-bom:33.14.0"))
    
    // Firebase Analytics
    implementation("com.google.firebase:firebase-analytics")
    
    // Firebase Authentication
    implementation("com.google.firebase:firebase-auth")
    
    // Cloud Firestore
    implementation("com.google.firebase:firebase-firestore")
    
    // Firebase Cloud Storage
    implementation("com.google.firebase:firebase-storage")
    
    // Firebase Cloud Messaging (Push Notifications)
    implementation("com.google.firebase:firebase-messaging")
    
    // Firebase Crashlytics (Optional - for crash reporting)
    implementation("com.google.firebase:firebase-crashlytics")
    
    // Firebase Performance Monitoring (Optional)
    implementation("com.google.firebase:firebase-perf")
}
