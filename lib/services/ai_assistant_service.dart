import 'dart:convert';
import 'package:http/http.dart' as http;

/// Intent types recognized by the AI assistant
enum AssistantIntent {
  playMusic,
  openAiChat,
  openBattery,
  openData,
  openFile,
  openMedia,
  openContact,
  openVoice,
  openSpin,
  openGame,
  openFriends,
  openMessages,
  openNotifications,
  shareContact,
  unknown,
}

/// Core AI assistant service handling intent detection and AI processing
class AiAssistantService {
  static final AiAssistantService _instance = AiAssistantService._internal();

  factory AiAssistantService() {
    return _instance;
  }

  AiAssistantService._internal();

  static const String _apiKey =
      const String openRouterApiKey = '';
  static const String _apiUrl = 'https://openrouter.ai/api/v1/chat/completions';

  /// Detect intent from user input
  AssistantIntent detectIntent(String input) {
    final q = input.toLowerCase();

    // Music/playback
    if (q.contains('play') ||
        q.contains('song') ||
        q.contains('music') ||
        q.contains('listen')) {
      return AssistantIntent.playMusic;
    }

    // AI Chat
    if (q.contains('ai chat') ||
        q.contains('empathetic') ||
        q.contains('medical') ||
        q.contains('flirty') ||
        q.contains('informative')) {
      return AssistantIntent.openAiChat;
    }

    // Battery
    if (q.contains('battery') || q.contains('charge') || q.contains('power')) {
      return AssistantIntent.openBattery;
    }

    // Data
    if (q.contains('data') || q.contains('hotspot') || q.contains('wifi')) {
      return AssistantIntent.openData;
    }

    // Files
    if (q.contains('file') || q.contains('document') || q.contains('pdf')) {
      return AssistantIntent.openFile;
    }

    // Media
    if (q.contains('media') ||
        q.contains('photo') ||
        q.contains('video') ||
        q.contains('image')) {
      return AssistantIntent.openMedia;
    }

    // Contact operations
    if (q.contains('send') && q.contains('contact') ||
        q.contains('share') && q.contains('contact')) {
      return AssistantIntent.shareContact;
    }
    if (q.contains('contact')) return AssistantIntent.openContact;

    // Voice
    if (q.contains('voice') || q.contains('speech') || q.contains('dictate')) {
      return AssistantIntent.openVoice;
    }

    // Spin
    if (q.contains('spin') || q.contains('wheel') || q.contains('daily spin')) {
      return AssistantIntent.openSpin;
    }

    // Games
    if (q.contains('game') || q.contains('runner') || q.contains('play game')) {
      return AssistantIntent.openGame;
    }

    // Friends
    if (q.contains('friend')) return AssistantIntent.openFriends;

    // Messages
    if (q.contains('message') || q.contains('chat') || q.contains('inbox')) {
      return AssistantIntent.openMessages;
    }

    // Notifications
    if (q.contains('notification') || q.contains('notify')) {
      return AssistantIntent.openNotifications;
    }

    return AssistantIntent.unknown;
  }

  /// Extract song query from user input
  String? extractSongQuery(String input) {
    final q = input.toLowerCase();
    const keywords = [
      'play ',
      'search ',
      'find song ',
      'listen to ',
      'song ',
    ];

    for (final kw in keywords) {
      if (q.contains(kw)) {
        return input
            .substring(input.toLowerCase().indexOf(kw) + kw.length)
            .trim();
      }
    }
    return null;
  }

  /// Extract AI chat mode from user input
  String extractChatMode(String input) {
    final q = input.toLowerCase();
    if (q.contains('medical')) return 'medical';
    if (q.contains('flirt')) return 'flirty';
    if (q.contains('informative') || q.contains('info')) return 'informative';
    return 'empathetic'; // default
  }

  /// Ask AI a question using OpenRouter API
  Future<String> askAI(String question) async {
    try {
      final response = await http
          .post(
            Uri.parse(_apiUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
              'HTTP-Referer': 'https://ampup.app',
              'X-Title': 'AmpUp',
            },
            body: jsonEncode({
              'model': 'openai/gpt-4o-mini',
              'messages': [
                {
                  'role': 'system',
                  'content':
                      'You are Amp, a smart voice assistant inside the AmpUp app. '
                          'Answer questions concisely in 1-2 sentences. '
                          'Be friendly and helpful. No markdown formatting.'
                },
                {'role': 'user', 'content': question},
              ],
              'max_tokens': 150,
              'temperature': 0.7,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final content = data['choices'][0]['message']['content'] as String;
        return content;
      }
      return 'Sorry, I couldn\'t process that. Try again!';
    } catch (e) {
      print('AI error: $e');
      return 'Sorry, I couldn\'t process that. Try again!';
    }
  }

  /// Get user-friendly message for an intent
  String getIntentMessage(AssistantIntent intent, String? extra) {
    switch (intent) {
      case AssistantIntent.playMusic:
        return 'Playing "${extra ?? "your music"}" for you! 🎵';
      case AssistantIntent.openAiChat:
        final mode = (extra ?? 'empathetic').capitalize();
        return 'Opening $mode AI Chat! 🤖';
      case AssistantIntent.openBattery:
        return 'Opening Battery Sharing! ⚡';
      case AssistantIntent.openData:
        return 'Opening Data Sharing! 📶';
      case AssistantIntent.openFile:
        return 'Opening File Transfer! 📁';
      case AssistantIntent.openMedia:
        return 'Opening Media Sharing! 🖼️';
      case AssistantIntent.openContact:
        return 'Opening Contact Sharing! 📇';
      case AssistantIntent.shareContact:
        return 'Preparing to share your contact info! 📇';
      case AssistantIntent.openVoice:
        return 'Opening Voice to Doc! 🎙️';
      case AssistantIntent.openSpin:
        return 'Spinning the wheel! 🎡 Good luck!';
      case AssistantIntent.openGame:
        return 'Let\'s play the runner game! 🎮';
      case AssistantIntent.openFriends:
        return 'Opening Friends! 👥';
      case AssistantIntent.openMessages:
        return 'Opening Messages! 💬';
      case AssistantIntent.openNotifications:
        return 'Opening Notifications! 🔔';
      case AssistantIntent.unknown:
      default:
        return 'Thinking... 🤔';
    }
  }
}

extension StringExt on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
