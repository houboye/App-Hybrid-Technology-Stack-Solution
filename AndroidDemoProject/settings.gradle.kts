pluginManagement {
    repositories {
        google {
            content {
                includeGroupByRegex("com\\.android.*")
                includeGroupByRegex("com\\.google.*")
                includeGroupByRegex("androidx.*")
            }
        }
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "AndroidDemoProject"
include(":app")

// ========================================
// Flutter Module Integration
// ========================================
// Uncomment after running `flutter pub get` in FlutterModule/:
//
// val flutterProjectPath = file("../FlutterModule").absolutePath
// apply(from = "$flutterProjectPath/.android/include_flutter.groovy")

// ========================================
// React Native Integration
// ========================================
// React Native is integrated via the app's build.gradle.kts dependencies.
// After running `npm install` in ReactNativeModule/, configure:
// - Add react-native dependency to app/build.gradle.kts
// - Ensure node_modules path is accessible
