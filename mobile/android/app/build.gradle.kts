import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Llave de firma de publicación: vive FUERA del repositorio (nunca se sube a GitHub).
// Por defecto en ~/.caporal/key.properties; otra ruta con la variable CAPORAL_FIRMA_ANDROID.
// Sin ella, la versión release se firma con la llave de pruebas y lo advierte.
val archivoFirma = file(System.getenv("CAPORAL_FIRMA_ANDROID") ?: "${System.getProperty("user.home")}/.caporal/key.properties")
val firma = Properties().apply { if (archivoFirma.exists()) FileInputStream(archivoFirma).use { load(it) } }
val hayFirma = archivoFirma.exists()

android {
    namespace = "co.caporal.caporal"
    // 37: lo pide flutter_local_notifications (avisos). minSdk y targetSdk no cambian.
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Necesario para los avisos programados (flutter_local_notifications).
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "co.caporal.caporal"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 31 // Android 12 o superior (requisito de la convocatoria)
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hayFirma) {
            create("publicacion") {
                storeFile = file(firma.getProperty("storeFile"))
                storePassword = firma.getProperty("storePassword")
                keyAlias = firma.getProperty("keyAlias")
                keyPassword = firma.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            if (hayFirma) {
                signingConfig = signingConfigs.getByName("publicacion")
            } else {
                logger.warn("Caporal: no se encontró la llave de firma; la APK release queda firmada con la llave de PRUEBAS.")
                signingConfig = signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
