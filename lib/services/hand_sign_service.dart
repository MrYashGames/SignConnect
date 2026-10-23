import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:hand_landmarker/hand_landmarker.dart';
import 'localization_service.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class HandSignDetection {
  final String label;
  final double confidence;
  final String english;
  final String hindi;
  final String marathi;
  final bool isWordSign;

  const HandSignDetection({
    required this.label,
    required this.confidence,
    required this.english,
    required this.hindi,
    required this.marathi,
    this.isWordSign = false,
  });

  String localized(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.hi:
        return hindi.isNotEmpty ? hindi : label;
      case AppLanguage.mr:
        return marathi.isNotEmpty ? marathi : label;
      case AppLanguage.en:
        return english.isNotEmpty ? english : label;
    }
  }
}

/// 100% On-Device ISL Sign & Hand Gesture Recognition Engine.
/// Runs locally on Android via MediaPipe native pipeline and TFLite — ZERO server required.
class HandSignService {
  HandSignService._internal();
  static final HandSignService instance = HandSignService._internal();

  HandLandmarkerPlugin? _plugin;
  Interpreter? _interpreter;
  List<String> _tfliteLabels = [];

  final List<String> _recentDetections = [];
  static const int _historyMax = 5;

  bool get isReady => _plugin != null;

  Future<void> init() async {
    // 1. Initialize MediaPipe Tracker
    if (_plugin == null) {
      try {
        _plugin = HandLandmarkerPlugin.create(
          numHands: 2,
          minHandDetectionConfidence: 0.6,
          delegate: HandLandmarkerDelegate.gpu,
        );
      } catch (_) {
        // Fallback if already created or on CPU
      }
    }

    // 2. Initialize TFLite Model for Words
    if (_interpreter == null) {
      try {
        _interpreter = await Interpreter.fromAsset('assets/models/isl_model.tflite');
        final jsonString = await rootBundle.loadString('assets/models/labels.json');
        final metadata = jsonDecode(jsonString);
        _tfliteLabels = List<String>.from(metadata['labels']);
      } catch (e) {
        // Handle model load failure
      }
    }
  }

  void processFrame(CameraImage cameraImage, int sensorOrientation) {
    _plugin?.processFrame(cameraImage, sensorOrientation);
  }

  Stream<List<Hand>> get results => _plugin?.landmarkStream ?? const Stream.empty();

