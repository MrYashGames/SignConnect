import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'localization_service.dart';

/// Wraps speech_to_text for real-time speech recognition in English, Hindi, and Marathi.
class SttService {
  SttService._internal();
  static final SttService instance = SttService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _available = false;
  bool _userRequestedStop = true;
  String? _localeId;
  AppLanguage _currentLanguage = AppLanguage.en;

  void Function(String text, bool isFinal)? _onResult;
  void Function(String errorMessage)? _onError;

  bool get isListening => _speech.isListening;
  bool get isAvailable => _available;
  String? get currentLocaleId => _localeId;
  AppLanguage get currentLanguage => _currentLanguage;

  Future<bool> init() async {
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      _onError?.call('Microphone permission was denied.');
      return false;
    }

    _available = await _speech.initialize(
      onError: (SpeechRecognitionError e) {
        _onError?.call(e.errorMsg);
        _maybeRestart();
      },
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          _maybeRestart();
        }
      },
    );

    if (_available) {
      await setLanguage(_currentLanguage);
    }
    return _available;
  }

  Future<void> setLanguage(AppLanguage lang) async {
    _currentLanguage = lang;
    if (!_available) {
      await init();
      if (!_available) return;
    }

    try {
      final locales = await _speech.locales();
      final targetPrefix = switch (lang) {
        AppLanguage.mr => 'mr',
        AppLanguage.hi => 'hi',
        AppLanguage.en => 'en',
      };

      final matched = locales.firstWhere(
        (l) => l.localeId.toLowerCase().startsWith(targetPrefix),
        orElse: () => locales.firstWhere(
          (l) => l.localeId.toLowerCase().contains(targetPrefix),
          orElse: () => locales.isNotEmpty ? locales.first : stt.LocaleName('en_IN', 'English (India)'),
        ),
      );

      _localeId = matched.localeId;
    } catch (_) {
      _localeId = lang.sttLocale;
    }
  }

  Future<List<stt.LocaleName>> availableLocales() async {
    if (!_available) await init();
    return _speech.locales();
  }

  void setLocale(String localeId) {
    _localeId = localeId;
  }

  void _maybeRestart() {
    if (_userRequestedStop || _onResult == null) return;
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!_userRequestedStop && !_speech.isListening) {
        _listenOnce();
      }
    });
  }

  Future<void> _listenOnce() async {
    await _speech.listen(
      onResult: (result) {
        _onResult?.call(result.recognizedWords, result.finalResult);
      },
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
        partialResults: true,
        cancelOnError: false,
        autoPunctuation: true,
        localeId: _localeId,
        pauseFor: const Duration(seconds: 8),
        listenFor: const Duration(minutes: 5),
      ),
    );
  }

  /// Starts real-time listening with continuous word detection
  Future<void> startListening({
    required void Function(String text, bool isFinal) onResult,
    void Function(String errorMessage)? onError,
  }) async {
    _onResult = onResult;
    _onError = onError;
    _userRequestedStop = false;

    if (!_available) {
      final ok = await init();
      if (!ok) return;
    }
    await _listenOnce();
  }

  Future<void> stopListening() async {
    _userRequestedStop = true;
    await _speech.stop();
  }
}
