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
        applicationId = "com.agrocom.dronagro"
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
            resValue(type = "string", name = "app_name", value = "DronAgro Piloto")
        }
        create("cliente") {
            dimension = "rol"
            applicationIdSuffix = ".cliente"
            resValue(type = "string", name = "app_name", value = "DronAgro")
        }
    }

    // Firma de release: todo viene de variables de entorno o propiedades de
    // Gradle (-P / ~/.gradle/gradle.properties). Nunca hay un keystore ni
    // contraseñas en el repo — ver docs/seguridad/firma-release.md. Sin esas
    // variables el release queda sin firmar (no se firma con la clave debug).
    fun secreto(nombre: String): String? =
        System.getenv(nombre) ?: (project.findProperty(nombre) as String?)

    val almacen = secreto("AGROCOM_KEYSTORE_FILE")
    val firmaConfigurada =
        almacen != null &&
            secreto("AGROCOM_KEYSTORE_PASSWORD") != null &&
            secreto("AGROCOM_KEY_ALIAS") != null &&
            secreto("AGROCOM_KEY_PASSWORD") != null

    if (firmaConfigurada) {
        signingConfigs {
            create("release") {
                storeFile = file(almacen!!)
                storePassword = secreto("AGROCOM_KEYSTORE_PASSWORD")
                keyAlias = secreto("AGROCOM_KEY_ALIAS")
                keyPassword = secreto("AGROCOM_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            if (firmaConfigurada) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // flutter_local_notifications (HU-62, avisos locales) exige desugaring habilitado.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // local_auth (desbloqueo con huella o rostro, ADR 0026): el aviso del sistema
    // exige un tema AppCompat, y sus recursos deben estar en la app.
    implementation("androidx.appcompat:appcompat:1.7.0")
}
