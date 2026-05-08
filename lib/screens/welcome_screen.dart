import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/app_button.dart';
import 'signup_screen.dart';
import 'signin_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _floatCtrl;
  late AnimationController _fadeCtrl;
  late Animation<double> _pulse;
  late Animation<double> _float;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _pulseCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _floatCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000))
      ..repeat(reverse: true);
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _pulse = Tween<double>(begin: 0.95, end: 1.05)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _float = Tween<double>(begin: -8, end: 8)
        .animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));
    _fade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut));
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _floatCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0E21),
              Color(0xFF0D1B3E),
              Color(0xFF0F2460),
            ],
          ),
        ),
        child: Stack(
          children: [
            // ── Background orbs ──────────────────────────
            Positioned(
              top: -60,
              right: -60,
              child: _Orb(
                  size: 220, color: const Color(0xFF2B5CE6), opacity: 0.18),
            ),
            Positioned(
              top: size.height * 0.25,
              left: -80,
              child: _Orb(
                  size: 180, color: const Color(0xFF7C3AED), opacity: 0.15),
            ),
            Positioned(
              bottom: 100,
              right: -40,
              child: _Orb(
                  size: 160, color: const Color(0xFF0EA5E9), opacity: 0.12),
            ),
            // ── Floating particles ───────────────────────
            ..._buildParticles(size),
            // ── Main content ─────────────────────────────
            FadeTransition(
              opacity: _fade,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      const Spacer(flex: 2),
                      // Logo
                      AnimatedBuilder(
                        animation: Listenable.merge([_pulse, _float]),
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _float.value),
                            child: Transform.scale(
                              scale: _pulse.value,
                              child: child,
                            ),
                          );
                        },
                        child: _AmpUpLogo(),
                      ),
                      const SizedBox(height: 36),
                      // App name
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            Color(0xFF60A5FA),
                            Color(0xFFE0F2FE),
                            Color(0xFF818CF8),
                          ],
                        ).createShader(bounds),
                        child: const Text(
                          'AmpUp',
                          style: TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -2,
                            height: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Tagline
                      const Text(
                        'Share Power. Share Data.\nStay Connected.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF94A3B8),
                          height: 1.6,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Feature pills
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          _FeaturePill(
                              icon: Icons.battery_charging_full_rounded,
                              label: 'Battery'),
                          _FeaturePill(
                              icon: Icons.wifi_tethering_rounded,
                              label: 'Data'),
                          _FeaturePill(
                              icon: Icons.folder_rounded, label: 'Files'),
                          _FeaturePill(
                              icon: Icons.auto_graph_rounded, label: 'AI'),
                        ],
                      ),
                      const Spacer(flex: 3),
                      // Buttons
                      _GlowButton(
                        label: 'Get Started',
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SignupScreen())),
                      ),
                      const SizedBox(height: 14),
                      // Sign in text button
                      GestureDetector(
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SigninScreen())),
                        child: Container(
                          width: double.infinity,
                          height: 54,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.15),
                              width: 1,
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              'Sign In',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFCBD5E1),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Bottom label
                      Text(
                        'Trusted by thousands of users',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.3),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildParticles(Size size) {
    final positions = [
      [0.15, 0.12],
      [0.85, 0.18],
      [0.08, 0.45],
      [0.92, 0.38],
      [0.25, 0.72],
      [0.75, 0.65],
      [0.5, 0.08],
      [0.4, 0.88],
      [0.6, 0.82],
    ];
    return positions.asMap().entries.map((e) {
      final i = e.key;
      final pos = e.value;
      return Positioned(
        left: size.width * pos[0],
        top: size.height * pos[1],
        child: AnimatedBuilder(
          animation: _floatCtrl,
          builder: (_, child) => Opacity(
            opacity: (0.2 + (i % 3) * 0.15) * (0.5 + _floatCtrl.value * 0.5),
            child: child,
          ),
          child: Container(
            width: i % 2 == 0 ? 3 : 2,
            height: i % 2 == 0 ? 3 : 2,
            decoration: BoxDecoration(
              color: i % 3 == 0
                  ? const Color(0xFF60A5FA)
                  : i % 3 == 1
                      ? const Color(0xFF818CF8)
                      : Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    }).toList();
  }
}

// ── AmpUp Logo ──────────────────────────────────────
class _AmpUpLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow ring
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF2B5CE6).withOpacity(0.3),
                  const Color(0xFF2B5CE6).withOpacity(0.0),
                ],
              ),
            ),
          ),
          // Middle ring
          Container(
            width: 114,
            height: 114,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF3B82F6).withOpacity(0.25),
                width: 1,
              ),
            ),
          ),
          // Main logo circle
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
                  color: const Color(0xFF2B5CE6).withOpacity(0.6),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: const Color(0xFF60A5FA).withOpacity(0.2),
                  blurRadius: 60,
                  spreadRadius: 10,
                ),
              ],
            ),
          ),
          // Lightning bolt icon
          CustomPaint(
            size: const Size(36, 48),
            painter: _LightningPainter(),
          ),
        ],
      ),
    );
  }
}

// ── Lightning bolt painter ──────────────────────────
class _LightningPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Glow layer
    final glowPaint = Paint()
      ..color = const Color(0xFF93C5FD).withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    // Main bolt
    final boltPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFFBAE6FD),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    // Top right point
    path.moveTo(size.width * 0.72, 0);
    // Down to middle left
    path.lineTo(size.width * 0.28, size.height * 0.45);
    // Middle notch right
    path.lineTo(size.width * 0.55, size.height * 0.45);
    // Down to bottom left
    path.lineTo(size.width * 0.28, size.height);
    // Up to middle right
    path.lineTo(size.width * 0.72, size.height * 0.55);
    // Middle notch left
    path.lineTo(size.width * 0.45, size.height * 0.55);
    path.close();

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, boltPaint);
  }

  @override
  bool shouldRepaint(_LightningPainter o) => false;
}

// ── Orb widget ──────────────────────────────────────
class _Orb extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _Orb({required this.size, required this.color, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withOpacity(opacity),
            color.withOpacity(0),
          ],
        ),
      ),
    );
  }
}

// ── Feature pill ────────────────────────────────────
class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF60A5FA)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Glow button ─────────────────────────────────────
class _GlowButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _GlowButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF2563EB),
              Color(0xFF4F46E5),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB).withOpacity(0.5),
              blurRadius: 24,
              offset: const Offset(0, 8),
              spreadRadius: -4,
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'Get Started',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}
