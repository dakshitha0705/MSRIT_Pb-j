import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Centralized voice synthesis service with configurable TTS settings
class VoiceService {
  static final VoiceService _instance = VoiceService._internal();

  factory VoiceService() {
    return _instance;
  }

  VoiceService._internal();

  final FlutterTts _tts = FlutterTts();

  double pitch = 1.3;
  double speechRate = 0.5;
  String locale = 'en-US';
  String? selectedVoice;

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _tts.setLanguage(locale);
      await _tts.setSpeechRate(speechRate);
      await _tts.setVolume(1.0);
      await _tts.setPitch(pitch);

      final dynamic rawVoices = await _tts.getVoices;
      if (rawVoices is List && rawVoices.isNotEmpty) {
        await _selectBestVoice(rawVoices);
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('VoiceService init error: $e');
    }
  }

  Future<void> _selectBestVoice(List voices) async {
    try {
      final List<Map<String, dynamic>> voiceList = voices
          .whereType<Map>()
          .map((v) => Map<String, dynamic>.from(v))
          .toList();

      if (voiceList.isEmpty) return;

      final googleVoices = voiceList.where((v) {
        final name = (v['name'] ?? '').toString().toLowerCase();
        final voiceLocale = (v['locale'] ?? '').toString().toLowerCase();
        return name.contains('google') && voiceLocale.startsWith('en');
      }).toList();

      if (googleVoices.isNotEmpty) {
        final voice = googleVoices.first;
        selectedVoice = voice['name']?.toString();

        if (selectedVoice != null && selectedVoice!.isNotEmpty) {
          await _tts.setVoice({
            'name': selectedVoice!,
            'locale': voice['locale']?.toString() ?? locale,
          });
        }
        return;
      }

      final englishVoices = voiceList.where((v) {
        final voiceLocale = (v['locale'] ?? '').toString().toLowerCase();
        return voiceLocale.startsWith('en');
      }).toList();

      if (englishVoices.isNotEmpty) {
        final voice = englishVoices.first;
        selectedVoice = voice['name']?.toString();

        if (selectedVoice != null && selectedVoice!.isNotEmpty) {
          await _tts.setVoice({
            'name': selectedVoice!,
            'locale': voice['locale']?.toString() ?? locale,
          });
        }
      }
    } catch (e) {
      debugPrint('Voice selection error: $e');
    }
  }

  Future<void> setPitch(double newPitch) async {
    pitch = newPitch.clamp(0.5, 2.0);
    await _tts.setPitch(pitch);
  }

  Future<void> setSpeechRate(double newRate) async {
    speechRate = newRate.clamp(0.1, 1.0);
    await _tts.setSpeechRate(speechRate);
  }

  Future<void> setLocale(String newLocale) async {
    locale = newLocale;
    await _tts.setLanguage(locale);
  }

  Future<List<Map<String, dynamic>>> getAvailableVoices() async {
    try {
      final dynamic rawVoices = await _tts.getVoices;
      if (rawVoices is! List) return [];

      return rawVoices
          .whereType<Map>()
          .map((v) => Map<String, dynamic>.from(v))
          .toList();
    } catch (e) {
      debugPrint('Get voices error: $e');
      return [];
    }
  }

  Future<void> speak(String text) async {
    if (!_isInitialized) await initialize();

    try {
      final cleanText = text.replaceAll(RegExp(r'[^\x00-\x7F]'), '');
      await _tts.speak(cleanText);
    } catch (e) {
      debugPrint('TTS speak error: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (e) {
      debugPrint('TTS stop error: $e');
    }
  }

  void setOnStart(VoidCallback callback) {
    _tts.setStartHandler(callback);
  }

  void setOnComplete(VoidCallback callback) {
    _tts.setCompletionHandler(callback);
  }

  void dispose() {
    _tts.stop();
  }
}
