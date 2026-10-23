import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../models/sensory_profile.dart';
import '../../services/hand_sign_service.dart';
import '../../services/localization_service.dart';
import '../../services/tts_service.dart';
import '../../theme/app_colors.dart';

enum SignMode {
  words, // Trained Deep Learning Model: isl_model.keras & isl_metadata.pkl
  alphabets, // Fingerspelling letters: A, B, D, F, I, K, L, V, W, Y
}

class SignRecognitionScreen extends StatefulWidget {
  const SignRecognitionScreen({super.key});

  @override
  State<SignRecognitionScreen> createState() => _SignRecognitionScreenState();
}

class _SignRecognitionScreenState extends State<SignRecognitionScreen> {
  CameraController? _controller;
  bool _cameraReady = false;
  String? _cameraError;

  SignMode _mode = SignMode.words;
  HandSignDetection? _lastDetection;
  int _handsDetected = 0;
  final List<String> _sentenceBuilder = [];

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    await HandSignService.instance.init();

    //Listen to on-device MediaPipe results (100% on-phone, zero server)
    HandSignService.instance.results.listen((hands) {
      if (!mounted) return;
      final detection = HandSignService.instance.classify(
      hands,
      wordsOnly: _mode == SignMode.words,
      alphabetsOnly: _mode == SignMode.alphabets,
      );

      setState(() {
      _handsDetected = hands.length;
if (detection != null) {
_lastDetection = detection;
  }
          });
  });

    await _initCamera();
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) setState(() => _cameraError = 'Camera permission was denied.');
      return;
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _cameraError = 'No camera found on this device.');
        return;
      }
      final frontOrFirst = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        frontOrFirst,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _controller!.initialize();
      if (!mounted) return;
      setState(() => _cameraReady = true);

      // Start on-device frame stream to MediaPipe native plugin
      await _controller!.startImageStream((image) {
        HandSignService.instance.processFrame(
          image,
          _controller!.description.sensorOrientation,
        );
      });
    } catch (e) {
      if (mounted) setState(() => _cameraError = 'Could not start camera: $e');
    }
  }

void _switchMode(SignMode mode) {
  if (_mode == mode) return;
  setState(() {
    _mode = mode;
    _lastDetection = null;
  });
}

void _addSignToSentence() {
if (_lastDetection == null) return;
final appState = context.read<AppState>();
final word = _lastDetection!.localized(appState.language);
setState(() => _sentenceBuilder.add(word));
}

void _backspace() {
  if (_sentenceBuilder.isEmpty) return;
  setState(() => _sentenceBuilder.removeLast());
}

  void _clearSentence() => setState(() => _sentenceBuilder.clear());

void _speakSentence() {
if (_sentenceBuilder.isEmpty) return;
final appState = context.read<AppState>();
TtsService.instance.setLanguage(appState.language.ttsLocale);
TtsService.instance.speak(_sentenceBuilder.join(' '));
}

