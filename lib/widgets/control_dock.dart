import 'package:flutter/material.dart';

class ControlDock extends StatelessWidget {
  final bool micOn;
  final bool cameraOn;
  final VoidCallback onToggleMic;
  final VoidCallback onToggleCamera;
  final VoidCallback onEndCall;

  const ControlDock({
    super.key,
    required this.micOn,
    required this.cameraOn,
    required this.onToggleMic,
    required this.onToggleCamera,
    required this.onEndCall,
  });

  Widget _btn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color bg = const Color(0xFF1E1E2E),
    Color fg = Colors.white,
  }) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: CircleAvatar(
          radius: 28,
          backgroundColor: bg,
          child: Icon(icon, color: fg, size: 26),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0B0B12),
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _btn(
            icon: micOn ? Icons.mic : Icons.mic_off,
            label: micOn ? 'Mute microphone' : 'Unmute microphone',
            onTap: onToggleMic,
          ),
          _btn(
            icon: cameraOn ? Icons.videocam : Icons.videocam_off,
            label: cameraOn ? 'Turn camera off' : 'Turn camera on',
            onTap: onToggleCamera,
          ),
          _btn(
            icon: Icons.call_end,
            label: 'End call',
            onTap: onEndCall,
            bg: Colors.redAccent,
          ),
        ],
      ),
    );
  }
}
