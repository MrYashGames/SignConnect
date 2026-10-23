import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'localization_service.dart';

class BackendSignResult {
  final String status; // 'success' or 'buffering'
  final String? modelFile;
  final String? prediction;
  final double confidence;
  final String englishTranslation;
  final String hindiTranslation;
  final String marathiTranslation;
  final int bufferLength;
  final int bufferNeeded;
  final int handsDetected;
  final bool isStable;
  final List<Map<String, dynamic>> topPredictions;
  final String? message;

  BackendSignResult({
    required this.status,
    this.modelFile,
    this.prediction,
    this.confidence = 0.0,
    this.englishTranslation = '',
    this.hindiTranslation = '',
    this.marathiTranslation = '',
    this.bufferLength = 0,
    this.bufferNeeded = 30,
    this.handsDetected = 0,
    this.isStable = false,
    this.topPredictions = const [],
    this.message,
  });

  String getLocalizedTranslation(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.hi:
        return hindiTranslation.isNotEmpty ? hindiTranslation : (prediction ?? '');
      case AppLanguage.mr:
        return marathiTranslation.isNotEmpty ? marathiTranslation : (prediction ?? '');
      case AppLanguage.en:
        return englishTranslation.isNotEmpty ? englishTranslation : (prediction ?? '');
    }
  }

  factory BackendSignResult.buffering({
    required int bufferLength,
    int bufferNeeded = 30,
    int handsDetected = 0,
    String? modelFile,
  }) {
    return BackendSignResult(
      status: 'buffering',
      modelFile: modelFile,
      bufferLength: bufferLength,
      bufferNeeded: bufferNeeded,
      handsDetected: handsDetected,
    );
  }

  factory BackendSignResult.fromJson(Map<String, dynamic> json) {
    final status = json['status'] as String? ?? 'buffering';
    final translations = (json['translations'] as Map<String, dynamic>?) ?? {};
    final topList = (json['top_predictions'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];

    String en = translations['en']?.toString() ?? '';
    String hi = translations['hi']?.toString() ?? '';
    String mr = translations['mr']?.toString() ?? '';

    final pred = json['prediction'] as String?;
    if (en.isEmpty && pred != null) en = pred.replaceAll('_', ' ');
    if (hi.isEmpty && pred != null) hi = LocalizationService.translateSign(pred, AppLanguage.hi);
    if (mr.isEmpty && pred != null) mr = LocalizationService.translateSign(pred, AppLanguage.mr);

    return BackendSignResult(
      status: status,
      modelFile: json['model_file']?.toString(),
      prediction: pred,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      englishTranslation: en,
      hindiTranslation: hi,
      marathiTranslation: mr,
      bufferLength: json['buffer_length'] as int? ?? 0,
      bufferNeeded: json['buffer_needed'] as int? ?? 30,
      handsDetected: json['hands_detected'] as int? ?? 0,
      isStable: json['is_stable'] as bool? ?? false,
      topPredictions: topList,
      message: json['message'] as String?,
    );
  }
}

class BackendSignService {
  BackendSignService._internal();
  static final BackendSignService instance = BackendSignService._internal();

  bool _isOnline = false;
  DateTime? _lastHealthCheck;
  String? _lastError;
  bool _isProcessing = false;
  String _activeModel = 'isl_model.keras';
  List<String> _classes = [];
  Map<String, dynamic> _translations = {};
  int _sequenceLength = 30;

  bool get isOnline => _isOnline;
  String? get lastError => _lastError;
  DateTime? get lastHealthCheck => _lastHealthCheck;
  String get activeModel => _activeModel;
  List<String> get classes => List.unmodifiable(_classes);
  Map<String, dynamic> get translations => _translations;
  int get sequenceLength => _sequenceLength;

  /// Check whether the Backend Model server is reachable and load metadata
  Future<bool> checkHealth(String serverUrl) async {
    try {
      final cleanUrl = serverUrl.endsWith('/') ? serverUrl.substring(0, serverUrl.length - 1) : serverUrl;
      final uri = Uri.parse('$cleanUrl/status');
      final res = await http.get(uri).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        _isOnline = true;
        _lastError = null;
        _lastHealthCheck = DateTime.now();
        final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        _activeModel = data['model_file']?.toString() ?? 'isl_model.keras';
        if (data['classes'] is List) {
          _classes = (data['classes'] as List).map((e) => e.toString()).toList();
        }
        if (data['translations'] is Map) {
          _translations = Map<String, dynamic>.from(data['translations'] as Map);
        }
        _sequenceLength = data['sequence_length'] as int? ?? 30;
        return true;
      }
    } catch (e) {
      _lastError = e.toString();
    }
    _isOnline = false;
    return false;
  }

  /// Explicitly tell server to reload model from Backend/models/
  Future<bool> reloadModel(String serverUrl) async {
    try {
      final cleanUrl = serverUrl.endsWith('/') ? serverUrl.substring(0, serverUrl.length - 1) : serverUrl;
      final uri = Uri.parse('$cleanUrl/reload');
      final res = await http.post(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        _activeModel = data['model_file']?.toString() ?? 'isl_model.keras';
        if (data['classes'] is List) {
          _classes = (data['classes'] as List).map((e) => e.toString()).toList();
        }
        _isOnline = true;
        return true;
      }
    } catch (e) {
      _lastError = e.toString();
    }
    return false;
  }

  /// Send JPEG frame bytes to backend for prediction using isl_model.keras
  Future<BackendSignResult?> predictFrameBytes({
    required String serverUrl,
    required Uint8List jpegBytes,
    String clientId = 'app_user',
  }) async {
    if (_isProcessing) return null;
    _isProcessing = true;

    try {
      final cleanUrl = serverUrl.endsWith('/') ? serverUrl.substring(0, serverUrl.length - 1) : serverUrl;
      final base64Image = base64Encode(jpegBytes);
      final uri = Uri.parse('$cleanUrl/predict_frame');

      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'client_id': clientId,
              'image': base64Image,
            }),
          )
          .timeout(const Duration(seconds: 3));

      if (res.statusCode == 200) {
        _isOnline = true;
        _lastError = null;
        final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        final result = BackendSignResult.fromJson(data);
        if (result.modelFile != null && result.modelFile!.isNotEmpty) {
          _activeModel = result.modelFile!;
        }
        return result;
      } else {
        _lastError = 'Server error (${res.statusCode})';
      }
    } catch (e) {
      _lastError = e.toString();
      _isOnline = false;
    } finally {
      _isProcessing = false;
    }
    return null;
  }

  /// Reset current sequence buffer on backend
  Future<void> resetBuffer(String serverUrl, {String clientId = 'app_user'}) async {
    try {
      final cleanUrl = serverUrl.endsWith('/') ? serverUrl.substring(0, serverUrl.length - 1) : serverUrl;
      final uri = Uri.parse('$cleanUrl/reset');
      await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'client_id': clientId}),
      ).timeout(const Duration(seconds: 2));
    } catch (_) {}
  }
}