  /// Classifies trained word signs (via TFLite) and alphabet fingerspelling (via Rules).
  HandSignDetection? classify(List<Hand> hands, {bool wordsOnly = false, bool alphabetsOnly = false}) {
    if (hands.isEmpty) {
      _recentDetections.clear();
      return null;
    }

    String? rawMatch;
    bool isWord = false;
    double conf = 0.85;

    for (final hand in hands) {
      // --- A. Check Word signs using Trained TFLite Model ---
      if (!alphabetsOnly && _interpreter != null && _tfliteLabels.isNotEmpty) {
        // Flatten 21 3D landmarks into a single array of 63 values (x, y, z for each)
        final inputFeatures = <double>[];
        for (var lm in hand.landmarks) {
          inputFeatures.addAll([lm.x, lm.y, lm.z]);
        }

        // Shape must match the Keras model input layer (1, 63)
        final input = [inputFeatures];
        final output = List.filled(1 * _tfliteLabels.length, 0.0).reshape([1, _tfliteLabels.length]);

        _interpreter!.run(input, output);

        final probabilities = List<double>.from(output[0]);
        double maxConfidence = 0.0;
        int maxIndex = 0;

        for (int i = 0; i < probabilities.length; i++) {
          if (probabilities[i] > maxConfidence) {
            maxConfidence = probabilities[i];
            maxIndex = i;
          }
        }

        // Apply a confidence threshold (e.g., 75%)
        if (maxConfidence > 0.75) {
          rawMatch = _tfliteLabels[maxIndex];
          isWord = true;
          conf = maxConfidence;
        }
      }

      // --- B. Fallback to Geometric Rules for Alphabet Fingerspelling ---
      if (rawMatch == null && !wordsOnly) {
        final state = FingerState.fromHand(hand);
        for (final rule in islLetterRules) {
          if (rule.matches(state)) {
            rawMatch = rule.label;
            isWord = false;
            conf = 0.88;
            break;
          }
        }
      }

      if (rawMatch != null) break;
    }

    if (rawMatch == null) {
      _recentDetections.clear();
      return null;
    }

    // Temporal stabilization filter (prevents flickering)
    _recentDetections.add(rawMatch);
    if (_recentDetections.length > _historyMax) {
      _recentDetections.removeAt(0);
    }

    // Require majority consistency
    final counts = <String, int>{};
    for (final d in _recentDetections) {
      counts[d] = (counts[d] ?? 0) + 1;
    }
    String stableMatch = rawMatch;
    int maxCount = 0;
    counts.forEach((k, v) {
      if (v > maxCount) {
        maxCount = v;
        stableMatch = k;
      }
    });

    if (maxCount < 2 && _recentDetections.length >= 3) {
      return null;
    }

    final en = LocalizationService.translateSign(stableMatch, AppLanguage.en);
    final hi = LocalizationService.translateSign(stableMatch, AppLanguage.hi);
    final mr = LocalizationService.translateSign(stableMatch, AppLanguage.mr);

    return HandSignDetection(
      label: stableMatch,
      confidence: conf,
      english: en,
      hindi: hi,
      marathi: mr,
      isWordSign: isWord,
    );
  }

  void dispose() {
    _plugin?.dispose();
    _plugin = null;
    _interpreter?.close();
  }
}

class FingerState {
  final bool thumb;
  final bool index;
  final bool middle;
  final bool ring;
  final bool pinky;
  final bool thumbIndexPinch;
  final int totalExtended;
  final double wristY;
  final double palmSpan;

  const FingerState({
    required this.thumb,
    required this.index,
    required this.middle,
    required this.ring,
    required this.pinky,
    required this.thumbIndexPinch,
    required this.totalExtended,
    required this.wristY,
    required this.palmSpan,
  });

  factory FingerState.fromHand(Hand hand) {
    final lm = hand.landmarks;
    if (lm.length < 21) {
      return const FingerState(
        thumb: false,
        index: false,
        middle: false,
        ring: false,
        pinky: false,
        thumbIndexPinch: false,
        totalExtended: 0,
        wristY: 0.5,
        palmSpan: 0.0,
      );
    }

    // Extended non-thumb fingers: tip higher than PIP joint (smaller y)
    bool extended(int tipIdx, int pipIdx) => lm[tipIdx].y < lm[pipIdx].y - 0.02;

    final wrist = lm[0];
    final thumbTip = lm[4];
    final thumbIp = lm[3];
    final thumbExtended = (thumbTip.x - wrist.x).abs() > (thumbIp.x - wrist.x).abs() + 0.02;

    final indexExt = extended(8, 6);
    final middleExt = extended(12, 10);
    final ringExt = extended(16, 14);
    final pinkyExt = extended(20, 18);

    final indexTip = lm[8];
    final pinchDist = math.sqrt(
      math.pow(thumbTip.x - indexTip.x, 2) +
          math.pow(thumbTip.y - indexTip.y, 2) +
          math.pow(thumbTip.z - indexTip.z, 2),
    );

    int count = 0;
    if (thumbExtended) count++;
    if (indexExt) count++;
    if (middleExt) count++;
    if (ringExt) count++;
    if (pinkyExt) count++;

    final pinkyTip = lm[20];
    final span = (thumbTip.x - pinkyTip.x).abs();

    return FingerState(
      thumb: thumbExtended,
      index: indexExt,
      middle: middleExt,
      ring: ringExt,
      pinky: pinkyExt,
      thumbIndexPinch: pinchDist < 0.06,
      totalExtended: count,
      wristY: wrist.y,
      palmSpan: span,
    );
  }
}

