import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';

/// Wraps flutter_tts with real-time word tracking and multilingual (English, Hindi, Marathi) support.
class TtsService {
  TtsService._internal();
  static final TtsService instance = TtsService._internal();

  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _player = AudioPlayer();
  bool _initialized = false;
  String _currentLanguage = 'en-IN';

  void Function(String word, int start, int end)? _onWord;
  void Function()? _onStart;
  void Function()? _onComplete;

  String get currentLanguage => _currentLanguage;

  Future<void> init() async {
    if (_initialized) return;
    try {
      await _tts.setLanguage(_currentLanguage);
      await _tts.setSpeechRate(0.5);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);

      _tts.setProgressHandler((String text, int start, int end, String word) {
        _onWord?.call(word, start, end);
      });

      _tts.setStartHandler(() {
        _onStart?.call();
      });

      _tts.setCompletionHandler(() {
        _onComplete?.call();
      });

      _tts.setCancelHandler(() {
        _onComplete?.call();
      });

      _initialized = true;
    } catch (_) {
      // Fallback if some handlers aren't supported on desktop
      _initialized = true;
    }
  }

  void setHandlers({
    void Function(String word, int start, int end)? onWord,
    void Function()? onStart,
    void Function()? onComplete,
  }) {
    _onWord = onWord;
    _onStart = onStart;
    _onComplete = onComplete;
  }

  /// Speak a single piece of text (interrupts anything currently speaking).
  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    await init();
    await _tts.stop();
    await _tts.speak(text);
  }

  /// Reads out the full visible text of the current screen.
  Future<void> readScreenText(List<String> visibleLabels) async {
    final combined = visibleLabels.where((s) => s.trim().isNotEmpty).join('. ');
    await speak(combined);
  }

  Future<void> stop() async {
    await _tts.stop();
    _onComplete?.call();
  }

  Future<void> setLanguage(String bcp47Tag) async {
    _currentLanguage = bcp47Tag;
    await init();
    await _tts.setLanguage(bcp47Tag);
  }

  Future<void> setRate(double rate) => _tts.setSpeechRate(rate);

  Future<void> setPitch(double pitch) => _tts.setPitch(pitch);

  /// Synthesizes text to a real audio file
  Future<String> synthesizeToFile(String text) async {
    if (text.trim().isEmpty) {
      throw ArgumentError('Cannot synthesize empty text');
    }
    await init();
    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'signconnect_tts_${DateTime.now().millisecondsSinceEpoch}.wav';

    await _tts.awaitSynthCompletion(true);
    final result = await _tts.synthesizeToFile(text, fileName);
    if (result != 1) {
      throw Exception('flutter_tts failed to synthesize to file (code $result)');
    }
    return '${dir.path}/$fileName';
  }

  /// Plays back a file created by [synthesizeToFile].
  Future<void> playFile(String path) async {
    await _player.stop();
    await _player.play(DeviceFileSource(path));
  }

  Future<void> stopPlayback() => _player.stop();

  /// Deletes an audio file created by [synthesizeToFile].
  Future<void> deleteFile(String path) async {
    final file = File(path);
    if (await file.exists()) await file.delete();
  }
}
