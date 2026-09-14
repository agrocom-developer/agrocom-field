plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.agrocom.agrocom_field"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.agrocom.agrocom_field"
        // Android 10 — el RC del dron DJI Agras (flavor piloto) no sube de acá.
        // No bajar sin confirmar hardware; no subir sin confirmar que el RC lo tolera.
        minSdk = 29
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "rol"

    productFlavors {
        create("piloto") {
            dimension = "rol"
            applicationIdSuffix = ".piloto"
            resValue(type = "string", name = "app_name", value = "Agrocom Piloto")
        }
        create("auxiliar") {
            dimension = "rol"
            applicationIdSuffix = ".auxiliar"
            resValue(type = "string", name = "app_name", value = "Agrocom Auxiliar")
        }
    }

    buildTypes {
        release {
            // TODO(distribucion-flutter): firma real antes del primer release —
            // nunca un keystore real en el repo (*.jks / key.properties ya están
            // en .gitignore).
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // flutter_local_notifications (HU-62, avisos locales) exige desugaring habilitado.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
