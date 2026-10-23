import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class PreferencesService {
  PreferencesService._internal();
  static final PreferencesService instance = PreferencesService._internal();

  File? _file;
  Map<String, dynamic> _data = {};
  bool _initialized = false;

  bool get isInitialized => _initialized;

  Future<void> init() async {
    if (_initialized) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      _file = File('${dir.path}/signconnect_prefs.json');
      if (await _file!.exists()) {
        final content = await _file!.readAsString();
        if (content.trim().isNotEmpty) {
          _data = jsonDecode(content) as Map<String, dynamic>;
        }
      }
    } catch (_) {
      _data = {};
    }
    _initialized = true;
  }

  bool get hasChosenProfile => _data['hasChosenProfile'] as bool? ?? false;
  String? get savedProfile => _data['profile'] as String?;
  String get savedLanguage => _data['language'] as String? ?? 'en';
  bool get forceTextToSpeech => _data['forceTextToSpeech'] as bool? ?? false;
  bool get autoReadScreen => _data['autoReadScreen'] as bool? ?? false;
  String get admissionMode => _data['admissionMode'] as String? ?? 'allowAll';

  Future<void> setHasChosenProfile(bool value) async {
    _data['hasChosenProfile'] = value;
    await _save();
  }

  Future<void> setProfile(String profileKey) async {
    _data['profile'] = profileKey;
    _data['hasChosenProfile'] = true;
    await _save();
  }

  Future<void> setLanguage(String langCode) async {
    _data['language'] = langCode;
    await _save();
  }

  Future<void> setForceTts(bool value) async {
    _data['forceTextToSpeech'] = value;
    await _save();
  }

  Future<void> setAutoReadScreen(bool value) async {
    _data['autoReadScreen'] = value;
    await _save();
  }

  Future<void> setAdmissionMode(String modeKey) async {
    _data['admissionMode'] = modeKey;
    await _save();
  }

  Future<void> _save() async {
    try {
      if (_file != null) {
        await _file!.writeAsString(jsonEncode(_data));
      }
    } catch (_) {}
  }
}