class SignRule {
  final String label;
  final bool Function(FingerState state) matches;
  const SignRule(this.label, this.matches);
}

/// On-Device rules for the 7 trained ISL words + common gestures.
final List<SignRule> islWordRules = [
  // 1. HELP: Open hand raised high in upper area of camera
  SignRule('HELP', (s) => s.totalExtended >= 4 && s.wristY < 0.42),

  // 2. HELLO: Open palm upright in mid-high position
  SignRule('HELLO', (s) => s.totalExtended >= 4 && s.wristY >= 0.42 && s.wristY <= 0.65),

  // 3. PLEASE: Open hand held lower / flat palm
  SignRule('PLEASE', (s) => s.totalExtended >= 4 && s.wristY > 0.65),

  // 4. THANK_YOU: Thumb & 4 fingers extended with pinch or hand raised
  SignRule('THANK_YOU', (s) => (s.index && s.middle && s.ring && s.wristY < 0.48 && !s.pinky)),

  // 5. YES: Thumbs up (only thumb extended) or closed fist
  SignRule('YES', (s) => (s.thumb && !s.index && !s.middle && !s.ring && !s.pinky) || s.totalExtended == 0),

  // 6. NO: Index finger alone extended (pointing/shaking)
  SignRule('NO', (s) => s.index && !s.middle && !s.ring && !s.pinky && !s.thumb),

  // 7. SORRY: Closed fist with thumb wrapped across
  SignRule('SORRY', (s) => s.totalExtended == 0 && s.wristY < 0.60),

  // OK gesture
  SignRule('OK', (s) => s.thumbIndexPinch && s.middle && s.ring && s.pinky),

  // VICTORY / Peace
  SignRule('VICTORY / PEACE', (s) => !s.thumb && s.index && s.middle && !s.ring && !s.pinky),

  // I LOVE YOU (thumb, index, pinky)
  SignRule('I LOVE YOU', (s) => s.thumb && s.index && !s.middle && !s.ring && s.pinky),
];

/// ISL Alphabet Fingerspelling Rules.
final List<SignRule> islLetterRules = [
  // A — closed fist with thumb straight up alongside
  SignRule('A', (s) => s.thumb && !s.index && !s.middle && !s.ring && !s.pinky),

  // B — four fingers extended together, thumb tucked across palm
  SignRule('B', (s) => s.index && s.middle && s.ring && s.pinky && !s.thumb),

  // D — index finger alone extended
  SignRule('D', (s) => s.index && !s.middle && !s.ring && !s.pinky && !s.thumb),

  // F — thumb and index pinch, other 3 extended
  SignRule('F', (s) => s.thumbIndexPinch && !s.index && s.middle && s.ring && s.pinky),

  // I — pinky alone extended
  SignRule('I', (s) => s.pinky && !s.index && !s.middle && !s.ring && !s.thumb),

  // K — index and middle extended and spread, thumb between
  SignRule('K', (s) => s.index && s.middle && s.thumb && !s.ring && !s.pinky),

  // L — thumb and index in an L shape
  SignRule('L', (s) => s.thumb && s.index && !s.middle && !s.ring && !s.pinky),

  // U — index and middle extended together
  SignRule('U', (s) => s.index && s.middle && !s.ring && !s.pinky && !s.thumb),

  // V — index and middle spread ("peace sign")
  SignRule('V', (s) => s.index && s.middle && !s.thumb && !s.ring && !s.pinky),

  // W — index, middle, ring extended
  SignRule('W', (s) => s.index && s.middle && s.ring && !s.pinky && !s.thumb),

  // Y — thumb and pinky extended ("hang loose")
  SignRule('Y', (s) => s.thumb && s.pinky && !s.index && !s.middle && !s.ring),
];
