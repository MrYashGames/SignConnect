import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:provider/provider.dart';
import '../models/sensory_profile.dart';
import '../services/livekit_meet_service.dart';
import '../services/tts_service.dart';
import '../theme/app_colors.dart';

class MeetScreen extends StatefulWidget {
  final String channelName;
  final bool isHost;

  const MeetScreen({
    super.key,
    required this.channelName,
    required this.isHost,
  });

  @override
  State<MeetScreen> createState() => _MeetScreenState();
}

class _MeetScreenState extends State<MeetScreen> {
  final LiveKitMeetService _meet = LiveKitMeetService();
  bool _micOn = true;
  bool _cameraOn = true;
  bool _joining = true;
  String? _error;
  bool _waitingForAdmission = false;

  String? _pinnedParticipantId;
  int _lastSeenMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _join();
  }

  Future<void> _join() async {
    final appState = context.read<AppState>();
    try {
      await _meet.init();
      if (!mounted) return;
      setState(() {
        _waitingForAdmission =
            !widget.isHost && appState.admissionMode == AdmissionMode.alwaysAsk;
      });

      await _meet.joinChannel(
        channelName: widget.channelName,
        isHost: widget.isHost,
        admissionMode: appState.admissionMode,
        onChanged: () {
          if (!mounted) return;
          setState(() {});
        },
        onParticipantWaiting: (id) {
          if (!mounted) return;
          setState(() {});
          TtsService.instance.speak('Someone is waiting to join the meet.');
        },
        onAdmitted: () {
          if (!mounted) return;
          setState(() => _waitingForAdmission = false);
          TtsService.instance.speak('You have been admitted to the meet.');
        },
      );
      if (!mounted) return;
      setState(() => _joining = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _joining = false;
        _error = 'Could not join the meeting: $e';
      });
    }
  }

  void _copyMeetingInfo() {
    final link = 'https://signconnect.app/meet?code=${widget.channelName}';
    Clipboard.setData(ClipboardData(
      text: 'Join my SignConnect Meet:\nCode: ${widget.channelName}\nLink: $link',
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Meeting code copied: ${widget.channelName}'),
        backgroundColor: AppColors.navy,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _togglePin(String participantId) {
    setState(() {
      if (_pinnedParticipantId == participantId) {
        _pinnedParticipantId = null;
      } else {
        _pinnedParticipantId = participantId;
      }
    });
  }

  void _openChatSheet() {
    setState(() {
      _lastSeenMessageCount = _meet.chatMessages.length;
    });

    final textController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: SizedBox(
                height: MediaQuery.of(ctx).size.height * 0.65,
                child: Column(
                  children: [
                    // Header
                    Row(
                      children: [
                        const Icon(Icons.chat_bubble_outline,
                            color: Color(0xFF00E5C7), size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'In-Call Messages',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Messages can be seen only by people in the call and are deleted when the call ends.',
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const Divider(color: Colors.white12),

                    // Message list
                    Expanded(
                      child: _meet.chatMessages.isEmpty
                          ? const Center(
                              child: Text(
                                'No messages yet.\nSay hello to everyone!',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white38),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _meet.chatMessages.length,
                              itemBuilder: (context, index) {
                                final msg = _meet.chatMessages[index];
                                final isMe = msg.isLocal;
                                return Align(
                                  alignment: isMe
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 4),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isMe
                                          ? AppColors.navy
                                          : const Color(0xFF2A2A3C),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: isMe
                                          ? CrossAxisAlignment.end
                                          : CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          msg.senderName,
                                          style: TextStyle(
                                            color: isMe
                                                ? const Color(0xFF00E5C7)
                                                : Colors.white70,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          msg.text,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),

                    // Input field
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: textController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Send a message to everyone…',
                                hintStyle:
                                    const TextStyle(color: Colors.white38),
                                filled: true,
                                fillColor: const Color(0xFF2A2A3C),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          CircleAvatar(
                            backgroundColor: const Color(0xFF00E5C7),
                            radius: 22,
                            child: IconButton(
                              icon: const Icon(Icons.send_rounded,
                                  color: Colors.black, size: 20),
                              onPressed: () {
                                final text = textController.text.trim();
                                if (text.isNotEmpty) {
                                  _meet.sendChatMessage(text);
                                  textController.clear();
                                  setSheetState(() {});
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _endCall() async {
    await _meet.leaveChannel();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _meet.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final participants = _meet.participants;
    final unreadCount = _meet.chatMessages.length - _lastSeenMessageCount;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _endCall();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF101018),
        body: SafeArea(
          child: Stack(
            children: [
              // Main Video Area
              Column(
                children: [
                  const SizedBox(height: 54), // Room for top header
                  Expanded(
                    child: _buildStage(participants),
                  ),
                  _buildControlsDock(unreadCount),
                ],
              ),

              // Top Bar with Google Meet-style Code on Top-Left
              Positioned(
                top: 8,
                left: 12,
                right: 12,
                child: Row(
                  children: [
                    // Back / End Call icon
                    GestureDetector(
                      onTap: _endCall,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back,
                            color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Top-Left Meeting Code Pill
                    GestureDetector(
                      onTap: _copyMeetingInfo,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.videocam_rounded,
                                color: Color(0xFF00E5C7), size: 16),
                            const SizedBox(width: 6),
                            Text(
                              widget.channelName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.copy_rounded,
                                color: Colors.white70, size: 14),
                          ],
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Participant count pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.people_alt_rounded,
                              color: Colors.white70, size: 15),
                          const SizedBox(width: 4),
                          Text(
                            '${participants.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Waiting room banner for host
              if (widget.isHost && _meet.waitingIds.isNotEmpty)
                Positioned(
                  top: 54,
                  right: 12,
                  child: _WaitingRoomBadge(
                    ids: _meet.waitingIds.toList(),
                    onAdmit: (id) {
                      _meet.admitParticipant(id);
                      setState(() {});
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStage(List<MeetParticipant> participants) {
    if (_joining) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF00E5C7)),
            SizedBox(height: 16),
            Text('Connecting to Google Meet room…',
                style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!,
              style: const TextStyle(color: Colors.redAccent),
              textAlign: TextAlign.center),
        ),
      );
    }
    if (_waitingForAdmission) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF00E5C7)),
            SizedBox(height: 20),
            Text(
              'Waiting for host to let you in…',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    if (participants.isEmpty) {
      return const Center(
        child: Text('No participants in the call',
            style: TextStyle(color: Colors.white38)),
      );
    }

    // --- PINNED PARTICIPANT VIEW ---
    if (_pinnedParticipantId != null) {
      final pinned = participants.firstWhere(
        (p) => p.id == _pinnedParticipantId,
        orElse: () => participants.first,
      );
      final others = participants.where((p) => p.id != pinned.id).toList();

      return Column(
        children: [
          // Main prominent stage
          Expanded(
            flex: 75,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: _buildParticipantTile(pinned, isPinned: true),
            ),
          ),
          // Horizontal filmstrip for other participants
          if (others.isNotEmpty)
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                itemCount: others.length,
                itemBuilder: (context, idx) {
                  return Container(
                    width: 140,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: _buildParticipantTile(others[idx], isThumbnail: true),
                  );
                },
              ),
            ),
        ],
      );
    }

    // --- AUTO-BALANCED GRID VIEW (GOOGLE MEET STYLE) ---
    final count = participants.length;

    if (count == 1) {
      return Padding(
        padding: const EdgeInsets.all(6),
        child: _buildParticipantTile(participants.first),
      );
    } else if (count == 2) {
      return Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: _buildParticipantTile(participants[0]),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: _buildParticipantTile(participants[1]),
            ),
          ),
        ],
      );
    } else if (count <= 4) {
      return Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: _buildParticipantTile(participants[0]),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: _buildParticipantTile(participants[1]),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: _buildParticipantTile(participants[2]),
                  ),
                ),
                if (count == 4)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: _buildParticipantTile(participants[3]),
                    ),
                  )
                else
                  const Spacer(),
              ],
            ),
          ),
        ],
      );
    } else {
      // 5 or more participants: 2-column scrollable grid
      return GridView.builder(
        padding: const EdgeInsets.all(6),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.1,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
        ),
        itemCount: count,
        itemBuilder: (context, idx) => _buildParticipantTile(participants[idx]),
      );
    }
  }

  Widget _buildParticipantTile(
    MeetParticipant p, {
    bool isPinned = false,
    bool isThumbnail = false,
  }) {
    final hasVideo = p.videoTrack != null && !p.isVideoMuted;

    return GestureDetector(
      onTap: () => _togglePin(p.id),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: p.isSpeaking
                ? const Color(0xFF00E5C7)
                : (isPinned ? Colors.blueAccent : Colors.white12),
            width: p.isSpeaking || isPinned ? 2.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video or Avatar
            if (hasVideo)
              VideoTrackRenderer(
                p.videoTrack!,
                mirrorMode:
                    p.isLocal ? VideoViewMirrorMode.mirror : VideoViewMirrorMode.off,
              )
            else
              Container(
                color: const Color(0xFF181824),
                child: Center(
                  child: CircleAvatar(
                    radius: isThumbnail ? 20 : 36,
                    backgroundColor: AppColors.navy,
                    child: Text(
                      p.name.isNotEmpty ? p.name.substring(0, 1).toUpperCase() : '?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isThumbnail ? 16 : 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

            // Top-right Pin icon
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: () => _togglePin(p.id),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                    color: isPinned ? const Color(0xFF00E5C7) : Colors.white70,
                    size: 16,
                  ),
                ),
              ),
            ),

            // Bottom-left Name pill & Audio status
            Positioned(
              left: 8,
              bottom: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      p.isAudioMuted ? Icons.mic_off : Icons.mic,
                      color: p.isAudioMuted ? Colors.redAccent : Colors.white,
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                          maxWidth: isThumbnail ? 80 : 160),
                      child: Text(
                        p.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsDock(int unreadCount) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Microphone Toggle
          _controlButton(
            icon: _micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
            color: _micOn ? Colors.white24 : Colors.redAccent.withValues(alpha: 0.3),
            iconColor: _micOn ? Colors.white : Colors.redAccent,
            onTap: () {
              setState(() => _micOn = !_micOn);
              _meet.toggleMic(!_micOn);
            },
          ),

          // Camera Toggle
          _controlButton(
            icon: _cameraOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
            color: _cameraOn ? Colors.white24 : Colors.redAccent.withValues(alpha: 0.3),
            iconColor: _cameraOn ? Colors.white : Colors.redAccent,
            onTap: () {
              setState(() => _cameraOn = !_cameraOn);
              _meet.toggleCamera(!_cameraOn);
            },
          ),

          // In-Meet Chat with Unread Badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              _controlButton(
                icon: Icons.chat_bubble_outline_rounded,
                color: Colors.white24,
                iconColor: Colors.white,
                onTap: _openChatSheet,
              ),
              if (unreadCount > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Color(0xFF00E5C7),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Red End Call / Leave Button
          _controlButton(
            icon: Icons.call_end_rounded,
            color: Colors.redAccent,
            iconColor: Colors.white,
            onTap: _endCall,
          ),
        ],
      ),
    );
  }

  Widget _controlButton({
    required IconData icon,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
    );
  }
}

class _WaitingRoomBadge extends StatelessWidget {
  final List<String> ids;
  final void Function(String id) onAdmit;

  const _WaitingRoomBadge({required this.ids, required this.onAdmit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00E5C7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${ids.length} guest(s) in lobby',
            style: const TextStyle(
                color: Color(0xFF00E5C7),
                fontSize: 12,
                fontWeight: FontWeight.bold),
          ),
          for (var i = 0; i < ids.length; i++)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Guest ${i + 1}',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 12)),
                  const SizedBox(width: 8),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      minimumSize: Size.zero,
                    ),
                    onPressed: () => onAdmit(ids[i]),
                    child: const Text('Admit',
                        style: TextStyle(
                            color: Color(0xFF00E5C7), fontSize: 12)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}