import 'dart:convert';
import 'dart:math';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/sensory_profile.dart';

const String livekitUrl = 'wss://signconnect-apdcgtw1.livekit.cloud';
const String livekitApiKey = 'APIfTjYXidVMiFQ';
const String livekitApiSecret = 'Zj7ChYVt6TcUOdYmmfekGV2YtKiJi6k0BQlf2IFMEePD';

const String _lobbyTopic = 'lobby';
const String _chatTopic = 'chat';

class InMeetMessage {
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final bool isLocal;

  const InMeetMessage({
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    required this.isLocal,
  });
}

class MeetParticipant {
  final String id;
  final String name;
  final bool isLocal;
  final VideoTrack? videoTrack;
  final bool isVideoMuted;
  final bool isAudioMuted;
  final bool isSpeaking;

  const MeetParticipant({
    required this.id,
    required this.name,
    required this.isLocal,
    this.videoTrack,
    this.isVideoMuted = false,
    this.isAudioMuted = false,
    this.isSpeaking = false,
  });
}

class LiveKitMeetService {
  Room? _room;
  EventsListener<RoomEvent>? _listener;
  void Function()? _onChanged;

  String _localId = '';
  bool _waiting = false;
  String _currentChannel = '';

  final Set<String> waitingIds = {};
  final List<InMeetMessage> chatMessages = [];

  bool get isInitialized => _room != null;
  Room get room => _room!;
  String get currentChannel => _currentChannel;
  String get localId => _localId;

  /// Returns all participants (local + all remote) so the meeting can display
  /// a Google Meet-style multi-user grid.
  List<MeetParticipant> get participants {
    final list = <MeetParticipant>[];
    final r = _room;
    if (r == null) return list;

    // 1. Local participant
    final lp = r.localParticipant;
    if (lp != null) {
      VideoTrack? localTrack;
      bool videoMuted = true;
      for (final pub in lp.videoTrackPublications) {
        if (pub.track != null && !pub.muted) {
          localTrack = pub.track;
          videoMuted = false;
          break;
        }
      }
      bool audioMuted = true;
      for (final pub in lp.audioTrackPublications) {
        if (!pub.muted) {
          audioMuted = false;
          break;
        }
      }

      final isHost = lp.identity.startsWith('host');
      list.add(MeetParticipant(
        id: lp.identity,
        name: 'You (${isHost ? 'Host' : 'Guest'})',
        isLocal: true,
        videoTrack: localTrack,
        isVideoMuted: videoMuted,
        isAudioMuted: audioMuted,
        isSpeaking: lp.isSpeaking,
      ));
    }

    // 2. All remote participants (multi-user support)
    int guestIdx = 1;
    for (final p in r.remoteParticipants.values) {
      VideoTrack? remoteTrack;
      bool videoMuted = true;
      for (final pub in p.videoTrackPublications) {
        if (pub.track != null && !pub.muted) {
          remoteTrack = pub.track;
          videoMuted = false;
          break;
        }
      }
      bool audioMuted = true;
      for (final pub in p.audioTrackPublications) {
        if (!pub.muted) {
          audioMuted = false;
          break;
        }
      }

      String displayName = p.name.isNotEmpty
          ? p.name
          : (p.identity.startsWith('host')
              ? 'Meeting Host'
              : 'Participant ${guestIdx++}');

      list.add(MeetParticipant(
        id: p.identity,
        name: displayName,
        isLocal: false,
        videoTrack: remoteTrack,
        isVideoMuted: videoMuted,
        isAudioMuted: audioMuted,
        isSpeaking: p.isSpeaking,
      ));
    }

    return list;
  }

  Future<void> init() async {
    if (_room != null) return;
    await [Permission.camera, Permission.microphone].request();
    _room = Room(
      roomOptions: const RoomOptions(adaptiveStream: true, dynacast: true),
    );
  }

  String _buildToken(String roomName, String identity) {
    final jwt = JWT(
      {
        'name': identity,
        'video': {
          'room': roomName,
          'roomJoin': true,
          'canPublish': true,
          'canSubscribe': true,
          'canPublishData': true,
        },
      },
      issuer: livekitApiKey,
      subject: identity,
    );
    return jwt.sign(
      SecretKey(livekitApiSecret),
      expiresIn: const Duration(hours: 4),
    );
  }

