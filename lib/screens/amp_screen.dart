import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/ai_assistant_service.dart';
import '../services/voice_service.dart';
import '../services/contact_action_service.dart';
import 'ai_chat_screen.dart';
import 'music_screen.dart';
import 'battery_screen.dart';
import 'data_screen.dart';
import 'file_screen.dart';
import 'media_screen.dart';
import 'contact_screen.dart';
import 'voice_to_doc_screen.dart';
import 'spin_wheel_screen.dart';
import 'game_screen.dart';
import 'notifications_screen.dart';

// ── Amp message model ────────────────────────────────
class _AmpMsg {
  final String text;
  final bool isUser;
  final bool isLoading;
  const _AmpMsg(
      {required this.text, required this.isUser, this.isLoading = false});
}

class AmpAssistant extends StatefulWidget {
  const AmpAssistant({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const AmpAssistant());
  }

  @override
  State<AmpAssistant> createState() => _AmpAssistantState();
}

class _AmpAssistantState extends State<AmpAssistant>
    with SingleTickerProviderStateMixin {
  static const _speech = MethodChannel('com.dakshitha.battery_barter/speech');

  late final VoiceService _voiceService;
  late final AiAssistantService _aiService;
  late final ContactActionService _contactService;

  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final _msgs = <_AmpMsg>[];

  bool _listening = false;
  bool _thinking = false;
  bool _speaking = false;
  String _partial = '';
  double _soundLevel = 0;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _voiceService = VoiceService();
    _aiService = AiAssistantService();
    _contactService = ContactActionService();

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.12)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _initVoice();
    _speech.setMethodCallHandler(_handleSpeech);
    _addAmpMsg(
        "Hi! I'm Amp 👋 How can I help you today? Try saying:\n• \"Play Arijit Singh\"\n• \"Open AI chat empathetic\"\n• \"Spin the wheel\"\n• Or ask me anything!");
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _ctrl.dispose();
    _scroll.dispose();
    if (_listening) _speech.invokeMethod('stopListening');
    _voiceService.dispose();
    super.dispose();
  }

  Future<void> _initVoice() async {
    await _voiceService.initialize();
    _voiceService.setOnStart(() => setState(() => _speaking = true));
    _voiceService.setOnComplete(() => setState(() => _speaking = false));
  }

  Future<dynamic> _handleSpeech(MethodCall call) async {
    switch (call.method) {
      case 'onPartial':
        setState(() => _partial = call.arguments as String);
        break;
      case 'onResult':
        final text = call.arguments as String;
        if (text.isNotEmpty) {
          setState(() => _partial = '');
          await _stopListening();
          await _process(text);
        }
        break;
      case 'onSoundLevel':
        setState(() => _soundLevel = (call.arguments as double).clamp(0, 10));
        break;
      case 'onError':
        setState(() {
          _listening = false;
          _partial = '';
        });
        break;
    }
  }

  Future<void> _toggleListen() async {
    if (_listening) {
      await _stopListening();
    } else {
      try {
        await _speech.invokeMethod('startListening');
        setState(() {
          _listening = true;
          _partial = '';
        });
      } catch (e) {
        _addAmpMsg('Mic error — try typing instead.');
      }
    }
  }

  Future<void> _stopListening() async {
    try {
      await _speech.invokeMethod('stopListening');
    } catch (_) {}
    setState(() {
      _listening = false;
      _soundLevel = 0;
    });
  }

  void _addUserMsg(String text) {
    setState(() => _msgs.add(_AmpMsg(text: text, isUser: true)));
    _scrollDown();
  }

  void _addAmpMsg(String text, {bool loading = false}) {
    setState(() =>
        _msgs.add(_AmpMsg(text: text, isUser: false, isLoading: loading)));
    _scrollDown();
  }

  void _replaceLastAmp(String text) {
    setState(() {
      if (_msgs.isNotEmpty && !_msgs.last.isUser) {
        _msgs[_msgs.length - 1] = _AmpMsg(text: text, isUser: false);
      }
    });
    _scrollDown();
  }

  void _scrollDown() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(_scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut);
        }
      });

  // ── Main processor ────────────────────────────────
  Future<void> _process(String input) async {
    if (input.trim().isEmpty) return;
    _addUserMsg(input);
    _addAmpMsg('', loading: true);
    setState(() => _thinking = true);

    final intent = _aiService.detectIntent(input);
    String? extra;

    // Pre-extract specific data for certain intents
    if (intent == AssistantIntent.playMusic) {
      extra = _aiService.extractSongQuery(input);
    } else if (intent == AssistantIntent.openAiChat) {
      extra = _aiService.extractChatMode(input);
    }

    final message = _aiService.getIntentMessage(intent, extra);
    _replaceLastAmp(message);
    await _speak(message);

    // Execute the action
    if (mounted) {
      switch (intent) {
        case AssistantIntent.playMusic:
          if (mounted) {
            Navigator.pop(context);
            await Future.delayed(const Duration(milliseconds: 300));
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const MusicScreen()));
          }
          break;

        case AssistantIntent.openAiChat:
          if (mounted) {
            final ctx = context;
            Navigator.pop(ctx);
            Navigator.push(
                ctx, MaterialPageRoute(builder: (_) => const AiChatScreen()));
          }
          break;

        case AssistantIntent.openBattery:
          if (mounted) {
            final ctx = context;
            Navigator.pop(ctx);
            Navigator.push(
                ctx, MaterialPageRoute(builder: (_) => const BatteryScreen()));
          }
          break;

        case AssistantIntent.openData:
          if (mounted) {
            final ctx = context;
            Navigator.pop(ctx);
            Navigator.push(
                ctx, MaterialPageRoute(builder: (_) => const DataScreen()));
          }
          break;

        case AssistantIntent.openFile:
          if (mounted) {
            final ctx = context;
            Navigator.pop(ctx);
            Navigator.push(
                ctx, MaterialPageRoute(builder: (_) => const FileScreen()));
          }
          break;

        case AssistantIntent.openMedia:
          if (mounted) {
            final ctx = context;
            Navigator.pop(ctx);
            Navigator.push(
                ctx, MaterialPageRoute(builder: (_) => const MediaScreen()));
          }
          break;

        case AssistantIntent.openContact:
          if (mounted) {
            final ctx = context;
            Navigator.pop(ctx);
            Navigator.push(
                ctx, MaterialPageRoute(builder: (_) => const ContactScreen()));
          }
          break;

        case AssistantIntent.shareContact:
          // Extract contact name and prepare for sharing
          final targetName = _contactService.extractContactName(input);
          if (targetName != null && mounted) {
            final userContact =
                await _contactService.getCurrentUserContact(context);
            if (userContact != null && mounted) {
              final confirmed =
                  await _contactService.showSendContactConfirmation(
                context,
                targetName,
                userContact,
              );
              if (confirmed && mounted) {
                _replaceLastAmp('Contact shared with $targetName! ✅');
                await _speak('Contact shared!');
              }
            }
          }
          break;

        case AssistantIntent.openVoice:
          if (mounted) {
            final ctx = context;
            Navigator.pop(ctx);
            Navigator.push(ctx,
                MaterialPageRoute(builder: (_) => const VoiceToDocScreen()));
          }
          break;

        case AssistantIntent.openSpin:
          if (mounted) {
            final ctx = context;
            Navigator.pop(ctx);
            Navigator.push(ctx,
                MaterialPageRoute(builder: (_) => const SpinWheelScreen()));
          }
          break;

        case AssistantIntent.openGame:
          if (mounted) {
            final ctx = context;
            Navigator.pop(ctx);
            Navigator.push(
                ctx, MaterialPageRoute(builder: (_) => const GameScreen()));
          }
          break;

        case AssistantIntent.openFriends:
          if (mounted) Navigator.pop(context);
          break;

        case AssistantIntent.openMessages:
          if (mounted) Navigator.pop(context);
          break;

        case AssistantIntent.openNotifications:
          if (mounted) {
            final ctx = context;
            Navigator.pop(ctx);
            Navigator.push(ctx,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()));
          }
          break;

        case AssistantIntent.unknown:
        default:
          // Ask AI
          try {
            final response = await _aiService.askAI(input);
            _replaceLastAmp(response);
            await _speak(response);
          } catch (e) {
            _replaceLastAmp('Sorry, I couldn\'t process that. Try again!');
          }
          break;
      }
    }

    setState(() => _thinking = false);
  }

  Future<void> _speak(String text) async {
    await _voiceService.speak(text);
  }

  void _sendText() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    _process(text);
  }

  Future<void> _showVoiceSettings(BuildContext context) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        title: const Text(
          'Voice Settings',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pitch slider
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Pitch',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        _voiceService.pitch.toStringAsFixed(2),
                        style: const TextStyle(
                          color: Color(0xFF6366F1),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _voiceService.pitch,
                    min: 0.5,
                    max: 2.0,
                    activeColor: const Color(0xFF6366F1),
                    inactiveColor: Colors.white12,
                    onChanged: (value) async {
                      await _voiceService.setPitch(value);
                      setState(() {});
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Speech rate slider
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Speed',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        _voiceService.speechRate.toStringAsFixed(2),
                        style: const TextStyle(
                          color: Color(0xFF6366F1),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _voiceService.speechRate,
                    min: 0.1,
                    max: 1.0,
                    activeColor: const Color(0xFF6366F1),
                    inactiveColor: Colors.white12,
                    onChanged: (value) async {
                      await _voiceService.setSpeechRate(value);
                      setState(() {});
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Test button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () =>
                      _voiceService.speak('Testing voice settings'),
                  child: const Text(
                    'Test Voice',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Done',
              style: TextStyle(color: Color(0xFF6366F1)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
            color: Color(0xFF09090B),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(children: [
          // Handle
          Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 4),
              child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(2)))),

          // Header
          Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(children: [
                // Amp avatar
                AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (_, child) => Transform.scale(
                        scale: _listening ? _pulseAnim.value : 1.0,
                        child: child),
                    child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight),
                            boxShadow: _listening
                                ? [
                                    BoxShadow(
                                        color: const Color(0xFF6366F1)
                                            .withOpacity(0.5),
                                        blurRadius: 12,
                                        spreadRadius: 2)
                                  ]
                                : null),
                        child: Center(
                            child: Text('A',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900))))),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      const Text('Amp',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5)),
                      Text(
                          _listening
                              ? 'Listening...'
                              : _thinking
                                  ? 'Thinking...'
                                  : _speaking
                                      ? 'Speaking...'
                                      : 'Your AmpUp assistant',
                          style: TextStyle(
                              fontSize: 12,
                              color: _listening
                                  ? const Color(0xFF818CF8)
                                  : Colors.white.withOpacity(0.4))),
                    ])),
                // Status indicator
                Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _listening
                            ? const Color(0xFF818CF8)
                            : _thinking
                                ? const Color(0xFFFBBF24)
                                : const Color(0xFF34D399))),
                const SizedBox(width: 12),
                // Settings button
                GestureDetector(
                    onTap: () => _showVoiceSettings(context),
                    child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.08),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.1))),
                        child: Icon(Icons.tune_rounded,
                            size: 18, color: Colors.white.withOpacity(0.6)))),
              ])),

          // Sound wave when listening
          if (_listening)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: SizedBox(
                  height: 28,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(24, (i) {
                        final h =
                            (4 + _soundLevel * 1.5 * (0.5 + (i % 4) * 0.12))
                                .clamp(2.0, 26.0);
                        return AnimatedContainer(
                            duration: const Duration(milliseconds: 80),
                            width: 3,
                            height: h,
                            margin: const EdgeInsets.symmetric(horizontal: 1.5),
                            decoration: BoxDecoration(
                                color: const Color(0xFF818CF8)
                                    .withOpacity(0.5 + (i % 3) * 0.15),
                                borderRadius: BorderRadius.circular(3)));
                      }))),
            ),

          // Partial text
          if (_partial.isNotEmpty)
            Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(_partial,
                    style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: Colors.white.withOpacity(0.4)))),

          Divider(height: 1, color: Colors.white.withOpacity(0.06)),

          // Messages
          Expanded(
              child: ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  itemCount: _msgs.length,
                  itemBuilder: (_, i) {
                    final msg = _msgs[i];
                    final isUser = msg.isUser;
                    return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                            mainAxisAlignment: isUser
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (!isUser) ...[
                                Container(
                                    width: 28,
                                    height: 28,
                                    decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(colors: [
                                          Color(0xFF6366F1),
                                          Color(0xFF818CF8)
                                        ])),
                                    child: const Center(
                                        child: Text('A',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w800)))),
                                const SizedBox(width: 8),
                              ],
                              Flexible(
                                  child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(
                                          color: isUser
                                              ? const Color(0xFF6366F1)
                                              : Colors.white.withOpacity(0.07),
                                          borderRadius: BorderRadius.only(
                                              topLeft:
                                                  const Radius.circular(18),
                                              topRight:
                                                  const Radius.circular(18),
                                              bottomLeft: Radius.circular(
                                                  isUser ? 18 : 4),
                                              bottomRight: Radius.circular(
                                                  isUser ? 4 : 18))),
                                      child: msg.isLoading
                                          ? _LoadingDots()
                                          : Text(msg.text,
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  height: 1.45,
                                                  color: isUser
                                                      ? Colors.white
                                                      : Colors.white
                                                          .withOpacity(0.85))))),
                              if (isUser) const SizedBox(width: 8),
                            ]));
                  })),

          // Input bar
          Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: BoxDecoration(
                  color: const Color(0xFF0D0D0F),
                  border: Border(
                      top: BorderSide(color: Colors.white.withOpacity(0.06)))),
              child: Row(children: [
                // Mic button
                GestureDetector(
                    onTap: _toggleListen,
                    child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _listening
                                ? const Color(0xFF6366F1)
                                : const Color(0xFF6366F1).withOpacity(0.12),
                            boxShadow: _listening
                                ? [
                                    BoxShadow(
                                        color: const Color(0xFF6366F1)
                                            .withOpacity(0.4),
                                        blurRadius: 10)
                                  ]
                                : null),
                        child: Icon(
                            _listening ? Icons.stop_rounded : Icons.mic_rounded,
                            color: _listening
                                ? Colors.white
                                : const Color(0xFF818CF8),
                            size: 22))),
                const SizedBox(width: 10),
                // Text input
                Expanded(
                    child: Container(
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.08))),
                        child: TextField(
                            controller: _ctrl,
                            style: const TextStyle(
                                fontSize: 14, color: Colors.white),
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendText(),
                            decoration: InputDecoration(
                                hintText: 'Ask Amp anything...',
                                hintStyle: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.25)),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10))))),
                const SizedBox(width: 10),
                // Send button
                GestureDetector(
                    onTap: _thinking ? null : _sendText,
                    child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: _thinking
                                ? null
                                : const LinearGradient(colors: [
                                    Color(0xFF6366F1),
                                    Color(0xFF818CF8)
                                  ]),
                            color: _thinking ? Colors.white12 : null),
                        child: _thinking
                            ? const Center(
                                child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        color: Color(0xFF818CF8),
                                        strokeWidth: 2)))
                            : const Icon(Icons.arrow_upward_rounded,
                                color: Colors.white, size: 20))),
              ])),
        ]));
  }
}

// ── Loading dots ─────────────────────────────────────
class _LoadingDots extends StatefulWidget {
  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final o = ((_c.value * 3 - i) % 1.0);
            final s = o < 0.5 ? 0.6 + o * 0.8 : 0.6 + (1 - o) * 0.8;
            return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        const Color(0xFF818CF8).withOpacity(0.35 + s * 0.45)));
          })));
}

// ── String extension ─────────────────────────────────
extension StringExt on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
