import 'package:flutter/material.dart';
import '../services/localization_service.dart';
import '../services/preferences_service.dart';
import '../services/tts_service.dart';

/// The three "Receiver-Dependent" viewing modes.
/// The whole UI (Home Dashboard + Meet screen) reconfigures around this.
enum SensoryProfile { deaf, blind, general }

extension SensoryProfileX on SensoryProfile {
  String localizedLabel(AppLanguage lang) {
    switch (this) {
      case SensoryProfile.deaf:
        return LocalizationService.tr('profile_deaf_label', lang);
      case SensoryProfile.blind:
        return LocalizationService.tr('profile_blind_label', lang);
      case SensoryProfile.general:
        return LocalizationService.tr('profile_general_label', lang);
    }
  }

  String localizedDescription(AppLanguage lang) {
    switch (this) {
      case SensoryProfile.deaf:
        return LocalizationService.tr('profile_deaf_desc', lang);
      case SensoryProfile.blind:
        return LocalizationService.tr('profile_blind_desc', lang);
      case SensoryProfile.general:
        return LocalizationService.tr('profile_general_desc', lang);
    }
  }

  String get label => localizedLabel(AppLanguage.en);
  String get description => localizedDescription(AppLanguage.en);

  IconData get icon {
    switch (this) {
      case SensoryProfile.deaf:
        return Icons.accessibility_new_rounded;
      case SensoryProfile.blind:
        return Icons.visibility_off_rounded;
      case SensoryProfile.general:
        return Icons.person_rounded;
    }
  }
}

/// Who gets let into a meeting automatically vs. who needs the host's
/// explicit approval first.
enum AdmissionMode { allowAll, alwaysAsk }

extension AdmissionModeX on AdmissionMode {
  String localizedLabel(AppLanguage lang) {
    switch (this) {
      case AdmissionMode.allowAll:
        return LocalizationService.tr('admission_allow_all', lang);
      case AdmissionMode.alwaysAsk:
        return LocalizationService.tr('admission_ask', lang);
    }
  }

  String localizedDescription(AppLanguage lang) {
    switch (this) {
      case AdmissionMode.allowAll:
        return LocalizationService.tr('admission_allow_all_desc', lang);
      case AdmissionMode.alwaysAsk:
        return LocalizationService.tr('admission_ask_desc', lang);
    }
  }

  String get label => localizedLabel(AppLanguage.en);
  String get description => localizedDescription(AppLanguage.en);
}

/// Persistent app-wide state (profile + accessibility toggles + language).
class AppState extends ChangeNotifier {
  SensoryProfile? _profile;
  bool _hasChosenProfile = false;
  AppLanguage _language = AppLanguage.en;
  AppLanguage _speechLanguage = AppLanguage.en;
  bool forceTextToSpeech = false;
  bool autoReadScreen = false;
  AdmissionMode admissionMode = AdmissionMode.allowAll;

  AppState() {
    initFromPreferences();
  }

  void initFromPreferences() {
    final prefs = PreferencesService.instance;
    _hasChosenProfile = prefs.hasChosenProfile;

    if (prefs.savedProfile != null) {
      _profile = SensoryProfile.values.firstWhere(
        (p) => p.name == prefs.savedProfile,
        orElse: () => SensoryProfile.general,
      );
    }

    _language = AppLanguage.values.firstWhere(
      (l) => l.code == prefs.savedLanguage,
      orElse: () => AppLanguage.en,
    );
    _speechLanguage = _language;

    forceTextToSpeech = prefs.forceTextToSpeech;
    autoReadScreen = prefs.autoReadScreen;
    admissionMode = AdmissionMode.values.firstWhere(
      (m) => m.name == prefs.admissionMode,
      orElse: () => AdmissionMode.allowAll,
    );
  }

  SensoryProfile? get profile => _profile;
  bool get hasChosenProfile => _hasChosenProfile;
  AppLanguage get language => _language;
  AppLanguage get speechLanguage => _speechLanguage;

  String tr(String key) => LocalizationService.tr(key, _language);

  void setLanguage(AppLanguage newLanguage) {
    if (_language == newLanguage) return;
    _language = newLanguage;
    _speechLanguage = newLanguage;
    PreferencesService.instance.setLanguage(newLanguage.code);
    TtsService.instance.setLanguage(newLanguage.ttsLocale);
    notifyListeners();
  }

  void setSpeechLanguage(AppLanguage newSpeechLanguage) {
    _speechLanguage = newSpeechLanguage;
    notifyListeners();
  }

  void setProfile(SensoryProfile profile) {
    _profile = profile;
    _hasChosenProfile = true;
    PreferencesService.instance.setProfile(profile.name);

    // Blind profile defaults to always-on TTS since there is no visual fallback.
    if (profile == SensoryProfile.blind) {
      forceTextToSpeech = true;
      autoReadScreen = true;
      PreferencesService.instance.setForceTts(true);
      PreferencesService.instance.setAutoReadScreen(true);
    }
    notifyListeners();
  }

  void toggleForceTts(bool value) {
    forceTextToSpeech = value;
    PreferencesService.instance.setForceTts(value);
    notifyListeners();
  }

  void toggleAutoReadScreen(bool value) {
    autoReadScreen = value;
    PreferencesService.instance.setAutoReadScreen(value);
    notifyListeners();
  }

  void setAdmissionMode(AdmissionMode mode) {
    admissionMode = mode;
    PreferencesService.instance.setAdmissionMode(mode.name);
    notifyListeners();
  }
}
