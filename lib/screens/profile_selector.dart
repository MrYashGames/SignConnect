import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sensory_profile.dart';
import '../services/localization_service.dart';
import '../services/tts_service.dart';
import '../theme/app_colors.dart';
import 'main_shell.dart';

class ProfileSelectorScreen extends StatelessWidget {
  const ProfileSelectorScreen({super.key});

  void _choose(BuildContext context, SensoryProfile p) {
    final appState = context.read<AppState>();
    appState.setProfile(p);
    final lang = appState.language;
    TtsService.instance.setLanguage(lang.ttsLocale);
    TtsService.instance.speak('${p.localizedLabel(lang)} ${appState.tr('current_mode')}');

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final lang = appState.language;
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: canPop,
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          PopupMenuButton<AppLanguage>(
            tooltip: 'Language / भाषा',
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.navy.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.navy.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.language, size: 16, color: AppColors.navy),
                  const SizedBox(width: 4),
                  Text(
                    lang.shortName,
                    style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
            ),
            onSelected: (AppLanguage selected) {
              appState.setLanguage(selected);
            },
            itemBuilder: (BuildContext context) => AppLanguage.values.map((item) {
              final isCurrent = item == lang;
              return PopupMenuItem<AppLanguage>(
                value: item,
                child: Row(
                  children: [
                    Text(
                      item.displayName,
                      style: TextStyle(
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isCurrent ? AppColors.navy : AppColors.textPrimary,
                      ),
                    ),
                    if (isCurrent) ...[
                      const Spacer(),
                      const Icon(Icons.check, size: 16, color: AppColors.navy),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appState.tr('welcome_title'),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                appState.tr('choose_experience'),
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: ListView(
                  children: SensoryProfile.values.map((p) {
                    final label = p.localizedLabel(lang);
                    final desc = p.localizedDescription(lang);

                    return Semantics(
                      button: true,
                      label: '$label. $desc',
                      child: GestureDetector(
                        onTap: () => _choose(context, p),
                        onLongPress: () {
                          TtsService.instance.setLanguage(lang.ttsLocale);
                          TtsService.instance.speak('$label. $desc');
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 18),
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.navy,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(p.icon, size: 28, color: Colors.white),
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      label,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 19,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      desc,
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
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
