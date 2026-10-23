import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sensory_profile.dart';
import '../services/localization_service.dart';
import '../theme/app_colors.dart';
import 'profile_selector.dart';

List<String> profileScreenLabels(AppState appState) {
  final lang = appState.language;
  final profile = appState.profile ?? SensoryProfile.general;
  return [
    LocalizationService.tr('nav_profile', lang),
    '${appState.tr('current_mode')} ${profile.localizedLabel(lang)}',
    profile.localizedDescription(lang),
    appState.tr('change_profile'),
  ];
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final lang = appState.language;
    final profile = appState.profile ?? SensoryProfile.general;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          appState.tr('nav_profile'),
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.navy,
                    child: Icon(profile.icon, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${appState.tr('current_mode')} ${profile.localizedLabel(lang)}',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profile.localizedDescription(lang),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileSelectorScreen()),
              ),
              icon: const Icon(Icons.swap_horiz, color: AppColors.navy),
              label: Text(
                appState.tr('change_profile'),
                style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
