import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/sensory_profile.dart';
import '../../services/localization_service.dart';
import '../../services/tts_service.dart';
import '../../theme/app_colors.dart';

class TextToAudioScreen extends StatefulWidget {
  const TextToAudioScreen({super.key});

  @override
  State<TextToAudioScreen> createState() => _TextToAudioScreenState();
}

class _TextToAudioScreenState extends State<TextToAudioScreen> {
  final TextEditingController _controller = TextEditingController();
  String? _filePath;
  bool _generating = false;
  String? _error;

  Future<void> _generate() async {
    if (_controller.text.trim().isEmpty) return;
    setState(() {
      _generating = true;
      _error = null;
      _filePath = null;
    });
    try {
      final appState = context.read<AppState>();
      await TtsService.instance.setLanguage(appState.language.ttsLocale);
      final path = await TtsService.instance.synthesizeToFile(_controller.text.trim());
      setState(() => _filePath = path);
    } catch (e) {
      setState(() => _error =
          'Could not generate an audio file on this platform/device. '
          'synthesizeToFile is supported on Android and iOS. ($e)');
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _play() async {
    if (_filePath == null) return;
    await TtsService.instance.playFile(_filePath!);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            appState.tr('tab_tto'),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Generates an actual .wav file from your text in the active language (English, Hindi, Marathi).',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              maxLines: 4,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: appState.tr('tts_hint'),
                hintStyle: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _generating ? null : _generate,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navy,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: _generating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.graphic_eq),
            label: Text(_generating ? 'Generating…' : 'Generate audio file'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
          ],
          if (_filePath != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration:
                  BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  const Icon(Icons.audiotrack, color: AppColors.navy),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _filePath!.split(Platform.pathSeparator).last,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.play_arrow, color: AppColors.navy),
                    onPressed: _play,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text('Saved to app documents directory: $_filePath',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          ],
        ],
      ),
    );
  }
}
