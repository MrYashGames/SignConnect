import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sensory_profile.dart';
import '../services/localization_service.dart';
import '../services/stt_service.dart';
import '../theme/app_colors.dart';
import 'profile_selector.dart';

List<String> settingsScreenLabels(AppState appState) {
  final lang = appState.language;
  final profileLabel = appState.profile?.localizedLabel(lang) ?? '';
  return [
    LocalizationService.tr('nav_options', lang),
    '${LocalizationService.tr('settings_language_section', lang)}: ${lang.displayName}',
    '${LocalizationService.tr('settings_profile_section', lang)}: $profileLabel',
    '${LocalizationService.tr('settings_force_tts', lang)} ${appState.forceTextToSpeech ? "on" : "off"}',
    '${LocalizationService.tr('settings_autoread', lang)} ${appState.autoReadScreen ? "on" : "off"}',
    '${LocalizationService.tr('settings_admission', lang)}: ${appState.admissionMode.localizedLabel(lang)}',
  ];
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final currentLang = appState.language;
    final currentProfile = appState.profile ?? SensoryProfile.general;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          appState.tr('nav_options'),
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // --- Language Selection Section ---
          Text(
            appState.tr('settings_language_section'),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            appState.tr('settings_language_desc'),
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: AppLanguage.values.map((lang) {
                final isSelected = lang == currentLang;
                return InkWell(
                  onTap: () {
                    appState.setLanguage(lang);
                    SttService.instance.setLanguage(lang);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                          color: isSelected ? AppColors.navy : AppColors.textSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          lang.displayName,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.navy.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Active',
                              style: TextStyle(color: AppColors.navy, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 24),

          // --- Sensory Profile Section ---
          Text(
            appState.tr('settings_profile_section'),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.navy.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        currentProfile.icon,
                        color: AppColors.navy,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentProfile.localizedLabel(currentLang),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currentProfile.localizedDescription(currentLang),
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ProfileSelectorScreen(),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.navy,
                      side: const BorderSide(color: AppColors.navy, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.swap_horiz, size: 20),
                    label: Text(
                      appState.tr('settings_change_profile_btn'),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // --- 100% On-Device AI Engine Section ---
          Text(
            appState.tr('settings_on_device_title'),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            appState.tr('settings_on_device_desc'),
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                _aiFeatureRow(
                  icon: Icons.front_hand,
                  title: 'ISL Sign Recognition',
                  subtitle: 'MediaPipe Landmark Engine (100% On-Device)',
                  active: true,
                ),
                const Divider(height: 20),
                _aiFeatureRow(
                  icon: Icons.record_voice_over,
                  title: 'Text → Speech (TTS)',
                  subtitle: 'English, हिन्दी, मराठी native voice engine',
                  active: true,
                ),
                const Divider(height: 20),
                _aiFeatureRow(
                  icon: Icons.mic,
                  title: 'Audio → Text (STT)',
                  subtitle: 'Real-time on-device speech recognizer',
                  active: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // --- Accessibility Toggles ---
          _toggleCard(
            title: appState.tr('settings_force_tts'),
            subtitle: appState.tr('settings_force_tts_desc'),
            value: appState.forceTextToSpeech,
            onChanged: appState.toggleForceTts,
          ),
          const SizedBox(height: 14),
          _toggleCard(
            title: appState.tr('settings_autoread'),
            subtitle: appState.tr('settings_autoread_desc'),
            value: appState.autoReadScreen,
            onChanged: appState.toggleAutoReadScreen,
          ),

          const SizedBox(height: 24),

          // --- Meeting Admission Section ---
          Text(
            appState.tr('settings_admission'),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ...AdmissionMode.values.map((mode) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _admissionCard(
                  title: mode.localizedLabel(currentLang),
                  description: mode.localizedDescription(currentLang),
                  selected: appState.admissionMode == mode,
                  onTap: () => appState.setAdmissionMode(mode),
                ),
              )),
        ],
      ),
    );
  }

  Widget _aiFeatureRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool active,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: active ? Colors.green.withValues(alpha: 0.12) : AppColors.textSecondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: active ? Colors.green : AppColors.textSecondary, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt, color: Colors.green, size: 14),
              SizedBox(width: 2),
              Text(
                'Ready',
                style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _admissionCard({
    required String title,
    required String description,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$title. $description',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.navy : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: selected ? AppColors.navy : AppColors.textSecondary,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toggleCard({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.navy,
          ),
        ],
      ),
    );
  }
}

