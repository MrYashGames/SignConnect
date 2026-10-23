import 'package:flutter/material.dart';

/// The "Live Translation Console" (middle 15% of the Meet screen).
/// Scrolling, grammar-corrected captions — the universal fallback for
/// every profile. Auto-scrolls to the latest line.
class TranslationConsole extends StatefulWidget {
  final List<String> captions;

  const TranslationConsole({super.key, required this.captions});

  @override
  State<TranslationConsole> createState() => _TranslationConsoleState();
}

class _TranslationConsoleState extends State<TranslationConsole> {
  final ScrollController _controller = ScrollController();

  @override
  void didUpdateWidget(covariant TranslationConsole oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_controller.hasClients) {
        _controller.animateTo(
          _controller.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF12121C),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Semantics(
        liveRegion: true,
        label: 'Live captions',
        child: ListView.builder(
          controller: _controller,
          itemCount: widget.captions.length,
          itemBuilder: (context, i) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              widget.captions[i],
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}
