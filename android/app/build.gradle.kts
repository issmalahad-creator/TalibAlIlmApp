import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// 2026-08-18: Play Store release-signing groundwork (Ismail: "جهز الاساس
// حقه" — foundation only, not publishing yet). Reads `android/key.properties`
// (gitignored, never committed) so the actual keystore password never
// touches source control. Falls back to debug signing if the file doesn't
// exist, so `flutter run --release` still works for anyone without it.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasKeystoreProperties = keystorePropertiesFile.exists()
if (hasKeystoreProperties) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.sunnahinstitute.talib_alilm"
    // file_picker's transitive dependency (flutter_plugin_android_lifecycle)
    // requires compileSdk 36+; the Flutter tool's own default (34) is too
    // old for it, so this is pinned explicitly rather than left on
    // flutter.compileSdkVersion. Don't revert to the flutter-provided
    // default without checking plugin requirements again.
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    // AGP disables resValues by default since 7.x — needed for the
    // per-flavor `resValue("string", "app_name", ...)` calls below.
    buildFeatures {
        resValues = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.sunnahinstitute.talib_alilm"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Two real, separately-installable apps (Ismail 2026-09-19: "تطبيقان
    // منفصلان") — "full" (everything bundled, today's existing behaviour
    // and applicationId, so current installs/store listing are untouched)
    // and "lite" (own applicationId, own label, so both can be installed
    // side by side on one device / listed separately on the store). The
    // Quran corpus text (~330 MB) is stripped from the lite build's Flutter
    // asset bundle by `tool/build_lite_apk.sh` BEFORE this Gradle build
    // runs — Gradle flavors alone don't control the Flutter asset bundle,
    // so this only handles applicationId/label; see that script for the
    // asset side. `lib/repositories/quran_book_cache.dart` already falls
    // back to `QuranCorpusDownloadService` whenever a bundled asset is
    // absent, so the SAME Dart code serves both flavors unmodified.
    flavorDimensions += "distribution"
    productFlavors {
        create("full") {
            dimension = "distribution"
            resValue("string", "app_name", "طالب العلم")
        }
        create("lite") {
            dimension = "distribution"
            applicationIdSuffix = ".lite"
            resValue("string", "app_name", "طالب العلم (خفيف)")
        }
    }

    signingConfigs {
        if (hasKeystoreProperties) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasKeystoreProperties) signingConfigs.getByName("release") else signingConfigs.getByName("debug")
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
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")

    // Tesseract4Android — OCR على الجهاز لكتب "مكتبتي" المصوَّرة بلا طبقة نص.
    // قناة MethodChannel كتبناها بأنفسنا (MainActivity.kt) بعد أن فشلت فعليًا
    // حزمتا Flutter الجاهزتين (flutter_tesseract_ocr، tesseract_ocr) في
    // البناء على AGP 9 (وحدة Gradle قديمة لا تُطبِّق com.android.library).
    implementation("cz.adaptech.tesseract4android:tesseract4android:4.9.0")
}
