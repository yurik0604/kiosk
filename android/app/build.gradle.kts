plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.kiosk.kiosk"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.kiosk.kiosk"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 30
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // LLRP Toolkit (Java) — used by the Sensormatic IDX-4000 driver.
    // LTK references org.apache.log4j.Logger directly, so we replace log4j 1.x
    // with the SLF4J shim (same package/classes, routes to SLF4J under the hood).
    implementation("org.llrp:ltkjava:1.0.0.7") {
        exclude(group = "log4j", module = "log4j")
        exclude(group = "ch.qos.logback", module = "logback-classic")
    }
    implementation("org.slf4j:log4j-over-slf4j:2.0.13")
    implementation("org.slf4j:slf4j-android:1.7.36")
}
