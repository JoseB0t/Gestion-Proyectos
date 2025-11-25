plugins {
    id("com.android.application")
    id("com.google.gms.google-services") // ✅ Firebase
    id("org.jetbrains.kotlin.android")   // ✅ nombre correcto del plugin de Kotlin
    id("dev.flutter.flutter-gradle-plugin") // ✅ Flutter
}

android {
    namespace = "com.example.neurodrive"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "29.0.14206865"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.neurodrive"
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
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    // ✅ Usa comillas dobles en Kotlin Script
    implementation(platform("com.google.firebase:firebase-bom:33.4.0"))
    implementation("com.google.firebase:firebase-auth-ktx:22.3.1")
    implementation("com.google.firebase:firebase-firestore-ktx:25.1.0")
    implementation("com.google.firebase:firebase-messaging-ktx:24.0.0")
    implementation("com.google.firebase:firebase-analytics-ktx:22.1.0")
}

flutter {
    source = "../.."
}
