# This folder is currently unused

Sign recognition now runs model-free, using hand-landmark geometry
(`lib/services/hand_sign_service.dart`) instead of a trained classifier —
so there's nothing to put in this folder right now, and `pubspec.yaml`
no longer declares it as an asset directory.

`labels.txt` is left here only as a leftover from the earlier TFLite-based
approach, in case that path gets revisited later (it's genuinely more
accurate once you have real training data — the geometric rules approach
is a fast, no-setup starting point, not a long-term replacement for a
properly trained model). If you do go back to it: re-add
`- assets/model/` under `flutter: assets:` in `pubspec.yaml`, add
`tflite_flutter` and `image` back to dependencies, and the general shape of
the old `SignRecognitionService` (camera frame → preprocess → `Interpreter.
run()` → label) is straightforward to rebuild the same way.
