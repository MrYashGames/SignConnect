import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/sensory_profile.dart';
import 'screens/main_shell.dart';
import 'screens/profile_selector.dart';
import 'services/preferences_service.dart';
import 'services/tts_service.dart';
import 'theme/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PreferencesService.instance.init();
  final appState = AppState();

  runApp(
    ChangeNotifierProvider.value(
      value: appState,
      child: const SenseBridgeApp(),
    ),
  );
}

class SenseBridgeApp extends StatefulWidget {
  const SenseBridgeApp({super.key});

  @override
  State<SenseBridgeApp> createState() => _SenseBridgeAppState();
}

class _SenseBridgeAppState extends State<SenseBridgeApp> {
  @override
  void initState() {
    super.initState();
    TtsService.instance.init();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return MaterialApp(
      title: 'SignConnect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.navy,
          brightness: Brightness.light,
          primary: AppColors.navy,
          surface: AppColors.background,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
        ),
        fontFamily: 'Roboto',
      ),
      // Choosing the profile is only asked on first launch; otherwise MainShell is loaded
      home: appState.hasChosenProfile
          ? const MainShell()
          : const ProfileSelectorScreen(),
    );
  }
}
