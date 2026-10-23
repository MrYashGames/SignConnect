import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/sensory_profile.dart';
import '../../services/localization_service.dart';
import '../../services/tts_service.dart';
import '../../theme/app_colors.dart';

class TtsScreen extends StatefulWidget {
  const TtsScreen({super.key});

  @override
  State<TtsScreen> createState() => _TtsScreenState();
}

class _TtsScreenState extends State<TtsScreen> {
  final TextEditingController _controller = TextEditingController();
  double _rate = 0.5;
  double _pitch = 1.0;
  bool _speaking = false;
  String _activeWord = '';
  int _activeWordIndex = -1;

  @override
  void initState() {
    super.initState();
    TtsService.instance.setHandlers(
      onWord: (word, start, end) {
        if (!mounted) return;
        setState(() {
          _activeWord = word;
        });
      },
      onStart: () {
        if (!mounted) return;
        setState(() => _speaking = true);
      },
      onComplete: () {
        if (!mounted) return;
        setState(() {
          _speaking = false;
          _activeWord = '';
          _activeWordIndex = -1;
        });
      },
    );
  }

  @override
  void dispose() {
    TtsService.instance.stop();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _speak([String? overrideText]) async {
    final text = (overrideText ?? _controller.text).trim();
    if (text.isEmpty) return;

    final appState = context.read<AppState>();
    await TtsService.instance.setLanguage(appState.language.ttsLocale);
    await TtsService.instance.setRate(_rate);
    await TtsService.instance.setPitch(_pitch);

    setState(() {
      _speaking = true;
      _activeWord = '';
    });

    await TtsService.instance.speak(text);

    // Also simulate word highlighting if platform doesn't support progressHandler
    _simulateWordProgress(text);
  }

  void _simulateWordProgress(String text) async {
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    for (int i = 0; i < words.length; i++) {
      if (!_speaking || !mounted) break;
      setState(() {
        _activeWord = words[i];
        _activeWordIndex = i;
      });
      final delay = (400 / (_rate * 2)).clamp(150, 800).toInt();
      await Future.delayed(Duration(milliseconds: delay));
    }
    if (mounted && _speaking) {
      setState(() {
        _speaking = false;
        _activeWord = '';
        _activeWordIndex = -1;
      });
    }
  }

  Future<void> _stop() async {
    await TtsService.instance.stop();
    if (mounted) {
      setState(() {
        _speaking = false;
        _activeWord = '';
        _activeWordIndex = -1;
      });
    }
  }

  void _selectPhrase(String phrase) {
    _controller.text = phrase;
    _speak(phrase);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final currentLang = appState.language;
    final quickPhrases = LocalizationService.getQuickPhrases(currentLang);
    final currentWords = _controller.text
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Screen Title
          Text(
            appState.tr('tts_title'),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            appState.tr('tts_desc'),
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),

          // Text Field Container
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _speaking ? AppColors.navy : Colors.transparent,
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _controller,
                  maxLines: 4,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: appState.tr('tts_hint'),
                    hintStyle: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                if (_controller.text.isNotEmpty)
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: const Icon(Icons.clear, size: 18, color: AppColors.textSecondary),
                      onPressed: () {
                        _controller.clear();
                        setState(() {});
                      },
                    ),
                  ),
              ],
            ),
          ),

          // --- Real-time Spoken Words Visualizer ---
          if (currentWords.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.volume_up, size: 16, color: AppColors.navy),
                      const SizedBox(width: 6),
                      Text(
                        appState.tr('tts_spoken_words'),
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (_speaking)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'LIVE',
                            style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: currentWords.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final word = entry.value;
                      final isSpoken = _speaking && (_activeWord == word || _activeWordIndex == idx);

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSpoken ? AppColors.navy : AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSpoken ? AppColors.navy : Colors.black12,
                            width: isSpoken ? 2 : 1,
                          ),
                          boxShadow: isSpoken
                              ? [
                                  BoxShadow(
                                    color: AppColors.navy.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: Text(
                          word,
                          style: TextStyle(
                            color: isSpoken ? Colors.white : AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: isSpoken ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Slider Controls (Speed & Pitch)
          _sliderCard(appState.tr('tts_speed'), _rate, 0.1, 1.0, (v) => setState(() => _rate = v)),
          const SizedBox(height: 10),
          _sliderCard(appState.tr('tts_pitch'), _pitch, 0.5, 2.0, (v) => setState(() => _pitch = v)),

          const SizedBox(height: 20),

          // Speak & Stop Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _speaking ? null : () => _speak(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: Icon(_speaking ? Icons.volume_up : Icons.play_arrow),
                  label: Text(_speaking ? appState.tr('tts_speaking') : appState.tr('tts_speak_btn')),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _speaking ? _stop : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Icon(Icons.stop),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // --- Quick Everyday Phrases ---
          Text(
            appState.tr('tts_quick_phrases'),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ...quickPhrases.map((phrase) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => _selectPhrase(phrase),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.black.withValues(alpha: 0.05)
                      ),                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.chat_bubble_outline, size: 18, color: AppColors.navy),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            phrase,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Icon(Icons.volume_up, size: 18, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _sliderCard(String label, double value, double min, double max, ValueChanged<double> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
          ),
          Expanded(
            child: Slider(
              value: value,
              min: min,
              max: max,
              activeColor: AppColors.navy,
              onChanged: onChanged,
            ),
          ),
          Text(
            value.toStringAsFixed(1),
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
