import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sensory_profile.dart';
import '../services/tts_service.dart';
import '../theme/app_colors.dart';
import 'home_dashboard.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  final _screens = const [
    HomeDashboard(),
    ProfileScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _speakTab(_index));
  }

  void _speakTab(int index) {
    final appState = context.read<AppState>();
    if (!appState.autoReadScreen) return;

    final labels = switch (index) {
      0 => homeScreenLabels(appState),
      1 => profileScreenLabels(appState),
      2 => settingsScreenLabels(appState),
      _ => <String>[],
    };
    TtsService.instance.readScreenText(labels);
  }

  void _selectTab(int index) {
    if (index == _index) return;
    setState(() => _index = index);
    _speakTab(index);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _navItem(
                icon: Icons.home_rounded,
                label: appState.tr('nav_home'),
                index: 0,
              ),
              _navItem(
                icon: Icons.person_rounded,
                label: appState.tr('nav_profile'),
                index: 1,
              ),
              _navItem(
                icon: Icons.settings_rounded,
                label: appState.tr('nav_options'),
                index: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem({required IconData icon, required String label, required int index}) {
    final selected = _index == index;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: () => _selectTab(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? Colors.white.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: selected ? Colors.white : Colors.white54, size: 24),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
