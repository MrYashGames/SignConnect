# Android build errors — checklist

I don't have your actual error text, so I can't point at the exact line —
**please paste the real error output** (from `flutter run` or Android
Studio's build output) next time; "it gives an error" could be any of a
dozen different things with this dependency set, and guessing blind risks
sending you down the wrong path entirely.

In the meantime, here's what changed and what's most likely to matter,
roughly in order of likelihood:

## 1. Dependencies were trimmed — do a full clean rebuild
Agora and TFLite are gone entirely (unused after switching Meet to Jitsi
and sign recognition to the model-free approach). Fewer native plugins
means fewer chances for Gradle/AGP conflicts, but **you must** do:

```
flutter clean
flutter pub get
flutter run
```

Just re-running without `clean` after a dependency change is a common
source of confusing, stale-feeling errors.

## 2. `hand_landmarker`'s prerequisites are strict
Per its own documentation:
- **Flutter SDK 3.44 or higher**
- **JDK 17 or higher**
- **Android only** — minimum API level 24 (same requirement Jitsi already
  has, so your `minSdkVersion` should already be at 24 from the Jitsi
  setup — see `SETUP_JITSI.md`)

Run `flutter --version` and check your JDK version
(`java -version`, or in Android Studio: Settings → Build Tools → Gradle →
Gradle JDK) against these. An older Flutter or JDK is a very plausible
cause of a build failure with this plugin specifically.

## 3. `camera` version bump
`hand_landmarker` requires `camera: ^0.12.1`; the project was previously
pinned to `^0.11.0+2`. This has been updated in `pubspec.yaml`, but if you
have a `pubspec.lock` from before, delete it and run `flutter pub get`
fresh so the solver doesn't try to satisfy the old constraint:

```
rm pubspec.lock   # or del pubspec.lock on Windows
flutter pub get
```

## Confirmed issues found so far (fixes in their own docs)
- Duplicate `MainActivity` class → fixed directly, see prior chat history.
- `compileSdk` must be 36, not 34 — **and this turned out to be the
  jitsi_meet_flutter_sdk plugin's own internal module, not your app's
  build.gradle; your app's compileSdk setting was already correct and
  couldn't fix it on its own** → `SETUP_JITSI.md`, bumped the plugin to
  `^13.2.0` as the fix.
- `hand_landmarker`/`jni` needs `dart run jni:setup` once → `SETUP_HAND_LANDMARKER.md`.

## Known harmless warning (safe to ignore)
```
[ERROR:flutter/shell/common/shell.cc...] The 'flutter_tts' channel sent a
message from native to Flutter on a non-platform thread...
```
This is a logged warning from `flutter_tts` about platform-channel
threading — it's a known plugin-level quirk, not something fixed in app
code, and doesn't block the build. Only worth revisiting if it's paired
with an actual crash (not just this log line).

## 4. Still failing after all of the above?
Send me:
- The exact error text/stack trace
- Output of `flutter doctor -v`
- Output of `flutter --version`

With the actual error, I can tell you precisely what's wrong instead of
listing possibilities.
