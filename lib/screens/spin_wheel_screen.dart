import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class _Segment {
  final String label;
  final int credits;
  final Color color;
  const _Segment(this.label, this.credits, this.color);
}

const _segments = [
  _Segment('5 cr', 5, Color(0xFF6366F1)),
  _Segment('LOSE', 0, Color(0xFF374151)),
  _Segment('15 cr', 15, Color(0xFF059669)),
  _Segment('LOSE', 0, Color(0xFF374151)),
  _Segment('10 cr', 10, Color(0xFF2563EB)),
  _Segment('LOSE', 0, Color(0xFF374151)),
  _Segment('30 cr', 30, Color(0xFFD97706)),
  _Segment('LOSE', 0, Color(0xFF374151)),
  _Segment('20 cr', 20, Color(0xFFDC2626)),
  _Segment('LOSE', 0, Color(0xFF374151)),
  _Segment('50 cr', 50, Color(0xFFFFD700)),
  _Segment('LOSE', 0, Color(0xFF374151)),
];

class SpinWheelScreen extends StatefulWidget {
  const SpinWheelScreen({super.key});
  @override
  State<SpinWheelScreen> createState() => _SpinWheelScreenState();
}

class _SpinWheelScreenState extends State<SpinWheelScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  final _rng = Random();

  bool _spinning = false;
  bool _hasSpunToday = false;
  bool _showResult = false;
  int _wonCredits = 0;
  int _userCredits = 0;
  double _currentAngle = 0;
  int _landedIndex = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 4500));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.decelerate);
    _anim.addListener(() {
      setState(() => _currentAngle = _anim.value);
    });
    _ctrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) _onSpinEnd();
    });
    _loadState();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _loadState() async {
    final auth = context.read<AuthService>();
    final fs = context.read<FirestoreService>();
    if (!auth.isLoggedIn) return;
    final user = fs.currentUser;
    setState(() => _userCredits = user?.credits ?? 0);

    // Check last spin date
    final lastSpin = user?.lastSpinDate;
    if (lastSpin != null) {
      final now = DateTime.now();
      final last = lastSpin;
      if (now.year == last.year &&
          now.month == last.month &&
          now.day == last.day) {
        setState(() => _hasSpunToday = true);
      }
    }
  }

  Future<void> _spin() async {
    if (_spinning || _hasSpunToday) return;
    HapticFeedback.mediumImpact();

    // Pick random segment weighted toward losses
    final weights = _segments.map((s) => s.credits == 0 ? 40 : 10).toList();
    final total = weights.reduce((a, b) => a + b);
    int pick = _rng.nextInt(total);
    int idx = 0;
    for (int i = 0; i < weights.length; i++) {
      pick -= weights[i];
      if (pick < 0) {
        idx = i;
        break;
      }
    }

    // Calculate target angle
    final segAngle = 2 * pi / _segments.length;
    final targetSegAngle = segAngle * idx;
    final spins = 5 + _rng.nextInt(3); // 5-7 full rotations
    final targetAngle =
        spins * 2 * pi + (2 * pi - targetSegAngle - segAngle / 2);

    setState(() {
      _spinning = true;
      _showResult = false;
    });

    _ctrl.reset();
    _anim =
        Tween<double>(begin: _currentAngle, end: _currentAngle + targetAngle)
            .animate(CurvedAnimation(parent: _ctrl, curve: Curves.decelerate));
    _anim.addListener(() => setState(() => _currentAngle = _anim.value));
    _ctrl.forward();
    _landedIndex = idx;
  }

  Future<void> _onSpinEnd() async {
    HapticFeedback.heavyImpact();
    final won = _segments[_landedIndex].credits;

    final auth = context.read<AuthService>();
    final fs = context.read<FirestoreService>();
    if (auth.isLoggedIn) {
      final updates = <String, dynamic>{
        'last_spin_date': DateTime.now(),
      };
      if (won > 0) {
        updates['credits'] = _userCredits + won;
        setState(() => _userCredits += won);
      }
      await fs.updateUserFields(auth.uid, updates);
    }

    setState(() {
      _spinning = false;
      _hasSpunToday = true;
      _showResult = true;
      _wonCredits = won;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0612),
      body: SafeArea(
        child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
            child: Row(children: [
              IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded,
                      color: Colors.white),
                  onPressed: () => Navigator.pop(context)),
              const Expanded(
                  child: Text('Daily Spin',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5))),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: const Color(0xFFFFD700).withOpacity(0.4),
                            blurRadius: 8)
                      ]),
                  child: Row(children: [
                    const Icon(Icons.bolt_rounded,
                        color: Colors.black, size: 14),
                    const SizedBox(width: 4),
                    Text('$_userCredits',
                        style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 13)),
                  ])),
            ]),
          ),

          const SizedBox(height: 8),
          Text(_hasSpunToday ? 'Come back tomorrow!' : 'Spin once per day',
              style: TextStyle(
                  fontSize: 13, color: Colors.white.withOpacity(0.4))),

          const Spacer(),

          // Pointer
          const Icon(Icons.arrow_drop_down_rounded,
              color: Color(0xFFFFD700), size: 48),

          // Wheel
          SizedBox(
            width: size.width * 0.82,
            height: size.width * 0.82,
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) => Transform.rotate(
                angle: _currentAngle,
                child:
                    CustomPaint(painter: _WheelPainter(), child: Container()),
              ),
            ),
          ),

          const Spacer(),

          // Result
          AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: _showResult
                  ? Container(
                      key: ValueKey(_wonCredits),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14),
                      decoration: BoxDecoration(
                          color: _wonCredits > 0
                              ? const Color(0xFFFFD700).withOpacity(0.12)
                              : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: _wonCredits > 0
                                  ? const Color(0xFFFFD700).withOpacity(0.5)
                                  : Colors.white.withOpacity(0.08))),
                      child: Text(
                          _wonCredits > 0
                              ? '🎉 You won +$_wonCredits credits!'
                              : 'Better luck tomorrow!',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: _wonCredits > 0
                                  ? const Color(0xFFFFD700)
                                  : Colors.white.withOpacity(0.4))))
                  : const SizedBox(height: 52)),

          const SizedBox(height: 24),

          // Spin button
          GestureDetector(
            onTap: _spinning || _hasSpunToday ? null : _spin,
            child: Container(
                margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                height: 64,
                decoration: BoxDecoration(
                    gradient: _spinning || _hasSpunToday
                        ? null
                        : const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight),
                    color: _spinning || _hasSpunToday
                        ? Colors.white.withOpacity(0.06)
                        : null,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: _spinning || _hasSpunToday
                        ? null
                        : [
                            BoxShadow(
                                color: const Color(0xFFFFD700).withOpacity(0.5),
                                blurRadius: 24,
                                offset: const Offset(0, 6))
                          ]),
                child: Center(
                    child: _spinning
                        ? const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                                color: Colors.black, strokeWidth: 3))
                        : Text(_hasSpunToday ? 'Spun Today' : 'S P I N',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 4,
                                color: _hasSpunToday
                                    ? Colors.white.withOpacity(0.2)
                                    : Colors.black)))),
          ),
        ]),
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final segAngle = 2 * pi / _segments.length;

    for (int i = 0; i < _segments.length; i++) {
      final seg = _segments[i];
      final startAngle = i * segAngle - pi / 2;

      // Segment fill
      final paint = Paint()
        ..color = seg.color
        ..style = PaintingStyle.fill;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
          startAngle, segAngle, true, paint);

      // Segment border
      final borderPaint = Paint()
        ..color = Colors.black.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
          startAngle, segAngle, true, borderPaint);

      // Label
      final midAngle = startAngle + segAngle / 2;
      final labelRadius = radius * 0.68;
      final labelX = center.dx + labelRadius * cos(midAngle);
      final labelY = center.dy + labelRadius * sin(midAngle);

      canvas.save();
      canvas.translate(labelX, labelY);
      canvas.rotate(midAngle + pi / 2);

      final tp = TextPainter(
          text: TextSpan(
              text: seg.label,
              style: TextStyle(
                  color: seg.credits == 0
                      ? Colors.white.withOpacity(0.3)
                      : Colors.white,
                  fontSize: seg.credits == 50 ? 13 : 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3)),
          textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }

    // Center circle
    final centerPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
      ).createShader(Rect.fromCircle(center: center, radius: 28));
    canvas.drawCircle(center, 28, centerPaint);

    // Center border
    canvas.drawCircle(
        center,
        28,
        Paint()
          ..color = Colors.black.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);

    // AMP text in center
    final ampTp = TextPainter(
        text: const TextSpan(
            text: 'AMP',
            style: TextStyle(
                color: Colors.black,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1)),
        textDirection: TextDirection.ltr);
    ampTp.layout();
    ampTp.paint(canvas,
        Offset(center.dx - ampTp.width / 2, center.dy - ampTp.height / 2));
  }

  @override
  bool shouldRepaint(_WheelPainter o) => false;
}
