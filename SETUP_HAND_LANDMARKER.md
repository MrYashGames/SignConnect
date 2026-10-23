# Required one-time setup for Hand Sign Recognition

`hand_landmarker` depends on `package:jni` (Dart↔Java interop) and
`jni_flutter` under the hood to call Android's camera/context APIs from
Dart. Those packages need a native helper library built once before they
work — without it, opening the Hand Sign Recognition tab throws:

```
Unhandled Exception: Unable to locate the helper library.
Ensure that the helper library is available at the path:
build\jni_libs\dartjni.dll
Run `dart jni:setup` to generate the shared library if it does not exist.
```

## Fix

From the project root (`C:\Users\yashm\Desktop\SignConnect\frontend`), run:

```
dart run jni:setup
```

This builds the `dartjni` shared library into `build/jni_libs/` (or
`build\jni_libs\dartjni.dll` on Windows specifically, matching what the
error message names). It requires a C/C++ toolchain to be available —
on Windows that typically means Visual Studio's "Desktop development with
C++" workload needs to be installed (the same one Flutter's own Windows
desktop target uses, so if you've ever built this project for Windows
desktop before, you likely already have it).

You only need to run this once per machine/checkout, not every build —
but it does need to be re-run if you ever delete the `build/` directory
(e.g. after `flutter clean`).

## Order of operations

Given everything currently blocking a full run, the practical order is:

1. Fix the Kotlin `MainActivity` duplicate (done, per earlier fix).
2. Fix `compileSdk` → 36 (see `SETUP_JITSI.md`).
3. `flutter clean && flutter pub get`
4. `dart run jni:setup` (this doc)
5. `flutter run`

If `dart run jni:setup` itself fails, it's almost always a missing C++
toolchain — the command's own error output will say what's missing.
