import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sensory_profile.dart';
import '../theme/app_colors.dart';
import 'features/tts_screen.dart';
import 'features/stt_screen.dart';
import 'features/text_to_audio_screen.dart';
import 'features/sign_recognition_screen.dart';

class FeaturesHubScreen extends StatefulWidget {
  const FeaturesHubScreen({super.key});

  @override
  State<FeaturesHubScreen> createState() => _FeaturesHubScreenState();
}

class _FeaturesHubScreenState extends State<FeaturesHubScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(
          appState.tr('tools_title'),
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.navy,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.navy,
          tabs: [
            Tab(icon: const Icon(Icons.record_voice_over), text: appState.tr('tab_tts')),
            Tab(icon: const Icon(Icons.mic), text: appState.tr('tab_stt')),
            Tab(icon: const Icon(Icons.graphic_eq), text: appState.tr('tab_tto')),
            Tab(icon: const Icon(Icons.pan_tool_alt), text: appState.tr('tab_signs')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          TtsScreen(),
          SttScreen(),
          TextToAudioScreen(),
          SignRecognitionScreen(),
        ],
      ),
    );
  }
}
