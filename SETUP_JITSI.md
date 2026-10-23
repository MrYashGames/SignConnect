# Required native setup for the Meet feature

`jitsi_meet_flutter_sdk` is a native plugin (Android/iOS platform code),
not pure Dart — adding it to `pubspec.yaml` alone isn't enough. Without
these steps, `jitsiMeet.join()` can fail at the native layer with nothing
useful surfacing in the Flutter console, which is exactly why "Start an
instant meeting" looked like it did nothing. (The app now also catches and
shows the error in a SnackBar if it fails — so if you've done the steps
below and it still fails, that message will tell you what's actually
wrong.)

## Android

**1. Minimum SDK version 24** — open `android/app/build.gradle`:

```groovy
android {
    ...
    defaultConfig {
        ...
        minSdkVersion 24   // Jitsi requires at least this
    }
}
```

If your project's `minSdkVersion` is currently lower (Flutter defaults to
21), this alone can be the entire cause — the plugin's native Android code
won't load correctly below API 24.

**1b. compileSdk 36 — UPDATE: setting your app's compileSdk isn't enough on its own.**
The AAR metadata error (`:jitsi_meet_flutter_sdk is currently compiled
against android-34`) refers to the *plugin's own* internal Android module,
not your app's `build.gradle` — your app's `compileSdk` can't override a
dependency's own internal build config. `jitsi_meet_flutter_sdk: 13.1.1`
ships with `compileSdk 34` baked into its own module, which conflicts with
the `media3 1.8.0` libraries it pulls in (those require 35+).

**Fix: bump the plugin itself.** `pubspec.yaml` now pins
`jitsi_meet_flutter_sdk: ^13.2.0` (was `13.1.1`) — a newer release (9 days
old at time of writing) that bumped its internal native SDK versions,
which plausibly carries a higher `compileSdk` with it. Run:
```
flutter clean
flutter pub get
flutter run
```
**If 13.2.0 still reports the same `android-34` error:** the version bump
didn't fix it, and the remaining option is a manual (if messier) patch:
open `%LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\jitsi_meet_flutter_sdk-<version>\android\build.gradle`
directly and change its `compileSdkVersion`/`compileSdk` line from `34` to
`36` by hand. This works, but gets silently wiped every time
`flutter pub get` re-fetches the package, so it's a last resort, not a
permanent fix — report it as an issue on
https://github.com/jitsi/jitsi-meet-flutter-sdk/issues if you end up
needing it, since that means the published package itself has the bug.

Your app's own `compileSdk 36` setting (below) is still correct and
worth keeping regardless — it's necessary, just not sufficient on its own.

**2. AndroidManifest.xml label conflict** — open
`android/app/src/main/AndroidManifest.xml`. Jitsi's own SDK manifest
declares an `android:label` that conflicts with yours. Add the `tools`
namespace and `tools:replace="android:label"` to your `<application>` tag:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">
    <application
        tools:replace="android:label"
        android:label="sign_connect"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        ...
    </application>
</manifest>
```

Without this, the build can fail outright with a manifest merge error —
worth checking your build output for that specifically if you haven't
already.

**3. ProGuard (release builds only)** — if you ever build `--release`,
add the rules Jitsi publishes here to your `proguard-rules.pro`:
https://github.com/jitsi/jitsi-meet/blob/master/android/app/proguard-rules.pro
(not needed for debug builds, which is almost certainly what you're
running while developing).

## iOS

**1. Podfile** — in `ios/Podfile`:

```
platform :ios, '15.1'
```

**2. Info.plist** — in `ios/Runner/Info.plist`, add (if not already
present from the camera/mic features):

```xml
<key>NSCameraUsageDescription</key>
<string>The app needs access to your camera for meetings.</string>
<key>NSMicrophoneUsageDescription</key>
<string>The app needs access to your microphone for meetings.</string>
```

## After making any of these changes

Native config changes are **not** picked up by hot reload or hot restart.
Run:

```
flutter clean
flutter pub get
flutter run
```

A full rebuild is required, not just re-running the app.
