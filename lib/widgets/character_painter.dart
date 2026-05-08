import 'package:flutter/material.dart';
import 'dart:math' as math;

class CharacterPainter extends CustomPainter {
  final String animal;
  final String? outfit, top, bottom, shoes, hat, glasses, extra;
  final bool isDark;

  const CharacterPainter({
    required this.animal,
    required this.isDark,
    this.outfit,
    this.top,
    this.bottom,
    this.shoes,
    this.hat,
    this.glasses,
    this.extra,
  });

  static const _pal = {
    'panda': [
      Color(0xFFF2F2F2),
      Color(0xFF222222),
      Color(0xFFFFE4E1),
      Color(0xFFDDDDDD)
    ],
    'fox': [
      Color(0xFFE8742A),
      Color(0xFF7A2E00),
      Color(0xFFFFF5EE),
      Color(0xFFC85A10)
    ],
    'cat': [
      Color(0xFFD4A96A),
      Color(0xFF7A4A10),
      Color(0xFFFFE8D0),
      Color(0xFFB8853A)
    ],
    'bear': [
      Color(0xFF8B5E3C),
      Color(0xFF3A1A00),
      Color(0xFFD4956A),
      Color(0xFF6B3E1C)
    ],
    'bunny': [
      Color(0xFFF5E8F5),
      Color(0xFFB060A0),
      Color(0xFFFFD6E8),
      Color(0xFFDDB8DD)
    ],
    'koala': [
      Color(0xFF888898),
      Color(0xFF303040),
      Color(0xFFD5D5E0),
      Color(0xFF606070)
    ],
    'tiger': [
      Color(0xFFE87820),
      Color(0xFF1A0800),
      Color(0xFFFFF0D8),
      Color(0xFFC85800)
    ],
    'wolf': [
      Color(0xFF9090A0),
      Color(0xFF202030),
      Color(0xFFE0E0F0),
      Color(0xFF606070)
    ],
  };

  static const _clothC = {
    'tshirt': Color(0xFF3B82F6),
    'hoodie': Color(0xFF6366F1),
    'jacket': Color(0xFF1E293B),
    'suit': Color(0xFF1E293B),
    'dress': Color(0xFFEC4899),
    'sweater': Color(0xFFEF4444),
    'tank': Color(0xFF10B981),
    'polo': Color(0xFFF59E0B),
    'jeans': Color(0xFF1D4ED8),
    'shorts': Color(0xFF0EA5E9),
    'skirt': Color(0xFFDB2777),
    'sweats': Color(0xFF6B7280),
    'trousers': Color(0xFF374151),
    'leggings': Color(0xFF111827),
    'school': Color(0xFF1E3A5F),
    'superhero': Color(0xFFDC2626),
    'tuxedo': Color(0xFF0F172A),
    'spacesuit': Color(0xFFCBD5E1),
    'ninja': Color(0xFF111827),
    'chef': Color(0xFFF8FAFC),
    'doctor': Color(0xFFEFF6FF),
    'royal': Color(0xFF7C3AED),
    'sneakers': Color(0xFFF8FAFC),
    'boots': Color(0xFF78350F),
    'heels': Color(0xFFEC4899),
    'sandals': Color(0xFFF59E0B),
    'loafers': Color(0xFF374151),
    'cleats': Color(0xFF065F46),
  };

  Color get _torsoC {
    if (outfit != null) return _clothC[outfit] ?? const Color(0xFF3B82F6);
    if (top != null) return _clothC[top] ?? const Color(0xFF3B82F6);
    return (_pal[animal] ?? _pal['panda']!)[0];
  }

  Color get _legC {
    if (outfit != null) {
      final c = _torsoC;
      return Color.fromARGB(255, (c.red * 0.75).round(),
          (c.green * 0.75).round(), (c.blue * 0.75).round());
    }
    if (bottom != null) return _clothC[bottom] ?? const Color(0xFF1D4ED8);
    return (_pal[animal] ?? _pal['panda']!)[0];
  }

  Color get _shoeC {
    if (shoes != null) return _clothC[shoes] ?? const Color(0xFF374151);
    return (_pal[animal] ?? _pal['panda']!)[1];
  }

  // ── Gradient paint helpers ────────────────────────
  Paint _gPaint(Color c, Color shadow, Rect r, {double angle = math.pi / 4}) {
    return Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(c, Colors.white, 0.35)!,
          c,
          Color.lerp(c, shadow, 0.4)!,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(r);
  }

  Paint _rimPaint(Color c, {double width = 1.5}) => Paint()
    ..color = Color.lerp(c, Colors.black, 0.3)!
    ..style = PaintingStyle.stroke
    ..strokeWidth = width;

  @override
  void paint(Canvas canvas, Size size) {
    final W = size.width;
    final H = size.height;
    final p = _pal[animal] ?? _pal['panda']!;
    final bodyC = p[0];
    final darkC = p[1];
    final innerC = p[2];
    final shadC = p[3];

    _drawShadow(canvas, W, H);
    _drawShoes(canvas, W, H);
    _drawLegs(canvas, W, H, shadC);
    _drawTorso(canvas, W, H, bodyC, shadC);
    _drawArms(canvas, W, H, bodyC, shadC, darkC);
    _drawNeck(canvas, W, H, bodyC, shadC);
    _drawClothingDetails(canvas, W, H);
    _drawHead(canvas, W, H, bodyC, darkC, innerC, shadC);
    _drawFace(canvas, W, H, bodyC, darkC, innerC);
    _drawAnimalExtras(canvas, W, H, bodyC, darkC, innerC, shadC);
    if (hat != null) _drawHat(canvas, W, H);
    if (glasses != null) _drawGlasses(canvas, W, H);
    if (extra != null) _drawExtra(canvas, W, H);
  }

  void _drawShadow(Canvas canvas, double W, double H) {
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(W / 2, H * 0.97), width: W * 0.55, height: H * 0.035),
      Paint()
        ..color = Colors.black.withOpacity(0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
  }

