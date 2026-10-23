import 'package:flutter/material.dart';
import '../services/tts_service.dart';
import '../theme/app_colors.dart';

/// A massive, high-contrast tile used on the Home Dashboard.
/// Wrapped in Semantics so native screen readers (TalkBack/VoiceOver) announce
/// it correctly, and also speaks its own label via TTS on long-press —
/// useful as an in-app fallback / for the Blind profile's "tap anywhere for
/// audio feedback" behaviour.
class ActionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const ActionTile({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tileColor = color ?? AppColors.card;

    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: () => TtsService.instance.speak(label),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          decoration: BoxDecoration(
            color: tileColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.navy,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 26, color: Colors.white),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