  Future<void> joinChannel({
    required String channelName,
    required bool isHost,
    required AdmissionMode admissionMode,
    required void Function() onChanged,
    required void Function(String waitingId) onParticipantWaiting,
    required void Function() onAdmitted,
  }) async {
    final r = _room!;
    _currentChannel = channelName;
    _onChanged = onChanged;
    _waiting = !isHost && admissionMode == AdmissionMode.alwaysAsk;
    _localId = '${isHost ? 'host' : 'guest'}_${Random().nextInt(1 << 24)}';
    chatMessages.clear();

    _listener = r.createListener()
      ..on<DataReceivedEvent>((e) {
        if (e.topic == _lobbyTopic) {
          final msg = _decode(e.data);
          if (msg == null) return;

          if (msg['t'] == 'waiting' && isHost) {
            final id = e.participant?.identity;
            if (id == null) return;
            waitingIds.add(id);
            onParticipantWaiting(id);
            onChanged();
          } else if (msg['t'] == 'admit' && msg['id'] == _localId && _waiting) {
            _waiting = false;
            _enableMedia();
            onAdmitted();
          }
        } else if (e.topic == _chatTopic) {
          final msg = _decode(e.data);
          if (msg != null && msg['text'] != null) {
            final sender = msg['sender']?.toString() ?? 'Participant';
            final text = msg['text'].toString();
            final timeStr = msg['time']?.toString();
            DateTime time = DateTime.now();
            if (timeStr != null) {
              time = DateTime.tryParse(timeStr) ?? DateTime.now();
            }

            chatMessages.add(InMeetMessage(
              senderId: e.participant?.identity ?? 'remote',
              senderName: sender,
              text: text,
              timestamp: time,
              isLocal: false,
            ));
            onChanged();
          }
        }
      })
      ..on<ParticipantConnectedEvent>((e) {
        if (_waiting) _announceWaiting();
        onChanged();
      })
      ..on<ParticipantDisconnectedEvent>((e) {
        waitingIds.remove(e.participant.identity);
        onChanged();
      })
      ..on<TrackSubscribedEvent>((e) => onChanged())
      ..on<TrackUnsubscribedEvent>((e) => onChanged())
      ..on<TrackMutedEvent>((e) => onChanged())
      ..on<TrackUnmutedEvent>((e) => onChanged());

    r.addListener(onChanged);

    await r.connect(livekitUrl, _buildToken(channelName, _localId));

    if (_waiting) {
      _announceWaiting();
    } else {
      await _enableMedia();
    }
  }

  Future<void> sendChatMessage(String text) async {
    if (text.trim().isEmpty) return;
    final lp = _room?.localParticipant;
    if (lp == null) return;

    final isHost = lp.identity.startsWith('host');
    final senderName = isHost ? 'Host' : 'Guest';
    final now = DateTime.now();

    final payload = {
      'text': text.trim(),
      'sender': senderName,
      'time': now.toIso8601String(),
    };

    await lp.publishData(
      utf8.encode(jsonEncode(payload)),
      topic: _chatTopic,
      reliable: true,
    );

    chatMessages.add(InMeetMessage(
      senderId: lp.identity,
      senderName: 'You',
      text: text.trim(),
      timestamp: now,
      isLocal: true,
    ));

    _onChanged?.call();
  }

  Future<void> _enableMedia() async {
    final lp = _room?.localParticipant;
    if (lp == null) return;
    await lp.setCameraEnabled(true);
    await lp.setMicrophoneEnabled(true);
  }

  void _announceWaiting() {
    _send({'t': 'waiting'});
  }

  void admitParticipant(String identity) {
    waitingIds.remove(identity);
    _send({'t': 'admit', 'id': identity});
  }

  void _send(Map<String, dynamic> msg) {
    _room?.localParticipant?.publishData(
      utf8.encode(jsonEncode(msg)),
      reliable: true,
      topic: _lobbyTopic,
    );
  }

  Map<String, dynamic>? _decode(List<int> data) {
    try {
      return jsonDecode(utf8.decode(data)) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> toggleMic(bool muted) async {
    await _room?.localParticipant?.setMicrophoneEnabled(!muted);
  }

  Future<void> toggleCamera(bool off) async {
    await _room?.localParticipant?.setCameraEnabled(!off);
  }

  Future<void> leaveChannel() async {
    waitingIds.clear();
    chatMessages.clear();
    await _room?.disconnect();
  }

  Future<void> dispose() async {
    final r = _room;
    if (r == null) return;
    _room = null;
    if (_onChanged != null) r.removeListener(_onChanged!);
    await _listener?.dispose();
    await r.disconnect();
    await r.dispose();
  }
}