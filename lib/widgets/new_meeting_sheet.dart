import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum NewMeetingChoice { createForLater, startInstant, schedule }

/// Google Meet styled "New Meeting" sheet.
Future<NewMeetingChoice?> showNewMeetingSheet(BuildContext context) {
  return showModalBottomSheet<NewMeetingChoice>(
    context: context,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _option(
                context,
                icon: Icons.link_rounded,
                label: 'Get a meeting link to share',
                subtitle: 'Generate a joinable link for later',
                choice: NewMeetingChoice.createForLater,
              ),
              _option(
                context,
                icon: Icons.videocam_rounded,
                label: 'Start an instant meeting',
                subtitle: 'Join immediately and invite others',
                choice: NewMeetingChoice.startInstant,
              ),
              _option(
                context,
                icon: Icons.calendar_month_rounded,
                label: 'Schedule a meeting',
                subtitle: 'Pick date & time to create invite link',
                choice: NewMeetingChoice.schedule,
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _option(
  BuildContext context, {
  required IconData icon,
  required String label,
  required NewMeetingChoice choice,
  String? subtitle,
}) {
  return ListTile(
    leading: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.navy.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: AppColors.navy, size: 22),
    ),
    title: Text(label,
        style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600)),
    subtitle: subtitle != null
        ? Text(subtitle,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12))
        : null,
    onTap: () => Navigator.of(context).pop(choice),
  );
}
