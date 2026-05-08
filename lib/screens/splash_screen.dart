import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'welcome_screen.dart';
import 'dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoCtrl;
  late AnimationController _textCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _textFade;
  late Animation<double> _textSlide;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _logoCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _textCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _pulseCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..repeat(reverse: true);
    _logoScale = Tween<double>(begin: 0.6, end: 1.0)
        .animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));
    _logoFade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _logoCtrl, curve: const Interval(0, 0.5)));
    _textFade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));
    _textSlide = Tween<double>(begin: 20, end: 0)
        .animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));
    _pulse = Tween<double>(begin: 0.8, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _logoCtrl.forward().then((_) => _textCtrl.forward());
    _initialize();
  }

  Future<void> _initialize() async {
    // Always wait for animation first
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    bool isLoggedIn = false;

    // Check auth with hard timeout — never hang
    try {
      final auth = context.read<AuthService>();
      isLoggedIn = await Future.value(auth.isLoggedIn)
          .timeout(const Duration(seconds: 3), onTimeout: () => false);
    } catch (_) {
      isLoggedIn = false;
    }

    if (!mounted) return;

    if (isLoggedIn) {
      // Load user data with timeout
      try {
        final auth = context.read<AuthService>();
        final fs = context.read<FirestoreService>();
        await fs
            .loadUser(auth.uid)
            .timeout(const Duration(seconds: 4), onTimeout: () {});
      } catch (_) {}

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
    }
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A0E21), Color(0xFF0D1B3E), Color(0xFF0F2460)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -80,
              right: -80,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      const Color(0xFF2B5CE6).withOpacity(0.2),
                      Colors.transparent,
                    ])),
              ),
            ),
            Positioned(
              bottom: -60,
              left: -60,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      const Color(0xFF7C3AED).withOpacity(0.15),
                      Colors.transparent,
                    ])),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: Listenable.merge([_logoScale, _logoFade]),
                    builder: (_, child) => FadeTransition(
                        opacity: _logoFade,
                        child: Transform.scale(
                            scale: _logoScale.value, child: child)),
                    child: SizedBox(
                      width: 120,
                      height: 120,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: _pulse,
                            builder: (_, __) => Container(
                              width: 120 * _pulse.value,
                              height: 120 * _pulse.value,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: const Color(0xFF3B82F6)
                                          .withOpacity(
                                              0.2 * (2 - _pulse.value)),
                                      width: 1)),
                            ),
                          ),
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF2563EB),
                                    Color(0xFF1D4ED8),
                                    Color(0xFF1E40AF),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                      color: const Color(0xFF2B5CE6)
                                          .withOpacity(0.6),
                                      blurRadius: 30,
                                      spreadRadius: 2)
                                ]),
                          ),
                          CustomPaint(
                              size: const Size(30, 40),
                              painter: _LightningPainter()),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  AnimatedBuilder(
                    animation: Listenable.merge([_textFade, _textSlide]),
                    builder: (_, child) => Opacity(
                        opacity: _textFade.value,
                        child: Transform.translate(
                            offset: Offset(0, _textSlide.value), child: child)),
                    child: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          Color(0xFF60A5FA),
                          Color(0xFFE0F2FE),
                          Color(0xFF818CF8)
                        ],
                      ).createShader(bounds),
                      child: const Text('AmpUp',
                          style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -1.5)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  AnimatedBuilder(
                    animation: _textFade,
                    builder: (_, child) =>
                        Opacity(opacity: _textFade.value, child: child),
                    child: const Text('Share Power. Share Data.',
                        style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.3,
                            fontWeight: FontWeight.w400)),
                  ),
                  const SizedBox(height: 60),
                  AnimatedBuilder(
                    animation: _textFade,
                    builder: (_, child) =>
                        Opacity(opacity: _textFade.value, child: child),
                    child: SizedBox(
                      width: 100,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                            backgroundColor: Colors.white.withOpacity(0.08),
                            color: const Color(0xFF3B82F6),
                            minHeight: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LightningPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFFFFF), Color(0xFFBAE6FD)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width * 0.72, 0)
      ..lineTo(size.width * 0.28, size.height * 0.45)
      ..lineTo(size.width * 0.55, size.height * 0.45)
      ..lineTo(size.width * 0.28, size.height)
      ..lineTo(size.width * 0.72, size.height * 0.55)
      ..lineTo(size.width * 0.45, size.height * 0.55)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_LightningPainter o) => false;
}
