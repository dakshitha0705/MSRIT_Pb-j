import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'ai_chat_history_screen.dart';

class _Msg {
  final String role;
  final String text;
  final bool loading;
  const _Msg({required this.role, required this.text, this.loading = false});
}

class _Mode {
  final String key, label, description, systemPrompt;
  final Color color;
  final IconData icon;
  const _Mode(
      {required this.key,
      required this.label,
      required this.description,
      required this.color,
      required this.icon,
      required this.systemPrompt});
}

const _modes = [
  _Mode(
    key: 'empathetic',
    label: 'Empathetic',
    description: 'Warm, caring & supportive',
    color: Color(0xFF3B82F6),
    icon: Icons.favorite_rounded,
    systemPrompt:
        'You are a warm, deeply empathetic companion. Listen carefully, '
        'validate feelings, offer emotional support, and respond with compassion. '
        'Never dismiss emotions. Be gentle, kind, and present. '
        'Keep responses conversational and human, not clinical. Be concise — 2-3 sentences max. Do NOT show thinking or reasoning. Reply directly.',
  ),
  _Mode(
    key: 'medical',
    label: 'Medical',
    description: 'Health information & guidance',
    color: Color(0xFF22C55E),
    icon: Icons.medical_services_rounded,
    systemPrompt:
        'You are a knowledgeable medical information assistant. Provide clear, '
        'accurate health information. Always recommend consulting a doctor for '
        'diagnosis or treatment. Be precise and use simple language. Keep it brief — 2-3 sentences.',
  ),
  _Mode(
    key: 'flirty',
    label: 'Flirty',
    description: 'Playful, witty & charming',
    color: Color(0xFFEC4899),
    icon: Icons.auto_awesome_rounded,
    systemPrompt:
        'You are playful, witty, charming and lightly flirtatious in a fun, '
        'tasteful way. Use humour, compliments and banter. '
        'Keep it fun, light-hearted and classy. Never be inappropriate. Be snappy — 1-2 sentences.',
  ),
  _Mode(
    key: 'informative',
    label: 'Informative',
    description: 'Facts, depth & precision',
    color: Color(0xFF8B5CF6),
    icon: Icons.psychology_rounded,
    systemPrompt:
        'You are a precise, knowledgeable assistant focused on accuracy. '
        'Provide well-structured, factual responses with examples. '
        'Be thorough but concise. Every sentence should add value. Max 3 sentences. Do NOT show thinking or reasoning. Reply directly.',
  ),
];

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});
  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  static const _speechChannel =
      MethodChannel('com.dakshitha.battery_barter/speech');
  static const _apiKey =
      const String openRouterApiKey = '';
  static const _apiUrl = 'https://openrouter.ai/api/v1/chat/completions';

  _Mode _mode = _modes[0];
  bool _modeChosen = false;
  String? _sessionId;
  final _msgs = <_Msg>[];
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  bool _listening = false;
  bool _thinking = false;
  String _partial = '';
  double _soundLevel = 0;

  @override
  void initState() {
    super.initState();
    _speechChannel.setMethodCallHandler(_handleSpeech);
  }

  @override
  void dispose() {
    if (_listening) _speechChannel.invokeMethod('stopListening');
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
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
          _ctrl.text = text;
          await _send();
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

  Future<void> _toggleListening() async {
    if (_listening) {
      await _stopListening();
    } else {
      try {
        await _speechChannel.invokeMethod('startListening');
        setState(() {
          _listening = true;
          _partial = '';
        });
      } catch (e) {
        _snack('Mic error: $e');
      }
    }
  }

  Future<void> _stopListening() async {
    try {
      await _speechChannel.invokeMethod('stopListening');
    } catch (_) {}
    setState(() {
      _listening = false;
      _soundLevel = 0;
    });
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _thinking) return;
    _ctrl.clear();
    setState(() {
      _msgs.add(_Msg(role: 'user', text: text));
      _msgs.add(const _Msg(role: 'assistant', text: '', loading: true));
      _thinking = true;
    });
    _scrollToBottom();
    _saveMessage('user', text);

    try {
      final response = await _callAI(text);
      setState(() {
        _msgs[_msgs.length - 1] = _Msg(role: 'assistant', text: response);
        _thinking = false;
      });
      _saveMessage('ai', response);
    } catch (e) {
      setState(() {
        _msgs[_msgs.length - 1] = const _Msg(role: 'assistant', text: 'Error: \$e');
        _thinking = false;
      });
    }
    _scrollToBottom();
  }

  Future<String> _callAI(String userText) async {
    final messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': _mode.systemPrompt},
    ];
    for (final msg in _msgs.where((m) => !m.loading && m.text.isNotEmpty)) {
      messages.add({
        'role': msg.role == 'user' ? 'user' : 'assistant',
        'content': msg.text,
      });
    }
    messages.add({'role': 'user', 'content': userText});

    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
        'HTTP-Referer': 'https://ampup.app',
        'X-Title': 'AmpUp',
      },
      body: jsonEncode({
        'model': 'openai/gpt-4o-mini',
        'messages': messages,
        'max_tokens': 300,
        'temperature': 0.9,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      String text = data['choices'][0]['message']['content'] as String;
      // Strip all possible thinking formats
      text = text.replaceAll(RegExp(r'<think>[\s\S]*?</think>'), '');
      text = text.replaceAll(RegExp(r'<thinking>[\s\S]*?</thinking>'), '');
      text = text.replaceAll(RegExp(r'<reasoning>[\s\S]*?</reasoning>'), '');
      text = text.replaceAll(RegExp(r'\[thinking\][\s\S]*?\[/thinking\]'), '');
      text = text.replaceAll(RegExp(r'\*\*Thinking\*\*[\s\S]*?\n\n'), '');
      text = text.replaceAll(
          RegExp(
              r'^(Thinking|Reasoning|Let me think|Let me consider)[:\s][\s\S]*?\n\n',
              multiLine: false),
          '');
      text = text.replaceAll(RegExp(r'^(Response:|Answer:|Assistant:)\s*'), '');
      return text.trim();
    } else {
      final error = jsonDecode(response.body);
      throw Exception(
          error['error']['message'] ?? 'Status ${response.statusCode}');
    }
  }

  Future<void> _saveMessage(String role, String text) async {
    try {
      final auth = context.read<AuthService>();
      if (!auth.isLoggedIn) return;
      final db = FirebaseFirestore.instance;
      // Create session if needed
      if (_sessionId == null) {
        final doc = await db
            .collection('users')
            .doc(auth.uid)
            .collection('ai_chats')
            .add({
          'mode': _mode.key,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
        _sessionId = doc.id;
      }
      final chatRef = db
          .collection('users')
          .doc(auth.uid)
          .collection('ai_chats')
          .doc(_sessionId);
      await db
          .collection('users')
          .doc(auth.uid)
          .collection('ai_chats')
          .doc(_sessionId)
          .collection('messages')
          .add({
        'role': role,
        'text': text,
        'created_at': FieldValue.serverTimestamp(),
      });
      await chatRef.set({
        'mode': _mode.key,
        'updated_at': FieldValue.serverTimestamp(),
        if (role == 'user') 'last_user_message': text,
        if (role != 'user') 'last_assistant_response': text,
      }, SetOptions(merge: true));
    } catch (e) {/* ignore */}
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A0F1E) : const Color(0xFFF0F4FF),
      body: SafeArea(
        child: Column(children: [
          _buildHeader(isDark),
          Expanded(
              child: !_modeChosen
                  ? _buildModePicker(isDark)
                  : _buildChatArea(isDark)),
          if (_modeChosen) _buildInputBar(isDark),
        ]),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
      decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0D1224) : Colors.white,
          border: Border(
              bottom: BorderSide(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.black.withOpacity(0.06)))),
      child: Row(children: [
        IconButton(
            icon: Icon(Icons.arrow_back_ios_rounded,
                color: isDark ? Colors.white : const Color(0xFF0F172A)),
            onPressed: () => Navigator.pop(context)),
        Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: _mode.color.withOpacity(0.15)),
            child: Icon(_mode.icon, color: _mode.color, size: 20)),
        const SizedBox(width: 10),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('AI Chat',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A))),
          Text(_modeChosen ? '${_mode.label} Mode' : 'Select a mode to begin',
              style: TextStyle(
                  fontSize: 11,
                  color: _modeChosen
                      ? _mode.color
                      : (isDark
                          ? Colors.white.withOpacity(0.4)
                          : Colors.black.withOpacity(0.4)))),
        ])),
        if (_modeChosen) ...[
          IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              icon: Icon(Icons.history_rounded,
                  color: isDark ? Colors.white60 : const Color(0xFF52525B),
                  size: 22),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          AiChatHistoryScreen(initialMode: _mode.key)))),
          GestureDetector(
              onTap: () => setState(() {
                    _modeChosen = false;
                    _msgs.clear();
                  }),
              child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: _mode.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _mode.color.withOpacity(0.25))),
                  child: Text('Switch',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _mode.color)))),
        ],
      ]),
    );
  }

  Widget _buildModePicker(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text('AI Chat',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.8)),
          const SizedBox(height: 4),
          Text('Choose how you want the AI to respond',
              style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? Colors.white.withOpacity(0.45)
                      : Colors.black.withOpacity(0.45))),
          const SizedBox(height: 28),
          ..._modes.map((m) {
            final sel = _mode.key == m.key;
            return GestureDetector(
              onTap: () => setState(() => _mode = m),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: sel
                        ? m.color.withOpacity(isDark ? 0.12 : 0.07)
                        : (isDark
                            ? Colors.white.withOpacity(0.04)
                            : Colors.white),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: sel
                            ? m.color
                            : (isDark
                                ? Colors.white.withOpacity(0.07)
                                : Colors.black.withOpacity(0.07)),
                        width: sel ? 1.5 : 1)),
                child: Row(children: [
                  Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                          color: m.color.withOpacity(sel ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(12)),
                      child: Icon(m.icon, color: m.color, size: 22)),
                  const SizedBox(width: 14),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(m.label,
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: sel
                                    ? m.color
                                    : (isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A)))),
                        const SizedBox(height: 2),
                        Text(m.description,
                            style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.white.withOpacity(0.4)
                                    : Colors.black.withOpacity(0.4))),
                      ])),
                  AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: sel ? m.color : Colors.transparent,
                          border: Border.all(
                              color: sel
                                  ? m.color
                                  : (isDark
                                      ? Colors.white.withOpacity(0.2)
                                      : Colors.black.withOpacity(0.15)),
                              width: 1.5)),
                      child: sel
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 14)
                          : null),
                ]),
              ),
            );
          }),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => setState(() => _modeChosen = true),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    _mode.color,
                    Color.lerp(_mode.color, Colors.indigo, 0.5)!
                  ], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: _mode.color.withOpacity(0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 5))
                  ]),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(_mode.icon, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Text('Start ${_mode.label} Chat',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
              ]),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildChatArea(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        // Subtle geometric background
        color: isDark ? const Color(0xFF0A0F1E) : const Color(0xFFF0F4FF),
      ),
      child: Stack(children: [
        // Background pattern
        Positioned.fill(
            child: CustomPaint(
                painter: _BgPainter(isDark: isDark, color: _mode.color))),
        ListView.builder(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          itemCount: _msgs.length + (_listening && _partial.isNotEmpty ? 1 : 0),
          itemBuilder: (_, i) {
            if (i == _msgs.length && _listening && _partial.isNotEmpty) {
              return _buildBubble(_Msg(role: 'user', text: _partial), isDark,
                  isPartial: true);
            }
            return _buildBubble(_msgs[i], isDark);
          },
        ),
        // Empty state
        if (_msgs.isEmpty && !_listening)
          Center(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                      color: _mode.color.withOpacity(0.1),
                      shape: BoxShape.circle),
                  child: Icon(_mode.icon, color: _mode.color, size: 30)),
              const SizedBox(height: 14),
              Text(_mode.label,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A))),
              const SizedBox(height: 6),
              Text('Start a conversation',
                  style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? Colors.white.withOpacity(0.35)
                          : Colors.black.withOpacity(0.35))),
            ],
          )),
      ]),
    );
  }

  Widget _buildBubble(_Msg msg, bool isDark, {bool isPartial = false}) {
    final isUser = msg.role == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                    color: _mode.color.withOpacity(0.15),
                    shape: BoxShape.circle),
                child: Icon(_mode.icon, color: _mode.color, size: 16)),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                  color: isUser
                      ? _mode.color
                      : (isDark ? const Color(0xFF1A2035) : Colors.white),
                  borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18)),
                  border: isUser
                      ? null
                      : Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.06)
                              : Colors.black.withOpacity(0.06)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ]),
              child: msg.loading
                  ? _TypingIndicator(color: _mode.color)
                  : Text(msg.text,
                      style: TextStyle(
                          fontSize: 14.5,
                          height: 1.55,
                          fontStyle:
                              isPartial ? FontStyle.italic : FontStyle.normal,
                          color: isUser
                              ? Colors.white
                              : (isPartial
                                  ? (isDark
                                      ? Colors.white.withOpacity(0.4)
                                      : Colors.black.withOpacity(0.3))
                                  : (isDark
                                      ? Colors.white.withOpacity(0.9)
                                      : const Color(0xFF0F172A))))),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildInputBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0D1224) : Colors.white,
          border: Border(
              top: BorderSide(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.black.withOpacity(0.06)))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_listening)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(
                height: 24,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(20, (i) {
                    final h = (4 + _soundLevel * 1.8 * (0.5 + (i % 4) * 0.12))
                        .clamp(2.0, 22.0);
                    return AnimatedContainer(
                        duration: const Duration(milliseconds: 80),
                        width: 3,
                        height: h,
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        decoration: BoxDecoration(
                            color:
                                _mode.color.withOpacity(0.5 + (i % 3) * 0.15),
                            borderRadius: BorderRadius.circular(3)));
                  }),
                ),
              ),
            ),
          Row(children: [
            GestureDetector(
                onTap: _toggleListening,
                child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _listening
                            ? _mode.color
                            : _mode.color.withOpacity(0.1),
                        boxShadow: _listening
                            ? [
                                BoxShadow(
                                    color: _mode.color.withOpacity(0.4),
                                    blurRadius: 10,
                                    spreadRadius: 1)
                              ]
                            : null),
                    child: Icon(
                        _listening ? Icons.stop_rounded : Icons.mic_rounded,
                        color: _listening ? Colors.white : _mode.color,
                        size: 22))),
            const SizedBox(width: 10),
            Expanded(
                child: Container(
                    decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.08)
                                : _mode.color.withOpacity(0.15))),
                    child: TextField(
                        controller: _ctrl,
                        maxLines: 4,
                        minLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A)),
                        decoration: InputDecoration(
                            hintText:
                                _listening ? 'Listening...' : 'Message...',
                            hintStyle: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? Colors.white.withOpacity(0.25)
                                    : Colors.black.withOpacity(0.3)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10))))),
            const SizedBox(width: 10),
            GestureDetector(
                onTap: _thinking ? null : _send,
                child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: _thinking
                            ? null
                            : LinearGradient(colors: [
                                _mode.color,
                                Color.lerp(_mode.color, Colors.indigo, 0.5)!
                              ]),
                        color: _thinking
                            ? (isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.black.withOpacity(0.04))
                            : null,
                        boxShadow: _thinking
                            ? null
                            : [
                                BoxShadow(
                                    color: _mode.color.withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3))
                              ]),
                    child: _thinking
                        ? Center(
                            child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    color: _mode.color, strokeWidth: 2)))
                        : const Icon(Icons.arrow_upward_rounded,
                            color: Colors.white, size: 20))),
          ]),
        ],
      ),
    );
  }
}

