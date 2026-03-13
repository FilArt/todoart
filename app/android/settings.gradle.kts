pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            val localPropertiesFile = file("local.properties")
            localPropertiesFile.inputStream().use { properties.load(it) }
            val configuredNdkDir =
                properties
                    .getProperty("ndk.dir")
                    ?.takeIf { file(it).resolve("source.properties").isFile }
            val nixStoreNdkDir =
                java.io.File("/nix/store")
                    .listFiles()
                    ?.asSequence()
                    ?.filter { it.name.contains("-android-sdk-ndk-") }
                    ?.mapNotNull { storePath ->
                        storePath
                            .resolve("libexec/android-sdk/ndk")
                            .listFiles()
                            ?.firstOrNull { candidate ->
                                candidate.resolve("source.properties").isFile
                            }
                    }
                    ?.firstOrNull()

            val resolvedNdkDir = configuredNdkDir ?: nixStoreNdkDir?.absolutePath
            if (resolvedNdkDir != null) {
                properties.setProperty("ndk.dir", resolvedNdkDir)
                localPropertiesFile.outputStream().use { output ->
                    properties.store(output, null)
                }
            }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
}

include(":app")