void _testSign(String signKey) {
final en = LocalizationService.translateSign(signKey, AppLanguage.en);
final hi = LocalizationService.translateSign(signKey, AppLanguage.hi);
final mr = LocalizationService.translateSign(signKey, AppLanguage.mr);

setState(() {
  _lastDetection = HandSignDetection(
    label: signKey,
    confidence: 0.95,
    english: en,
    hindi: hi,
    marathi: mr,
    isWordSign: true,
  );
});
}

  @override
  void dispose() {
    _controller?.stopImageStream();
    _controller?.dispose();
    HandSignService.instance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final lang = appState.language;

    final displayLabel = _lastDetection != null ? _lastDetection!.localized(lang) : '—';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with On-Device Badge
          Row(
            children: [
              Expanded(
                child: Text(
                  appState.tr('sign_title'),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green, width: 1),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.offline_bolt_rounded, size: 14, color: Colors.green),
                    SizedBox(width: 4),
                    Text(
                      ' On-Device sign recognition',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

    // Mode Selector (Words vs Alphabets)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _switchMode(SignMode.words),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _mode == SignMode.words ? AppColors.navy : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'ISL Words (Trained Signs)',
                        style: TextStyle(
                          color: _mode == SignMode.words ? Colors.white : AppColors.textPrimary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _switchMode(SignMode.alphabets),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _mode == SignMode.alphabets ? AppColors.navy : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'ISL Alphabets (Letters)',
                        style: TextStyle(
                          color: _mode == SignMode.alphabets ? Colors.white : AppColors.textPrimary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Camera Viewport
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(22),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildCameraArea(),
              // Tracking Status Overlay
              Positioned(
                bottom: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(10),
                      ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _handsDetected > 0 ? Icons.check_circle_rounded : Icons.pan_tool_outlined,
                        size: 14,
                        color: _handsDetected > 0 ? const Color(0xFF00E5C7) : Colors.white70,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _handsDetected > 0 ? '$_handsDetected Hand(s) Tracked' : 'Show your hand to camera',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                 ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Real-time Recognition Box with English, Hindi, and Marathi
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _lastDetection != null ? AppColors.navy.withValues(alpha: 0.3) : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appState.tr('sign_detected'),
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          displayLabel,
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    if (_lastDetection != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${(_lastDetection!.confidence * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.volume_up_rounded, color: AppColors.navy),
                      onPressed: () {
                        if (displayLabel != '—') {
                          TtsService.instance.setLanguage(lang.ttsLocale);
                          TtsService.instance.speak(displayLabel);
                        }
                      },
                    ),
                    ElevatedButton(
                      onPressed: _addSignToSentence,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navy,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      child: Text(appState.tr('sign_add_btn')),
                    ),
                  ],
                ),

                // Multi-Language Translation Chips
                if (_lastDetection != null) ...[
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _translationPill('English', _lastDetection!.english, lang == AppLanguage.en),
                      _translationPill('हिन्दी', _lastDetection!.hindi, lang == AppLanguage.hi),
                      _translationPill('मराठी', _lastDetection!.marathi, lang == AppLanguage.mr),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 10),

          // --- Sentence Builder ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _sentenceBuilder.isEmpty ? appState.tr('sign_spell_placeholder') : _sentenceBuilder.join(' '),
                    style: TextStyle(
                      color: _sentenceBuilder.isEmpty ? AppColors.textSecondary : AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.backspace_outlined, size: 20, color: AppColors.textSecondary),
                  onPressed: _backspace,
                ),
                IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 20, color: AppColors.textSecondary),
                  onPressed: _clearSentence,
                ),
                ElevatedButton.icon(
                  onPressed: _speakSentence,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: const Icon(Icons.volume_up_rounded, size: 16),
                  label: Text(appState.tr('sign_speak_sentence')),
                ),
              ],
            ),
          ),

          // Quick Sign Test Chips
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text('Try signs: ', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                ...['HELLO', 'THANK_YOU', 'PLEASE', 'HELP', 'YES', 'NO', 'SORRY'].map(
                      (s) => Padding(
                    padding: const EdgeInsets.only(right: 5),
                    child: InkWell(
                      onTap: () => _testSign(s),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Text(
                          LocalizationService.translateSign(s, lang),
                          style: const TextStyle(fontSize: 11, color: AppColors.navy, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _translationPill(String title, String value, bool isCurrent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: isCurrent ? AppColors.navy.withValues(alpha: 0.12) : AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isCurrent ? AppColors.navy : Colors.black12),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
          const SizedBox(height: 1),
          Text(
            value.isNotEmpty ? value : '—',
            style: TextStyle(
              color: isCurrent ? AppColors.navy : AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraArea() {
    if (_cameraError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            _cameraError!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      );
    }
    if (!_cameraReady || _controller == null) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    return CameraPreview(_controller!);
  }
}