// ── Subtle geometric background painter ────────────
class _BgPainter extends CustomPainter {
  final bool isDark;
  final Color color;
  const _BgPainter({required this.isDark, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color.withOpacity(isDark ? 0.03 : 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw subtle grid dots
    for (double x = 0; x < size.width; x += 28) {
      for (double y = 0; y < size.height; y += 28) {
        canvas.drawCircle(Offset(x, y), 1.5,
            Paint()..color = color.withOpacity(isDark ? 0.08 : 0.06));
      }
    }

    // Draw a few subtle circles
    canvas.drawCircle(
        Offset(size.width * 0.85, size.height * 0.12), size.width * 0.18, p);
    canvas.drawCircle(
        Offset(size.width * 0.10, size.height * 0.75), size.width * 0.14, p);
  }

  @override
  bool shouldRepaint(_BgPainter o) => o.color != color;
}

// ── Typing indicator ────────────────────────────────
class _TypingIndicator extends StatefulWidget {
  final Color color;
  const _TypingIndicator({required this.color});
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final offset = ((_ctrl.value * 3 - i) % 1.0);
          final scale =
              offset < 0.5 ? 0.6 + offset * 0.8 : 0.6 + (1 - offset) * 0.8;
          return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withOpacity(0.35 + scale * 0.45)));
        }),
      ),
    );
  }
}
