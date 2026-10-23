import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/sensory_profile.dart';
import '../../services/localization_service.dart';
import '../../services/stt_service.dart';
import '../../services/tts_service.dart';
import '../../theme/app_colors.dart';

class SttScreen extends StatefulWidget {
  const SttScreen({super.key});

  @override
  State<SttScreen> createState() => _SttScreenState();
}

class _SttScreenState extends State<SttScreen> with SingleTickerProviderStateMixin {
  String _liveText = '';
  final List<String> _finalizedLines = [];
  bool _listening = false;
  String? _lastError;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    // Sync STT language with AppState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = context.read<AppState>();
      SttService.instance.setLanguage(appState.speechLanguage);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    SttService.instance.stopListening();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (_listening) {
      await SttService.instance.stopListening();
      if (mounted) setState(() => _listening = false);
      return;
    }

    setState(() {
      _listening = true;
      _liveText = '';
      _lastError = null;
    });

    final appState = context.read<AppState>();
    await SttService.instance.setLanguage(appState.speechLanguage);

    await SttService.instance.startListening(
      onResult: (text, isFinal) {
        if (!mounted) return;
        setState(() {
          _liveText = text;
          if (isFinal && text.trim().isNotEmpty) {
            _finalizedLines.add(text.trim());
            _liveText = '';
          }
        });
      },
      onError: (message) {
        if (!mounted) return;
        if (message.contains('permission')) {
          setState(() {
            _lastError = message;
            _listening = false;
          });
        }
      },
    );
  }

  void _changeSpeechLanguage(AppLanguage lang) async {
    final appState = context.read<AppState>();
    appState.setSpeechLanguage(lang);
    await SttService.instance.setLanguage(lang);

    if (_listening) {
      await SttService.instance.stopListening();
      setState(() => _listening = false);
      _toggleListening();
    } else {
      setState(() {});
    }
  }

  void _copyAll() {
    final fullText = [..._finalizedLines, if (_liveText.isNotEmpty) _liveText].join('\n');
    if (fullText.trim().isEmpty) return;
    Clipboard.setData(ClipboardData(text: fullText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.read<AppState>().tr('stt_copied')),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _clearAll() {
    setState(() {
      _finalizedLines.clear();
      _liveText = '';
      _lastError = null;
    });
  }

  List<String> _getAllRecognizedWords() {
    final combined = [..._finalizedLines, _liveText].join(' ');
    if (combined.trim().isEmpty) return [];
    return combined
        .split(RegExp(r'\s+'))
        .where((w) => w.trim().isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final currentSpeechLang = appState.speechLanguage;
    final words = _getAllRecognizedWords();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            appState.tr('stt_title'),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            appState.tr('stt_desc'),
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),

          // --- Language Selection Chips ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Text(
                  appState.tr('stt_select_language'),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: AppLanguage.values.map((lang) {
                        final isSelected = lang == currentSpeechLang;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(
                              lang.displayName,
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppColors.textPrimary,
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: AppColors.navy,
                            backgroundColor: AppColors.background,
                            onSelected: (_) => _changeSpeechLanguage(lang),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_lastError != null) ...[
            const SizedBox(height: 8),
            Text(_lastError!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
          ],

          const SizedBox(height: 12),

          // --- Real-Time Recognized Words Cloud ---
          if (words.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.navy.withValues(alpha: 0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: AppColors.navy, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '${appState.tr('stt_recognized_words')} (${words.length})',
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 16, color: AppColors.textSecondary),
                        onPressed: _copyAll,
                        tooltip: appState.tr('stt_copy'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.textSecondary),
                        onPressed: _clearAll,
                        tooltip: appState.tr('stt_clear'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: words.take(20).map((w) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.navy.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.navy.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          w,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // --- Transcript Box ---
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Semantics(
                liveRegion: true,
                child: ListView(
                  children: [
                    if (_finalizedLines.isEmpty && _liveText.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 40),
                          child: Text(
                            appState.tr('stt_tap_to_listen'),
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ..._finalizedLines.map((line) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  line,
                                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.volume_up, color: AppColors.textSecondary, size: 20),
                                onPressed: () {
                                  TtsService.instance.setLanguage(currentSpeechLang.ttsLocale);
                                  TtsService.instance.speak(line);
                                },
                              ),
                            ],
                          ),
                        )),
                    if (_liveText.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.navy.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.navy),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _liveText,
                                style: const TextStyle(
                                  color: AppColors.navy,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // --- Microphone Action Button with Pulse Effect ---
          Center(
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final scale = _listening ? 1.0 + (_pulseController.value * 0.12) : 1.0;
                    return Transform.scale(
                      scale: scale,
                      child: GestureDetector(
                        onTap: _toggleListening,
                        child: CircleAvatar(
                          radius: 38,
                          backgroundColor: _listening ? AppColors.danger : AppColors.navy,
                          child: Icon(
                            _listening ? Icons.stop : Icons.mic,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  _listening
                      ? '${appState.tr('stt_listening')} (${currentSpeechLang.displayName})'
                      : appState.tr('stt_tap_to_listen'),
                  style: TextStyle(
                    color: _listening ? AppColors.danger : AppColors.textSecondary,
                    fontSize: 12.5,
                    fontWeight: _listening ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
