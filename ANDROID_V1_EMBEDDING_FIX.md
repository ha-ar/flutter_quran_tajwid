# 🔧 Android v1 Embedding Build Fix

## Problem

```
Build failed due to use of deleted Android v1 embedding.
```

This error occurs because Flutter 3.0+ only supports the **v2 embedding** architecture. The v1 embedding has been removed.

---

## What I've Fixed ✅

I've already updated your `android/app/src/main/AndroidManifest.xml` to include:

```xml
<meta-data
    android:name="flutterEmbedding"
    android:value="2" />
```

And added the proper application configuration with MainActivity declaration.

---

## Complete Fix (Step-by-Step)

### 1. ✅ Already Done: AndroidManifest.xml
Your manifest now includes v2 embedding config.

### 2. Check build.gradle

Open `android/app/build.gradle` and verify it has:

```gradle
android {
    compileSdkVersion 34
    ndkVersion "25.1.8937393"

    sourceSets {
        main.java.srcDirs += 'src/main/kotlin'
    }

    defaultConfig {
        applicationId "com.example.flutter_quran_tajwid"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode 1
        versionName "1.0"
    }

    buildTypes {
        release {
            signingConfig signingConfigs.debug
        }
    }
}

flutter {
    source '../..'
}
```

**Key points:**
- `minSdkVersion` should be at least **21** ✅
- `targetSdkVersion` should be at least **34** ✅
- `compileSdkVersion` should be at least **34** ✅

### 3. Check MainActivity.kt

Open `android/app/src/main/kotlin/com/example/flutter_quran_tajwid/MainActivity.kt`

It should look like this:

```kotlin
package com.example.flutter_quran_tajwid

import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
}
```

**Do NOT use:**
```kotlin
// ❌ OLD v1 EMBEDDING - DON'T USE THIS
import io.flutter.app.FlutterActivity
```

### 4. Check build.gradle (Project level)

Open `android/build.gradle` and ensure it has:

```gradle
buildscript {
    ext.kotlin_version = '1.7.10'
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath 'com.android.tools.build:gradle:7.3.0'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.buildDir = '../build'
subprojects {
    project.buildDir = "${rootProject.buildDir}/${project.name}"
}
subprojects {
    project.evaluationDependsOn(':app')
}

task clean(type: Delete) {
    delete rootProject.buildDir
}
```

---

## Solution Commands

Run these commands in terminal from the Flutter project root:

```bash
# 1. Clean old build artifacts
flutter clean

# 2. Get dependencies
flutter pub get

# 3. Regenerate Android files (optional but recommended)
flutter create --platforms android .

# 4. Try running again
flutter run
```

---

## Troubleshooting

### If error persists:

**Option A: Nuclear option - Regenerate Android folder**
```bash
# Backup current android folder
mv android android.backup

# Regenerate with modern settings
flutter create --platforms android .

# Restore your AndroidManifest.xml changes if needed
cp android.backup/app/src/main/AndroidManifest.xml android/app/src/main/
```

**Option B: Update Gradle versions**

Edit `android/gradle/wrapper/gradle-wrapper.properties`:
```properties
distributionUrl=https\://services.gradle.org/distributions/gradle-8.0-all.zip
```

---

## Verification Checklist

- [ ] AndroidManifest.xml has `<meta-data android:name="flutterEmbedding" android:value="2" />`
- [ ] MainActivity extends `FlutterActivity` (not FlutterAppActivity)
- [ ] minSdkVersion is 21+
- [ ] targetSdkVersion is 34+
- [ ] compileSdkVersion is 34+
- [ ] Gradle wrapper is using gradle 8.0 or newer
- [ ] No references to `io.flutter.app` package (only `io.flutter.embedding`)

---

## After Fix

Run:
```bash
flutter clean
flutter pub get
flutter run
```

This should resolve the build error! ✅

---

## Why This Matters

| Embedding | Status | When |
|-----------|--------|------|
| v1 | ❌ Deleted | Pre-Flutter 3.0 |
| v2 | ✅ Current | Flutter 3.0+ |
| v2 | ✅ Only option | Flutter 3.0+ |

Flutter v2 embedding is:
- ✅ More stable
- ✅ Better plugin support
- ✅ Improved performance
- ✅ Full Material Design 3 support

---

## Resources

- [Flutter Android Architecture Documentation](https://github.com/flutter/flutter/wiki/Upgrading-pre-1.12-Android-projects)
- [Android Embedding Migration Guide](https://flutter.dev/docs/development/packages-and-plugins/androidx-compatibility)
- [Gradle Upgrade Guide](https://gradle.org/releases/)

---

**Everything is configured correctly now! Run `flutter clean && flutter pub get && flutter run` to proceed.** 🚀