  void _drawShoes(Canvas canvas, double W, double H) {
    final c = _shoeC;
    final shad = Color.lerp(c, Colors.black, 0.4)!;
    final lite = Color.lerp(c, Colors.white, 0.4)!;

    for (final isRight in [false, true]) {
      final cx = isRight ? W * 0.645 : W * 0.355;
      final r = Rect.fromLTWH(cx - W * 0.135, H * 0.855, W * 0.27, H * 0.10);

      // Shoe body with 3D gradient
      final shoePath = Path()
        ..addRRect(RRect.fromRectAndCorners(r,
            topLeft: Radius.circular(isRight ? 6 : 10),
            topRight: Radius.circular(isRight ? 10 : 6),
            bottomLeft: const Radius.circular(8),
            bottomRight: const Radius.circular(8)));
      canvas.drawPath(
          shoePath,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [lite, c, shad],
            ).createShader(r));
      canvas.drawPath(shoePath, _rimPaint(c));

      // Toe cap highlight
      canvas.drawOval(
          Rect.fromLTWH(cx - W * 0.08, H * 0.858, W * 0.10, H * 0.025),
          Paint()..color = Colors.white.withOpacity(0.35));

      // Sole
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(cx - W * 0.135, H * 0.945, W * 0.27, H * 0.018),
              const Radius.circular(4)),
          Paint()..color = shad);

      // Laces for sneakers/boots
      if (shoes == 'sneakers' || shoes == null) {
        final lp = Paint()
          ..color = Colors.white.withOpacity(0.6)
          ..strokeWidth = 1;
        for (int i = 0; i < 2; i++) {
          final lx = cx - W * 0.06 + i * W * 0.05;
          canvas.drawLine(
              Offset(lx, H * 0.875), Offset(lx + W * 0.03, H * 0.875), lp);
        }
      }
    }
  }

  void _drawLegs(Canvas canvas, double W, double H, Color shadC) {
    final c = _legC;
    final lite = Color.lerp(c, Colors.white, 0.3)!;
    final dark = Color.lerp(c, Colors.black, 0.3)!;

    for (final isRight in [false, true]) {
      final cx = isRight ? W * 0.645 : W * 0.355;
      final r = Rect.fromLTWH(cx - W * 0.12, H * 0.59, W * 0.24, H * 0.295);

      canvas.drawRRect(
          RRect.fromRectAndCorners(r,
              topLeft: const Radius.circular(10),
              topRight: const Radius.circular(10),
              bottomLeft: const Radius.circular(6),
              bottomRight: const Radius.circular(6)),
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [lite, c, dark],
            ).createShader(r));

      // Knee highlight
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(cx, H * 0.695),
              width: W * 0.10,
              height: H * 0.055),
          Paint()..color = Colors.white.withOpacity(0.18));

      // Leg crease
      if (bottom != null || outfit != null) {
        canvas.drawLine(
            Offset(cx, H * 0.62),
            Offset(cx, H * 0.85),
            Paint()
              ..color = Colors.black.withOpacity(0.06)
              ..strokeWidth = 0.8);
      }
    }
  }

  void _drawTorso(Canvas canvas, double W, double H, Color bodyC, Color shadC) {
    final c = _torsoC;
    final lite = Color.lerp(c, Colors.white, 0.35)!;
    final dark = Color.lerp(c, Colors.black, 0.35)!;

    final r = Rect.fromLTWH(W * 0.18, H * 0.305, W * 0.64, H * 0.32);
    canvas.drawRRect(
        RRect.fromRectAndCorners(r,
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: const Radius.circular(8),
            bottomRight: const Radius.circular(8)),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [lite, c, dark],
            stops: const [0.0, 0.45, 1.0],
          ).createShader(r));

    // Chest highlight
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(W * 0.50, H * 0.38),
            width: W * 0.28,
            height: H * 0.10),
        Paint()..color = Colors.white.withOpacity(0.12));

    // Bottom hem shadow
    canvas.drawRRect(
        RRect.fromRectAndCorners(
            Rect.fromLTWH(W * 0.18, H * 0.60, W * 0.64, H * 0.025),
            bottomLeft: const Radius.circular(8),
            bottomRight: const Radius.circular(8)),
        Paint()..color = Colors.black.withOpacity(0.08));
  }

  void _drawArms(Canvas canvas, double W, double H, Color bodyC, Color shadC,
      Color darkC) {
    final armC = _torsoC;
    final lite = Color.lerp(armC, Colors.white, 0.3)!;
    final dark = Color.lerp(armC, Colors.black, 0.3)!;

    for (final isRight in [false, true]) {
      final x = isRight ? W * 0.795 : W * 0.005;
      final r = Rect.fromLTWH(x, H * 0.315, W * 0.20, H * 0.30);

      // Arm
      canvas.drawRRect(
          RRect.fromRectAndRadius(r, const Radius.circular(14)),
          Paint()
            ..shader = LinearGradient(
              begin: isRight ? Alignment.centerLeft : Alignment.centerRight,
              end: isRight ? Alignment.centerRight : Alignment.centerLeft,
              colors: [lite, armC, dark],
            ).createShader(r));

      // Hand (paw)
      final hx = isRight ? W * 0.895 : W * 0.105;
      final handR = Rect.fromCenter(
          center: Offset(hx, H * 0.615), width: W * 0.20, height: W * 0.20);
      canvas.drawOval(
          handR,
          Paint()
            ..shader = RadialGradient(
              colors: [
                Color.lerp(bodyC, Colors.white, 0.4)!,
                bodyC,
                Color.lerp(bodyC, darkC, 0.3)!
              ],
            ).createShader(handR));

      // Paw toes
      for (int t = 0; t < 3; t++) {
        canvas.drawCircle(Offset(hx - W * 0.05 + t * W * 0.05, H * 0.600),
            W * 0.025, Paint()..color = Color.lerp(bodyC, Colors.white, 0.5)!);
      }
    }
  }

  void _drawNeck(Canvas canvas, double W, double H, Color bodyC, Color shadC) {
    final r = Rect.fromLTWH(W * 0.40, H * 0.23, W * 0.20, H * 0.09);
    canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(8)),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(bodyC, Colors.white, 0.3)!,
              bodyC,
              Color.lerp(bodyC, shadC, 0.4)!
            ],
          ).createShader(r));
  }

  void _drawClothingDetails(Canvas canvas, double W, double H) {
    final effective = outfit ?? top;
    if (effective == null) return;

    switch (effective) {
      case 'school':
      case 'suit':
      case 'tuxedo':
        // White shirt collar
        canvas.drawPath(
            Path()
              ..moveTo(W * 0.38, H * 0.305)
              ..lineTo(W * 0.50, H * 0.425)
              ..lineTo(W * 0.62, H * 0.305)
              ..close(),
            Paint()..color = Colors.white);
        // Lapels
        canvas.drawPath(
            Path()
              ..moveTo(W * 0.38, H * 0.305)
              ..lineTo(W * 0.44, H * 0.415)
              ..lineTo(W * 0.50, H * 0.425),
            Paint()
              ..color = Colors.black.withOpacity(0.15)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1);
        canvas.drawPath(
            Path()
              ..moveTo(W * 0.62, H * 0.305)
              ..lineTo(W * 0.56, H * 0.415)
              ..lineTo(W * 0.50, H * 0.425),
            Paint()
              ..color = Colors.black.withOpacity(0.15)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1);
        // Tie
        final tieC =
            effective == 'tuxedo' ? Colors.white : const Color(0xFFDC2626);
        canvas.drawPath(
            Path()
              ..moveTo(W * 0.47, H * 0.37)
              ..lineTo(W * 0.50, H * 0.57)
              ..lineTo(W * 0.53, H * 0.37)
              ..lineTo(W * 0.50, H * 0.33)
              ..close(),
            Paint()..color = tieC);
        canvas.drawPath(
            Path()
              ..moveTo(W * 0.47, H * 0.37)
              ..lineTo(W * 0.50, H * 0.40)
              ..lineTo(W * 0.53, H * 0.37),
            Paint()
              ..color = Colors.black.withOpacity(0.2)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1);
        if (effective == 'tuxedo') {
          // Bow tie
          canvas.drawPath(
              Path()
                ..moveTo(W * 0.43, H * 0.345)
                ..lineTo(W * 0.50, H * 0.375)
                ..lineTo(W * 0.57, H * 0.345)
                ..lineTo(W * 0.50, H * 0.315)
                ..close(),
              Paint()..color = Colors.white);
        }
        // Buttons
        for (int i = 0; i < 3; i++) {
          canvas.drawCircle(Offset(W * 0.50, H * (0.455 + i * 0.048)),
              W * 0.016, Paint()..color = Colors.white.withOpacity(0.7));
        }
        break;

      case 'superhero':
        // Cape
        final capeP = Paint()..color = const Color(0xFF7C0000);
        canvas.drawPath(
            Path()
              ..moveTo(W * 0.20, H * 0.315)
              ..lineTo(W * 0.05, H * 0.62)
              ..quadraticBezierTo(W * 0.12, H * 0.58, W * 0.20, H * 0.54)
              ..close(),
            capeP);
        canvas.drawPath(
            Path()
              ..moveTo(W * 0.80, H * 0.315)
              ..lineTo(W * 0.95, H * 0.62)
              ..quadraticBezierTo(W * 0.88, H * 0.58, W * 0.80, H * 0.54)
              ..close(),
            capeP);
        // Chest shield
        canvas.drawPath(
            Path()
              ..moveTo(W * 0.38, H * 0.355)
              ..lineTo(W * 0.62, H * 0.355)
              ..lineTo(W * 0.58, H * 0.535)
              ..lineTo(W * 0.50, H * 0.565)
              ..lineTo(W * 0.42, H * 0.535)
              ..close(),
            Paint()..color = Colors.yellow.withOpacity(0.9));
        // Symbol on chest
        canvas.drawPath(
            Path()
              ..moveTo(W * 0.46, H * 0.40)
              ..lineTo(W * 0.50, H * 0.355)
              ..lineTo(W * 0.54, H * 0.40)
              ..lineTo(W * 0.50, H * 0.52)
              ..close(),
            Paint()..color = const Color(0xFFDC2626));
        break;

      case 'spacesuit':
        // Helmet ring
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset(W * 0.50, H * 0.27),
                width: W * 0.60,
                height: H * 0.18),
            Paint()..color = const Color(0xFFCBD5E1).withOpacity(0.4));
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset(W * 0.50, H * 0.27),
                width: W * 0.60,
                height: H * 0.18),
            Paint()
              ..color = Colors.white.withOpacity(0.3)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3);
        // Suit details
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(W * 0.38, H * 0.38, W * 0.24, H * 0.15),
                const Radius.circular(6)),
            Paint()..color = Colors.white.withOpacity(0.25));
        // Buttons/dials
        for (int i = 0; i < 3; i++) {
          canvas.drawCircle(
              Offset(W * 0.435 + i * W * 0.065, H * 0.465),
              W * 0.022,
              Paint()
                ..color = [
                  const Color(0xFF22C55E),
                  const Color(0xFFF59E0B),
                  const Color(0xFFEF4444)
                ][i]);
        }
        break;

      case 'ninja':
        // Mask across face area — drawn here as torso sash
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(W * 0.18, H * 0.305, W * 0.64, H * 0.06),
                const Radius.circular(4)),
            Paint()..color = Colors.black.withOpacity(0.7));
        // Belt
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(W * 0.18, H * 0.565, W * 0.64, H * 0.032),
                const Radius.circular(4)),
            Paint()..color = const Color(0xFF7C0000));
        // Belt buckle
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(W * 0.44, H * 0.558, W * 0.12, H * 0.046),
                const Radius.circular(3)),
            Paint()..color = const Color(0xFFF59E0B));
        break;

      case 'chef':
        // Apron
        canvas.drawRRect(
            RRect.fromRectAndCorners(
                Rect.fromLTWH(W * 0.32, H * 0.38, W * 0.36, H * 0.245),
                bottomLeft: const Radius.circular(8),
                bottomRight: const Radius.circular(8)),
            Paint()..color = Colors.white.withOpacity(0.8));
        // Apron strings
        canvas.drawLine(
            Offset(W * 0.32, H * 0.38),
            Offset(W * 0.22, H * 0.32),
            Paint()
              ..color = Colors.white.withOpacity(0.8)
              ..strokeWidth = 2);
        canvas.drawLine(
            Offset(W * 0.68, H * 0.38),
            Offset(W * 0.78, H * 0.32),
            Paint()
              ..color = Colors.white.withOpacity(0.8)
              ..strokeWidth = 2);
        // Pocket
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(W * 0.42, H * 0.50, W * 0.16, H * 0.10),
                const Radius.circular(3)),
            Paint()..color = Colors.blue.withOpacity(0.4));
        break;

      case 'doctor':
        // Stethoscope
        canvas.drawArc(
            Rect.fromCenter(
                center: Offset(W * 0.50, H * 0.44),
                width: W * 0.30,
                height: H * 0.12),
            0.2,
            2.8,
            false,
            Paint()
              ..color = const Color(0xFF374151).withOpacity(0.8)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.5);
        canvas.drawCircle(Offset(W * 0.50, H * 0.50), W * 0.04,
            Paint()..color = const Color(0xFF374151).withOpacity(0.8));
        // Name badge
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(W * 0.58, H * 0.36, W * 0.14, H * 0.08),
                const Radius.circular(3)),
            Paint()..color = Colors.white.withOpacity(0.9));
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(W * 0.605, H * 0.375, W * 0.09, H * 0.012),
                const Radius.circular(2)),
            Paint()..color = const Color(0xFF3B82F6));
        break;

      case 'royal':
        // Robe details
        canvas.drawPath(
            Path()
              ..moveTo(W * 0.22, H * 0.305)
              ..lineTo(W * 0.32, H * 0.625)
              ..lineTo(W * 0.22, H * 0.625)
              ..close(),
            Paint()..color = Colors.white.withOpacity(0.15));
        canvas.drawPath(
            Path()
              ..moveTo(W * 0.78, H * 0.305)
              ..lineTo(W * 0.68, H * 0.625)
              ..lineTo(W * 0.78, H * 0.625)
              ..close(),
            Paint()..color = Colors.white.withOpacity(0.15));
        // Gold trim
        canvas.drawLine(
            Offset(W * 0.32, H * 0.305),
            Offset(W * 0.32, H * 0.625),
            Paint()
              ..color = const Color(0xFFF59E0B).withOpacity(0.7)
              ..strokeWidth = 2);
        canvas.drawLine(
            Offset(W * 0.68, H * 0.305),
            Offset(W * 0.68, H * 0.625),
            Paint()
              ..color = const Color(0xFFF59E0B).withOpacity(0.7)
              ..strokeWidth = 2);
        // Jewel
        canvas.drawCircle(Offset(W * 0.50, H * 0.40), W * 0.055,
            Paint()..color = const Color(0xFFE879F9));
        canvas.drawCircle(Offset(W * 0.50, H * 0.40), W * 0.035,
            Paint()..color = const Color(0xFF7C3AED));
        break;

      case 'hoodie':
        // Front pocket
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(W * 0.30, H * 0.50, W * 0.40, H * 0.11),
                const Radius.circular(6)),
            Paint()..color = Colors.black.withOpacity(0.12));
        canvas.drawLine(
            Offset(W * 0.50, H * 0.50),
            Offset(W * 0.50, H * 0.61),
            Paint()
              ..color = Colors.black.withOpacity(0.12)
              ..strokeWidth = 1);
        // Hood strings
        canvas.drawLine(
            Offset(W * 0.44, H * 0.305),
            Offset(W * 0.44, H * 0.40),
            Paint()
              ..color = Colors.white.withOpacity(0.4)
              ..strokeWidth = 1.5);
        canvas.drawLine(
            Offset(W * 0.56, H * 0.305),
            Offset(W * 0.56, H * 0.40),
            Paint()
              ..color = Colors.white.withOpacity(0.4)
              ..strokeWidth = 1.5);
        break;

      case 'dress':
        // Skirt flare
        final skirtPath = Path()
          ..moveTo(W * 0.18, H * 0.50)
          ..lineTo(W * 0.08, H * 0.625)
          ..lineTo(W * 0.92, H * 0.625)
          ..lineTo(W * 0.82, H * 0.50)
          ..close();
        canvas.drawPath(
            skirtPath,
            Paint()
              ..color = (_clothC[effective] ?? Colors.pink).withOpacity(0.85));
        // Waist ribbon
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(W * 0.18, H * 0.495, W * 0.64, H * 0.030),
                const Radius.circular(4)),
            Paint()..color = Colors.white.withOpacity(0.5));
        // Bow
        canvas.drawPath(
            Path()
              ..moveTo(W * 0.44, H * 0.495)
              ..lineTo(W * 0.50, H * 0.525)
              ..lineTo(W * 0.56, H * 0.495)
              ..lineTo(W * 0.50, H * 0.465)
              ..close(),
            Paint()..color = Colors.white.withOpacity(0.8));
        break;

      case 'sweater':
        // Turtleneck
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(W * 0.36, H * 0.215, W * 0.28, H * 0.11),
                const Radius.circular(6)),
            Paint()..color = (_clothC[effective] ?? Colors.red));
        // Ribbing lines
        for (int i = 0; i < 4; i++) {
          canvas.drawLine(
              Offset(W * 0.36, H * 0.225 + i * H * 0.022),
              Offset(W * 0.64, H * 0.225 + i * H * 0.022),
              Paint()
                ..color = Colors.black.withOpacity(0.08)
                ..strokeWidth = 0.8);
        }
        break;

      default:
        // Generic: just a subtle seam line
        canvas.drawLine(
            Offset(W * 0.50, H * 0.315),
            Offset(W * 0.50, H * 0.615),
            Paint()
              ..color = Colors.black.withOpacity(0.04)
              ..strokeWidth = 0.8);
    }
  }

  void _drawHead(Canvas canvas, double W, double H, Color bodyC, Color darkC,
      Color innerC, Color shadC) {
    // Head oval with 3D shading
    final hr = Rect.fromLTWH(W * 0.14, H * 0.02, W * 0.72, H * 0.26);
    canvas.drawOval(
        hr,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.3, -0.4),
            radius: 0.75,
            colors: [
              Color.lerp(bodyC, Colors.white, 0.55)!,
              bodyC,
              Color.lerp(bodyC, shadC, 0.5)!,
            ],
            stops: const [0.0, 0.55, 1.0],
          ).createShader(hr));

    // Head rim
    canvas.drawOval(
        hr,
        Paint()
          ..color = Color.lerp(bodyC, Colors.black, 0.15)!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);

    // Specular highlight on forehead
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(W * 0.38, H * 0.075),
            width: W * 0.15,
            height: H * 0.055),
        Paint()
          ..color = Colors.white.withOpacity(0.28)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
  }

  void _drawFace(Canvas canvas, double W, double H, Color bodyC, Color darkC,
      Color innerC) {
    final eyeY = H * 0.115;

    // Eye whites with slight 3D shadow
    for (final isRight in [false, true]) {
      final ex = isRight ? W * 0.635 : W * 0.365;
      // Eye socket shadow
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(ex, eyeY + H * 0.005),
              width: W * 0.175,
              height: H * 0.095),
          Paint()..color = Colors.black.withOpacity(0.06));
      // White
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(ex, eyeY), width: W * 0.165, height: H * 0.085),
          Paint()..color = Colors.white);
      // Iris gradient
      final ir = Rect.fromCenter(
          center: Offset(ex + W * 0.008, eyeY + H * 0.005),
          width: W * 0.095,
          height: H * 0.055);
      canvas.drawOval(
          ir,
          Paint()
            ..shader = RadialGradient(
              colors: [
                const Color(0xFF4B8BFF),
                const Color(0xFF1A3A8F),
                Colors.black
              ],
              stops: const [0.0, 0.65, 1.0],
            ).createShader(ir));
      // Pupil
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(ex + W * 0.010, eyeY + H * 0.008),
              width: W * 0.048,
              height: H * 0.030),
          Paint()..color = Colors.black);
      // Main shine
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(ex + W * 0.022, eyeY - H * 0.014),
              width: W * 0.040,
              height: H * 0.022),
          Paint()..color = Colors.white.withOpacity(0.92));
      // Small secondary shine
      canvas.drawCircle(Offset(ex - W * 0.018, eyeY + H * 0.010), W * 0.015,
          Paint()..color = Colors.white.withOpacity(0.45));
      // Eyelid line
      canvas.drawArc(
          Rect.fromCenter(
              center: Offset(ex, eyeY - H * 0.005),
              width: W * 0.165,
              height: H * 0.085),
          -math.pi * 0.85,
          -math.pi * 0.30,
          false,
          Paint()
            ..color = darkC.withOpacity(0.25)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2);
    }

    // Cute blush
    for (final isRight in [false, true]) {
      final bx = isRight ? W * 0.72 : W * 0.28;
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(bx, eyeY + H * 0.065),
              width: W * 0.14,
              height: H * 0.045),
          Paint()
            ..color = const Color(0xFFFF9090).withOpacity(0.30)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    }
  }

  void _drawAnimalExtras(Canvas canvas, double W, double H, Color bodyC,
      Color darkC, Color innerC, Color shadC) {
    switch (animal) {
      case 'panda':
        // Eye patches
        for (final isRight in [false, true]) {
          final ex = isRight ? W * 0.635 : W * 0.365;
          canvas.drawOval(
              Rect.fromCenter(
                  center: Offset(ex, H * 0.115),
                  width: W * 0.225,
                  height: H * 0.115),
              Paint()..color = darkC.withOpacity(0.88));
        }
        // Ears
        for (final isRight in [false, true]) {
          final earX = isRight ? W * 0.785 : W * 0.215;
          canvas.drawCircle(
              Offset(earX, H * 0.040), W * 0.115, Paint()..color = darkC);
          canvas.drawCircle(Offset(earX, H * 0.040), W * 0.06,
              Paint()..color = Color.lerp(darkC, Colors.grey, 0.3)!);
        }
        // Nose
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset(W * 0.50, H * 0.187),
                width: W * 0.135,
                height: H * 0.048),
            Paint()..color = darkC);
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset(W * 0.488, H * 0.183),
                width: W * 0.045,
                height: H * 0.016),
            Paint()..color = Colors.white.withOpacity(0.4));
        // Mouth
        _drawMouth(canvas, W, H);
        // Re-draw eyes on top of patches
        _drawFace(canvas, W, H, bodyC, darkC, innerC);
        break;

      case 'fox':
        // Pointed ears
        for (final isRight in [false, true]) {
          final ex = isRight ? W * 0.745 : W * 0.255;
          canvas.drawPath(
              Path()
                ..moveTo(ex - W * 0.10, H * 0.06)
                ..lineTo(ex, H * -0.04)
                ..lineTo(ex + W * 0.10, H * 0.06)
                ..close(),
              Paint()..color = bodyC);
          canvas.drawPath(
              Path()
                ..moveTo(ex - W * 0.06, H * 0.055)
                ..lineTo(ex, H * -0.01)
                ..lineTo(ex + W * 0.06, H * 0.055)
                ..close(),
              Paint()..color = const Color(0xFFFFB3B3));
        }
        // White muzzle
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset(W * 0.50, H * 0.185),
                width: W * 0.34,
                height: H * 0.115),
            Paint()..color = Colors.white.withOpacity(0.88));
        // Nose
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset(W * 0.50, H * 0.158),
                width: W * 0.095,
                height: H * 0.042),
            Paint()..color = const Color(0xFF2D1A00));
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset(W * 0.485, H * 0.154),
                width: W * 0.03,
                height: H * 0.012),
            Paint()..color = Colors.white.withOpacity(0.5));
        _drawMouth(canvas, W, H);
        break;

      case 'cat':
        // Pointed ears with inner ear
        for (final isRight in [false, true]) {
          final ex = isRight ? W * 0.74 : W * 0.26;
          canvas.drawPath(
              Path()
                ..moveTo(ex - W * 0.09, H * 0.07)
                ..lineTo(ex, H * -0.03)
                ..lineTo(ex + W * 0.09, H * 0.07)
                ..close(),
              Paint()..color = bodyC);
          canvas.drawPath(
              Path()
                ..moveTo(ex - W * 0.055, H * 0.065)
                ..lineTo(ex, H * 0.01)
                ..lineTo(ex + W * 0.055, H * 0.065)
                ..close(),
              Paint()..color = const Color(0xFFFF9EB5));
        }
        // Small triangle nose
        canvas.drawPath(
            Path()
              ..moveTo(W * 0.50, H * 0.170)
              ..lineTo(W * 0.464, H * 0.200)
              ..lineTo(W * 0.536, H * 0.200)
              ..close(),
            Paint()..color = const Color(0xFFFF6B8A));
        // Whiskers
        final wp = Paint()
          ..color = darkC.withOpacity(0.35)
          ..strokeWidth = 0.9;
        canvas.drawLine(
            Offset(W * 0.17, H * 0.18), Offset(W * 0.44, H * 0.195), wp);
        canvas.drawLine(
            Offset(W * 0.17, H * 0.205), Offset(W * 0.44, H * 0.210), wp);
        canvas.drawLine(
            Offset(W * 0.83, H * 0.18), Offset(W * 0.56, H * 0.195), wp);
        canvas.drawLine(
            Offset(W * 0.83, H * 0.205), Offset(W * 0.56, H * 0.210), wp);
        _drawMouth(canvas, W, H);
        break;

      case 'bear':
        // Round ears
        for (final isRight in [false, true]) {
          final ex = isRight ? W * 0.785 : W * 0.215;
          final er = Rect.fromCenter(
              center: Offset(ex, H * 0.038), width: W * 0.20, height: W * 0.20);
          canvas.drawOval(
              er,
              Paint()
                ..shader = RadialGradient(
                  colors: [
                    Color.lerp(bodyC, Colors.white, 0.3)!,
                    bodyC,
                    Color.lerp(bodyC, shadC, 0.4)!
                  ],
                ).createShader(er));
          canvas.drawOval(
              Rect.fromCenter(
                  center: Offset(ex, H * 0.040),
                  width: W * 0.11,
                  height: W * 0.11),
              Paint()..color = innerC);
        }
        // Muzzle
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset(W * 0.50, H * 0.192),
                width: W * 0.32,
                height: H * 0.11),
            Paint()..color = innerC);
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset(W * 0.50, H * 0.165),
                width: W * 0.115,
                height: H * 0.048),
            Paint()..color = const Color(0xFF2D1000));
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset(W * 0.486, H * 0.161),
                width: W * 0.038,
                height: H * 0.014),
            Paint()..color = Colors.white.withOpacity(0.5));
        _drawMouth(canvas, W, H);
        break;

      case 'bunny':
        // Long upright ears
        for (final isRight in [false, true]) {
          final ex = isRight ? W * 0.685 : W * 0.315;
          final er =
              Rect.fromLTWH(ex - W * 0.085, H * -0.165, W * 0.17, H * 0.225);
          canvas.drawRRect(
              RRect.fromRectAndRadius(er, const Radius.circular(20)),
              Paint()
                ..shader = LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color.lerp(bodyC, Colors.white, 0.4)!, bodyC],
                ).createShader(er));
          canvas.drawRRect(
              RRect.fromRectAndRadius(
                  Rect.fromLTWH(
                      ex - W * 0.047, H * -0.148, W * 0.094, H * 0.180),
                  const Radius.circular(14)),
              Paint()..color = const Color(0xFFFFB3C8));
        }
        // Nose
        canvas.drawCircle(Offset(W * 0.50, H * 0.175), W * 0.038,
            Paint()..color = const Color(0xFFFF8FA3));
        _drawMouth(canvas, W, H);
        break;

      case 'koala':
        // Big round fluffy ears
        for (final isRight in [false, true]) {
          final ex = isRight ? W * 0.80 : W * 0.20;
          canvas.drawCircle(Offset(ex, H * 0.042), W * 0.155,
              Paint()..color = Color.lerp(bodyC, Colors.white, 0.2)!);
          canvas.drawCircle(
              Offset(ex, H * 0.042), W * 0.11, Paint()..color = bodyC);
          canvas.drawCircle(
              Offset(ex, H * 0.042), W * 0.065, Paint()..color = innerC);
        }
        // Big round grey nose
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset(W * 0.50, H * 0.170),
                width: W * 0.22,
                height: H * 0.082),
            Paint()..color = const Color(0xFF555560));
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset(W * 0.484, H * 0.164),
                width: W * 0.062,
                height: H * 0.022),
            Paint()..color = Colors.white.withOpacity(0.45));
        _drawMouth(canvas, W, H);
        break;

      case 'tiger':
        // Ears
        for (final isRight in [false, true]) {
          final ex = isRight ? W * 0.775 : W * 0.225;
          canvas.drawPath(
              Path()
                ..moveTo(ex - W * 0.10, H * 0.06)
                ..lineTo(ex, H * -0.04)
                ..lineTo(ex + W * 0.10, H * 0.06)
                ..close(),
              Paint()..color = bodyC);
          canvas.drawPath(
              Path()
                ..moveTo(ex - W * 0.06, H * 0.055)
                ..lineTo(ex, H * 0.005)
                ..lineTo(ex + W * 0.06, H * 0.055)
                ..close(),
              Paint()..color = const Color(0xFFFFD0A0));
        }
        // Stripes on forehead
        final sp = Paint()
          ..color = darkC.withOpacity(0.55)
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
            Offset(W * 0.50, H * 0.032), Offset(W * 0.50, H * 0.085), sp);
        canvas.drawLine(
            Offset(W * 0.42, H * 0.038), Offset(W * 0.40, H * 0.092), sp);
        canvas.drawLine(
            Offset(W * 0.58, H * 0.038), Offset(W * 0.60, H * 0.092), sp);
        // White muzzle
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset(W * 0.50, H * 0.192),
                width: W * 0.34,
                height: H * 0.11),
            Paint()..color = Colors.white.withOpacity(0.85));
        // Nose
        canvas.drawPath(
            Path()
              ..moveTo(W * 0.50, H * 0.165)
              ..lineTo(W * 0.466, H * 0.195)
              ..lineTo(W * 0.534, H * 0.195)
              ..close(),
            Paint()..color = const Color(0xFF2D0000));
        _drawMouth(canvas, W, H);
        break;

      case 'wolf':
        // Pointed ears
        for (final isRight in [false, true]) {
          final ex = isRight ? W * 0.765 : W * 0.235;
          canvas.drawPath(
              Path()
                ..moveTo(ex - W * 0.10, H * 0.07)
                ..lineTo(ex, H * -0.05)
                ..lineTo(ex + W * 0.10, H * 0.07)
                ..close(),
              Paint()..color = bodyC);
          canvas.drawPath(
              Path()
                ..moveTo(ex - W * 0.06, H * 0.062)
                ..lineTo(ex, H * -0.008)
                ..lineTo(ex + W * 0.06, H * 0.062)
                ..close(),
              Paint()..color = innerC);
        }
        // Muzzle
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset(W * 0.50, H * 0.188),
                width: W * 0.30,
                height: H * 0.10),
            Paint()..color = innerC);
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset(W * 0.50, H * 0.162),
                width: W * 0.105,
                height: H * 0.045),
            Paint()..color = Colors.black.withOpacity(0.75));
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset(W * 0.487, H * 0.158),
                width: W * 0.034,
                height: H * 0.013),
            Paint()..color = Colors.white.withOpacity(0.5));
        _drawMouth(canvas, W, H);
        break;
    }
  }

  void _drawMouth(Canvas canvas, double W, double H) {
    final mp = Paint()
      ..color = Colors.black.withOpacity(0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final path = Path();
    path.moveTo(W * 0.435, H * 0.218);
    path.quadraticBezierTo(W * 0.50, H * 0.248, W * 0.565, H * 0.218);
    canvas.drawPath(path, mp);
  }

  void _drawHat(Canvas canvas, double W, double H) {
    switch (hat) {
      case 'cap':
        // Bill
        canvas.drawPath(
            Path()
              ..moveTo(W * 0.16, H * 0.025)
              ..lineTo(W * 0.84, H * 0.025)
              ..lineTo(W * 0.92, H * 0.048)
              ..lineTo(W * 0.84, H * 0.058)
              ..lineTo(W * 0.16, H * 0.058)
              ..close(),
            Paint()..color = const Color(0xFF1E40AF));
        // Cap dome
        final cr = Rect.fromLTWH(W * 0.18, H * -0.105, W * 0.64, H * 0.14);
        canvas.drawRRect(
            RRect.fromRectAndCorners(cr,
                topLeft: const Radius.circular(22),
                topRight: const Radius.circular(22)),
            Paint()
              ..shader = LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF3B82F6),
                  const Color(0xFF1D4ED8),
                  const Color(0xFF1E3A8A)
                ],
              ).createShader(cr));
        // Logo
        canvas.drawCircle(Offset(W * 0.50, H * -0.032), W * 0.055,
            Paint()..color = Colors.white.withOpacity(0.8));
        // Button top
        canvas.drawCircle(Offset(W * 0.50, H * -0.105), W * 0.025,
            Paint()..color = const Color(0xFF1D4ED8));
        break;

      case 'tophat':
        // Brim
        final br = Rect.fromLTWH(W * 0.12, H * -0.005, W * 0.76, H * 0.042);
        canvas.drawRRect(
            RRect.fromRectAndRadius(br, const Radius.circular(4)),
            Paint()
              ..shader = LinearGradient(
                colors: [const Color(0xFF2D2D2D), const Color(0xFF0A0A0A)],
              ).createShader(br));
        // Crown
        final tr = Rect.fromLTWH(W * 0.26, H * -0.175, W * 0.48, H * 0.178);
        canvas.drawRRect(
            RRect.fromRectAndCorners(tr,
                topLeft: const Radius.circular(6),
                topRight: const Radius.circular(6)),
            Paint()
              ..shader = LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [const Color(0xFF3D3D3D), const Color(0xFF0A0A0A)],
              ).createShader(tr));
        // Hat band
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(W * 0.26, H * -0.008, W * 0.48, H * 0.028),
                const Radius.circular(3)),
            Paint()..color = const Color(0xFF7C0000));
        // Shine
        canvas.drawRRect(
            RRect.fromRectAndCorners(
                Rect.fromLTWH(W * 0.28, H * -0.168, W * 0.12, H * 0.15),
                topLeft: const Radius.circular(6)),
            Paint()..color = Colors.white.withOpacity(0.07));
        break;

      case 'crown':
        final cp = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFFDE68A),
              const Color(0xFFF59E0B),
              const Color(0xFFD97706)
            ],
          ).createShader(
              Rect.fromLTWH(W * 0.14, H * -0.145, W * 0.72, H * 0.16));
        final crownPath = Path()
          ..moveTo(W * 0.14, H * 0.012)
          ..lineTo(W * 0.14, H * -0.08)
          ..lineTo(W * 0.26, H * -0.005)
          ..lineTo(W * 0.38, H * -0.145)
          ..lineTo(W * 0.50, H * -0.02)
          ..lineTo(W * 0.62, H * -0.145)
          ..lineTo(W * 0.74, H * -0.005)
          ..lineTo(W * 0.86, H * -0.08)
          ..lineTo(W * 0.86, H * 0.012)
          ..close();
        canvas.drawPath(crownPath, cp);
        canvas.drawPath(
            crownPath,
            Paint()
              ..color = const Color(0xFFD97706)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5);
        // Gems
        final gemColors = [
          const Color(0xFFDC2626),
          const Color(0xFF7C3AED),
          const Color(0xFF0EA5E9)
        ];
        final gemPos = [W * 0.50, W * 0.32, W * 0.68];
        final gemY = [H * -0.108, H * -0.052, H * -0.052];
        for (int i = 0; i < 3; i++) {
          canvas.drawCircle(Offset(gemPos[i], gemY[i]), W * 0.045,
              Paint()..color = gemColors[i]);
          canvas.drawCircle(Offset(gemPos[i] - W * 0.012, gemY[i] - H * 0.010),
              W * 0.015, Paint()..color = Colors.white.withOpacity(0.6));
        }
        break;

      case 'graduation':
        // Cap board
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(W * 0.14, H * -0.038, W * 0.72, H * 0.048),
                const Radius.circular(3)),
            Paint()..color = const Color(0xFF0F172A));
        // Cap body
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(W * 0.28, H * -0.115, W * 0.44, H * 0.082),
                const Radius.circular(4)),
            Paint()..color = const Color(0xFF1E293B));
        // Tassel
        canvas.drawLine(
            Offset(W * 0.80, H * -0.014),
            Offset(W * 0.88, H * 0.055),
            Paint()
              ..color = const Color(0xFFF59E0B)
              ..strokeWidth = 2.5);
        canvas.drawCircle(Offset(W * 0.88, H * 0.058), W * 0.028,
            Paint()..color = const Color(0xFFF59E0B));
        break;

      case 'cowboy':
        // Wide brim
        final brimPaint = Paint()
          ..shader = LinearGradient(
            colors: [const Color(0xFFB45309), const Color(0xFF78350F)],
          ).createShader(
              Rect.fromLTWH(W * 0.06, H * -0.008, W * 0.88, H * 0.055));
        canvas.drawOval(
            Rect.fromLTWH(W * 0.06, H * -0.008, W * 0.88, H * 0.055),
            brimPaint);
        // Crown
        final cowR = Rect.fromLTWH(W * 0.24, H * -0.155, W * 0.52, H * 0.162);
        canvas.drawRRect(
            RRect.fromRectAndCorners(cowR,
                topLeft: const Radius.circular(12),
                topRight: const Radius.circular(12)),
            Paint()
              ..shader = LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [const Color(0xFFD97706), const Color(0xFF92400E)],
              ).createShader(cowR));
        // Band
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(W * 0.24, H * -0.005, W * 0.52, H * 0.025),
                const Radius.circular(3)),
            Paint()..color = const Color(0xFF0F172A));
        break;

      case 'santa':
        // Red hat body
        final santaR = Rect.fromLTWH(W * 0.20, H * -0.135, W * 0.60, H * 0.155);
        canvas.drawRRect(
            RRect.fromRectAndCorners(santaR,
                topLeft: const Radius.circular(4),
                topRight: const Radius.circular(50)),
            Paint()
              ..shader = LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [const Color(0xFFEF4444), const Color(0xFF991B1B)],
              ).createShader(santaR));
        // White trim band
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(W * 0.16, H * 0.005, W * 0.68, H * 0.038),
                const Radius.circular(8)),
            Paint()..color = Colors.white);
        // Pompom
        canvas.drawCircle(Offset(W * 0.75, H * -0.125), W * 0.055,
            Paint()..color = Colors.white);
        canvas.drawCircle(Offset(W * 0.744, H * -0.132), W * 0.022,
            Paint()..color = Colors.white.withOpacity(0.7));
        break;

      case 'beret':
        final beret = Rect.fromLTWH(W * 0.16, H * -0.095, W * 0.68, H * 0.11);
        canvas.drawOval(
            beret,
            Paint()
              ..shader = LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [const Color(0xFF6D28D9), const Color(0xFF4C1D95)],
              ).createShader(beret));
        // Brim
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(W * 0.25, H * -0.005, W * 0.50, H * 0.028),
                const Radius.circular(4)),
            Paint()..color = const Color(0xFF5B21B6));
        canvas.drawCircle(Offset(W * 0.50, H * -0.085), W * 0.028,
            Paint()..color = const Color(0xFF8B5CF6));
        break;

      case 'party':
        // Party hat cone
        final partyPath = Path()
          ..moveTo(W * 0.20, H * 0.025)
          ..lineTo(W * 0.50, H * -0.165)
          ..lineTo(W * 0.80, H * 0.025)
          ..close();
        canvas.drawPath(
            partyPath,
            Paint()
              ..shader = LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [const Color(0xFFF472B6), const Color(0xFF7C3AED)],
              ).createShader(
                  Rect.fromLTWH(W * 0.20, H * -0.165, W * 0.60, H * 0.19)));
        // Dots
        for (int i = 0; i < 5; i++) {
          final px = W * (0.30 + i * 0.09);
          final py = H * (-0.10 + i * 0.024);
          canvas.drawCircle(Offset(px, py), W * 0.022,
              Paint()..color = Colors.white.withOpacity(0.8));
        }
        // Pom top
        canvas.drawCircle(Offset(W * 0.50, H * -0.165), W * 0.04,
            Paint()..color = Colors.yellow);
        // Hat band
        canvas.drawLine(
            Offset(W * 0.20, H * 0.025),
            Offset(W * 0.80, H * 0.025),
            Paint()
              ..color = Colors.white.withOpacity(0.5)
              ..strokeWidth = 2);
        break;
    }
  }

  void _drawGlasses(Canvas canvas, double W, double H) {
    final eyeY = H * 0.115;
    Color frameC;
    Color lensC;

    switch (glasses) {
      case 'sunglasses':
        frameC = const Color(0xFF0F172A);
        lensC = const Color(0xFF0F172A).withOpacity(0.88);
        break;
      case 'goggles':
        frameC = const Color(0xFF065F46);
        lensC = const Color(0xFF34D399).withOpacity(0.55);
        break;
      case 'monocle':
        frameC = const Color(0xFFF59E0B);
        lensC = Colors.transparent;
        // Single monocle on right eye only
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset(W * 0.635, eyeY),
                width: W * 0.195,
                height: H * 0.105),
            Paint()..color = lensC);
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset(W * 0.635, eyeY),
                width: W * 0.195,
                height: H * 0.105),
            Paint()
              ..color = frameC
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3);
        canvas.drawLine(
            Offset(W * 0.732, eyeY + H * 0.052),
            Offset(W * 0.78, H * 0.22),
            Paint()
              ..color = frameC
              ..strokeWidth = 1.5);
        return;
      default:
        frameC = const Color(0xFF374151);
        lensC = Colors.lightBlue.withOpacity(0.15);
    }

    if (glasses == 'goggles') {
      // Single wide goggle
      final gr = Rect.fromLTWH(W * 0.15, eyeY - H * 0.048, W * 0.70, H * 0.095);
      canvas.drawRRect(RRect.fromRectAndRadius(gr, const Radius.circular(10)),
          Paint()..color = lensC);
      canvas.drawRRect(
          RRect.fromRectAndRadius(gr, const Radius.circular(10)),
          Paint()
            ..color = frameC
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(W * 0.165, eyeY - H * 0.040, W * 0.22, H * 0.030),
              const Radius.circular(4)),
          Paint()..color = Colors.white.withOpacity(0.28));
      return;
    }

    // Two-lens glasses/sunglasses
    for (final isRight in [false, true]) {
      final ex = isRight ? W * 0.635 : W * 0.365;
      final lr = Rect.fromCenter(
          center: Offset(ex, eyeY), width: W * 0.215, height: H * 0.100);
      // Lens
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              lr, Radius.circular(glasses == 'sunglasses' ? 14 : 8)),
          Paint()..color = lensC);
      // Frame
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              lr, Radius.circular(glasses == 'sunglasses' ? 14 : 8)),
          Paint()
            ..color = frameC
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5);
      // Lens shine
      if (glasses == 'sunglasses') {
        canvas.drawOval(
            Rect.fromLTWH(
                ex - W * 0.07, eyeY - H * 0.030, W * 0.055, H * 0.028),
            Paint()..color = Colors.white.withOpacity(0.18));
      }
    }
    // Bridge
    canvas.drawLine(
        Offset(W * 0.365 + W * 0.107, eyeY),
        Offset(W * 0.635 - W * 0.107, eyeY),
        Paint()
          ..color = frameC
          ..strokeWidth = 2);
    // Temples
    canvas.drawLine(
        Offset(W * 0.365 - W * 0.107, eyeY),
        Offset(W * 0.14, eyeY + H * 0.02),
        Paint()
          ..color = frameC
          ..strokeWidth = 2);
    canvas.drawLine(
        Offset(W * 0.635 + W * 0.107, eyeY),
        Offset(W * 0.86, eyeY + H * 0.02),
        Paint()
          ..color = frameC
          ..strokeWidth = 2);
  }

  void _drawExtra(Canvas canvas, double W, double H) {
    switch (extra) {
      case 'bow':
        final bp = Paint()
          ..shader = LinearGradient(
            colors: [const Color(0xFFF9A8D4), const Color(0xFFEC4899)],
          ).createShader(
              Rect.fromLTWH(W * 0.38, H * 0.265, W * 0.24, H * 0.06));
        // Left loop
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset(W * 0.435, H * 0.290),
                width: W * 0.10,
                height: H * 0.055),
            bp);
        // Right loop
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset(W * 0.565, H * 0.290),
                width: W * 0.10,
                height: H * 0.055),
            bp);
        // Center knot
        canvas.drawCircle(Offset(W * 0.50, H * 0.290), W * 0.030, bp);
        // Tails
        canvas.drawLine(
            Offset(W * 0.485, H * 0.305),
            Offset(W * 0.460, H * 0.336),
            Paint()
              ..color = const Color(0xFFEC4899)
              ..strokeWidth = 3
              ..strokeCap = StrokeCap.round);
        canvas.drawLine(
            Offset(W * 0.515, H * 0.305),
            Offset(W * 0.540, H * 0.336),
            Paint()
              ..color = const Color(0xFFEC4899)
              ..strokeWidth = 3
              ..strokeCap = StrokeCap.round);
        break;

      case 'necklace':
        // Chain
        final nPath = Path();
        nPath.moveTo(W * 0.30, H * 0.295);
        nPath.quadraticBezierTo(W * 0.50, H * 0.345, W * 0.70, H * 0.295);
        canvas.drawPath(
            nPath,
            Paint()
              ..color = const Color(0xFFF59E0B)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.5
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.5));
        // Pendant
        canvas.drawCircle(Offset(W * 0.50, H * 0.348), W * 0.038,
            Paint()..color = const Color(0xFFF59E0B));
        canvas.drawCircle(Offset(W * 0.50, H * 0.348), W * 0.022,
            Paint()..color = const Color(0xFF7C3AED));
        canvas.drawCircle(Offset(W * 0.493, H * 0.343), W * 0.009,
            Paint()..color = Colors.white.withOpacity(0.7));
        break;

      case 'watch':
        // Watch on left wrist
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromCenter(
                    center: Offset(W * 0.10, H * 0.565),
                    width: W * 0.145,
                    height: H * 0.065),
                const Radius.circular(6)),
            Paint()..color = const Color(0xFF0F172A));
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromCenter(
                    center: Offset(W * 0.10, H * 0.565),
                    width: W * 0.110,
                    height: H * 0.050),
                const Radius.circular(5)),
            Paint()..color = const Color(0xFF1E293B));
        // Watch face
        canvas.drawCircle(Offset(W * 0.10, H * 0.565), W * 0.032,
            Paint()..color = Colors.white.withOpacity(0.9));
        // Hands
        canvas.drawLine(
            Offset(W * 0.10, H * 0.565),
            Offset(W * 0.10, H * 0.550),
            Paint()
              ..color = Colors.black
              ..strokeWidth = 1.2
              ..strokeCap = StrokeCap.round);
        canvas.drawLine(
            Offset(W * 0.10, H * 0.565),
            Offset(W * 0.116, H * 0.568),
            Paint()
              ..color = Colors.black
              ..strokeWidth = 1.0
              ..strokeCap = StrokeCap.round);
        break;

      case 'bag':
        // Handbag on right arm
        final bagR = Rect.fromLTWH(W * 0.78, H * 0.485, W * 0.175, H * 0.13);
        canvas.drawRRect(
            RRect.fromRectAndRadius(bagR, const Radius.circular(10)),
            Paint()
              ..shader = LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [const Color(0xFFF9A8D4), const Color(0xFFEC4899)],
              ).createShader(bagR));
        canvas.drawRRect(
            RRect.fromRectAndRadius(bagR, const Radius.circular(10)),
            Paint()
              ..color = const Color(0xFFBE185D)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5);
        // Strap
        canvas.drawArc(
            Rect.fromCenter(
                center: Offset(W * 0.868, H * 0.478),
                width: W * 0.10,
                height: H * 0.055),
            math.pi,
            math.pi,
            false,
            Paint()
              ..color = const Color(0xFFBE185D)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.5);
        // Clasp
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromCenter(
                    center: Offset(W * 0.868, H * 0.488),
                    width: W * 0.055,
                    height: H * 0.022),
                const Radius.circular(4)),
            Paint()..color = const Color(0xFFF59E0B));
        break;

      case 'backpack':
        // Backpack on back (visible on sides)
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(W * 0.24, H * 0.31, W * 0.52, H * 0.30),
                const Radius.circular(10)),
            Paint()..color = const Color(0xFF1D4ED8).withOpacity(0.85));
        // Pockets
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(W * 0.32, H * 0.455, W * 0.36, H * 0.13),
                const Radius.circular(7)),
            Paint()..color = const Color(0xFF1E40AF));
        // Zipper
        canvas.drawLine(
            Offset(W * 0.50, H * 0.458),
            Offset(W * 0.50, H * 0.583),
            Paint()
              ..color = Colors.white.withOpacity(0.4)
              ..strokeWidth = 1);
        // Straps
        for (final isRight in [false, true]) {
          final sx = isRight ? W * 0.58 : W * 0.42;
          canvas.drawRRect(
              RRect.fromRectAndRadius(
                  Rect.fromLTWH(sx - W * 0.028, H * 0.30, W * 0.056, H * 0.26),
                  const Radius.circular(5)),
              Paint()..color = const Color(0xFF1E40AF).withOpacity(0.8));
        }
        break;

      case 'wings':
        // Angel/fairy wings
        final wingGrad = [
          Colors.white.withOpacity(0.90),
          const Color(0xFFE0E7FF).withOpacity(0.60)
        ];
        // Left wing
        final lWing = Path()
          ..moveTo(W * 0.20, H * 0.38)
          ..cubicTo(
              W * -0.12, H * 0.22, W * -0.15, H * 0.52, W * 0.18, H * 0.55)
          ..close();
        final lWing2 = Path()
          ..moveTo(W * 0.20, H * 0.46)
          ..cubicTo(
              W * -0.05, H * 0.44, W * -0.06, H * 0.62, W * 0.18, H * 0.60)
          ..close();
        // Right wing
        final rWing = Path()
          ..moveTo(W * 0.80, H * 0.38)
          ..cubicTo(W * 1.12, H * 0.22, W * 1.15, H * 0.52, W * 0.82, H * 0.55)
          ..close();
        final rWing2 = Path()
          ..moveTo(W * 0.80, H * 0.46)
          ..cubicTo(W * 1.05, H * 0.44, W * 1.06, H * 0.62, W * 0.82, H * 0.60)
          ..close();
        final wingR = Rect.fromLTWH(W * -0.15, H * 0.22, W * 0.40, H * 0.42);
        for (final path in [lWing, lWing2, rWing, rWing2]) {
          canvas.drawPath(
              path,
              Paint()
                ..shader = LinearGradient(
                  colors: wingGrad,
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ).createShader(wingR));
          canvas.drawPath(
              path,
              Paint()
                ..color = const Color(0xFF818CF8).withOpacity(0.35)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1.2);
        }
        // Wing veins
        final vp = Paint()
          ..color = const Color(0xFF6366F1).withOpacity(0.20)
          ..strokeWidth = 0.8;
        canvas.drawLine(
            Offset(W * 0.20, H * 0.38), Offset(W * -0.04, H * 0.36), vp);
        canvas.drawLine(
            Offset(W * 0.20, H * 0.38), Offset(W * 0.02, H * 0.48), vp);
        canvas.drawLine(
            Offset(W * 0.80, H * 0.38), Offset(W * 1.04, H * 0.36), vp);
        canvas.drawLine(
            Offset(W * 0.80, H * 0.38), Offset(W * 0.98, H * 0.48), vp);
        break;

      case 'cape':
        // Hero cape
        canvas.drawPath(
            Path()
              ..moveTo(W * 0.20, H * 0.315)
              ..cubicTo(
                  W * 0.10, H * 0.50, W * 0.04, H * 0.70, W * 0.16, H * 0.82)
              ..lineTo(W * 0.35, H * 0.70)
              ..lineTo(W * 0.20, H * 0.52)
              ..close(),
            Paint()
              ..shader = LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [const Color(0xFF7C0000), const Color(0xFF450A0A)],
              ).createShader(
                  Rect.fromLTWH(W * 0.04, H * 0.315, W * 0.31, H * 0.505)));
        canvas.drawPath(
            Path()
              ..moveTo(W * 0.80, H * 0.315)
              ..cubicTo(
                  W * 0.90, H * 0.50, W * 0.96, H * 0.70, W * 0.84, H * 0.82)
              ..lineTo(W * 0.65, H * 0.70)
              ..lineTo(W * 0.80, H * 0.52)
              ..close(),
            Paint()
              ..shader = LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [const Color(0xFF7C0000), const Color(0xFF450A0A)],
              ).createShader(
                  Rect.fromLTWH(W * 0.65, H * 0.315, W * 0.31, H * 0.505)));
        // Cape clasp
        canvas.drawCircle(Offset(W * 0.50, H * 0.315), W * 0.038,
            Paint()..color = const Color(0xFFF59E0B));
        canvas.drawCircle(Offset(W * 0.50, H * 0.315), W * 0.022,
            Paint()..color = const Color(0xFFD97706));
        break;

      case 'umbrella':
        // Umbrella handle at wrist
        canvas.drawLine(
            Offset(W * 0.88, H * 0.48),
            Offset(W * 0.88, H * 0.28),
            Paint()
              ..color = const Color(0xFF374151)
              ..strokeWidth = 3
              ..strokeCap = StrokeCap.round);
        // Canopy
        canvas.drawPath(
            Path()
              ..moveTo(W * 0.62, H * 0.28)
              ..quadraticBezierTo(W * 0.88, H * 0.14, W * 1.02, H * 0.28)
              ..close(),
            Paint()
              ..shader = LinearGradient(
                colors: [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)],
              ).createShader(
                  Rect.fromLTWH(W * 0.62, H * 0.14, W * 0.40, H * 0.14)));
        // Ribs
        for (int i = 0; i < 3; i++) {
          canvas.drawLine(
              Offset(W * 0.88, H * 0.28),
              Offset(W * (0.68 + i * 0.16), H * 0.28),
              Paint()
                ..color = Colors.white.withOpacity(0.3)
                ..strokeWidth = 0.8);
        }
        // Hook
        canvas.drawArc(
            Rect.fromCenter(
                center: Offset(W * 0.88, H * 0.505),
                width: W * 0.07,
                height: H * 0.05),
            0,
            math.pi,
            false,
            Paint()
              ..color = const Color(0xFF374151)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3);
        break;
    }
  }

  @override
  bool shouldRepaint(CharacterPainter o) =>
      o.animal != animal ||
      o.outfit != outfit ||
      o.top != top ||
      o.bottom != bottom ||
      o.shoes != shoes ||
      o.hat != hat ||
      o.glasses != glasses ||
      o.extra != extra;
}
