import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/sensory_profile.dart';
import '../services/localization_service.dart';
import '../services/tts_service.dart';
import '../theme/app_colors.dart';
import '../widgets/new_meeting_sheet.dart';
import 'features_hub_screen.dart';
import 'meet_screen.dart';
import 'profile_selector.dart';

const _uuid = Uuid();
String _generateRoomCode() => 'signconnect-${_uuid.v4().substring(0, 8)}';

List<String> homeScreenLabels(AppState appState) {
  final lang = appState.language;
  final profile = appState.profile ?? SensoryProfile.general;
  return [
    LocalizationService.tr('nav_home', lang),
    '${appState.tr('current_mode')} ${profile.localizedLabel(lang)}',
    appState.tr('tools_title'),
    appState.tr('start_meet'),
    appState.tr('join_code'),
    appState.tr('saved_contacts'),
  ];
}

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  final TextEditingController _codeController = TextEditingController();

  Future<void> _readScreen() async {
    final appState = context.read<AppState>();
    await TtsService.instance.readScreenText(homeScreenLabels(appState));
  }

  void _openMeet(String channelName, {required bool isHost}) {
    // Sanitize in case a full URL was passed
    String cleanCode = channelName.trim();
    if (cleanCode.contains('code=')) {
      try {
        final uri = Uri.parse(cleanCode);
        cleanCode = uri.queryParameters['code'] ?? cleanCode;
      } catch (_) {}
    } else if (cleanCode.contains('/')) {
      cleanCode = cleanCode.split('/').last;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MeetScreen(channelName: cleanCode, isHost: isHost),
      ),
    );
  }

  Future<void> _startNewMeetFlow() async {
    final choice = await showNewMeetingSheet(context);
    if (choice == null || !mounted) return;

    final code = _generateRoomCode();

    switch (choice) {
      case NewMeetingChoice.startInstant:
        _openMeet(code, isHost: true);
        break;

      case NewMeetingChoice.createForLater:
        _showCreatedLinkDialog(code, isScheduled: false);
        break;

      case NewMeetingChoice.schedule:
        _scheduleMeetingFlow(code);
        break;
    }
  }

  Future<void> _scheduleMeetingFlow(String code) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
    );
    if (time == null || !mounted) return;

    final scheduledDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    _showCreatedLinkDialog(code, isScheduled: true, scheduledTime: scheduledDateTime);
  }

  void _showCreatedLinkDialog(String code, {required bool isScheduled, DateTime? scheduledTime}) {
    final link = 'https://signconnect.app/meet?code=$code';
    final appState = context.read<AppState>();

    String title = isScheduled ? 'Meeting Scheduled!' : 'Here is your meeting link';
    String timeInfo = '';
    if (scheduledTime != null) {
      timeInfo = 'Scheduled for: ${scheduledTime.day}/${scheduledTime.month}/${scheduledTime.year} at ${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}\n\n';
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.link_rounded, color: AppColors.navy),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${timeInfo}Send this invite link so participants can tap and join directly in the SignConnect app:',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      link,
                      style: const TextStyle(color: AppColors.navy, fontSize: 13, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, color: AppColors.navy, size: 20),
                    tooltip: 'Copy link',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: link));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Meeting link copied to clipboard!')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Meeting Code: $code',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(appState.tr('close_btn'), style: const TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _openMeet(code, isHost: true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: Text(appState.tr('start_now')),
          ),
        ],
      ),
    );
  }

  void _joinWithCode() {
    final appState = context.read<AppState>();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(appState.tr('join_code'), style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the meeting code or paste the full meeting link to join:',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _codeController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'e.g. signconnect-12345678 or link',
                hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.keyboard_alt_outlined, color: AppColors.navy),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(appState.tr('close_btn'), style: const TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final text = _codeController.text.trim();
              if (text.isEmpty) return;
              Navigator.pop(context);
              _codeController.clear();
              _openMeet(text, isHost: false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(appState.tr('join_btn')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final profile = appState.profile ?? SensoryProfile.general;
    final currentLang = appState.language;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.sign_language_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              appState.tr('app_name'),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          // Language Selector Dropdown
          PopupMenuButton<AppLanguage>(
            tooltip: 'Language / भाषा बदला',
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.translate_rounded, size: 16, color: AppColors.navy),
                  const SizedBox(width: 4),
                  Text(
                    currentLang.shortName,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            onSelected: (AppLanguage selected) {
              appState.setLanguage(selected);
            },
            itemBuilder: (BuildContext context) => AppLanguage.values.map((lang) {
              final isCurrent = lang == currentLang;
              return PopupMenuItem<AppLanguage>(
                value: lang,
                child: Row(
                  children: [
                    Text(
                      lang.displayName,
                      style: TextStyle(
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isCurrent ? AppColors.navy : AppColors.textPrimary,
                      ),
                    ),
                    if (isCurrent) ...[
                      const Spacer(),
                      const Icon(Icons.check_rounded, size: 16, color: AppColors.navy),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Active Sensory Profile Banner with "Change" button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E5C7).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(profile.icon, color: const Color(0xFF00E5C7), size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                profile.localizedLabel(currentLang),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00E5C7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'ACTIVE',
                                  style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w900),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            profile.localizedDescription(currentLang),
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 22),
                      tooltip: 'Change sensory profile',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ProfileSelectorScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Section Header: Quick Actions
              const Text(
                'Video Calling (Google Meet style)',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              // Meet Action Cards
              Row(
                children: [
                  Expanded(
                    child: _homeCard(
                      icon: Icons.video_call_rounded,
                      title: appState.tr('start_meet'),
                      subtitle: 'Instant or Scheduled',
                      iconBg: const Color(0xFF0D9488),
                      onTap: _startNewMeetFlow,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _homeCard(
                      icon: Icons.add_link_rounded,
                      title: appState.tr('join_code'),
                      subtitle: 'Via Code or Link',
                      iconBg: const Color(0xFF2563EB),
                      onTap: _joinWithCode,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Section Header: Accessibility & AI
              Text(
                appState.tr('tools_title'),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              // Standalone Accessibility Hub Card
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FeaturesHubScreen()),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.navy,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.accessibility_new_rounded, color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appState.tr('tools_title'),
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              'Real-time Sign Recognition, Speech-to-Text & TTS (English, Hindi, Marathi)',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textSecondary, size: 16),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Saved Contacts Card
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Contacts directory ready.')),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.people_alt_rounded, color: Colors.purple, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          appState.tr('saved_contacts'),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 70), // Room for FAB
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.hearing_rounded, size: 20),
        label: Text(appState.tr('read_screen'), style: const TextStyle(fontWeight: FontWeight.bold)),
        onPressed: _readScreen,
      ),
    );
  }

  Widget _homeCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconBg,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
