import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

class DinoGame extends StatefulWidget {
  final void Function(int creditsEarned) onGameOver;
  const DinoGame({super.key, required this.onGameOver});
  @override
  State<DinoGame> createState() => _DinoGameState();
}

class _DinoGameState extends State<DinoGame>
    with SingleTickerProviderStateMixin {
  static const double _groundY = 0.80;
  static const double _gravity = 0.0018;
  static const double _jumpForce = -0.046;
  static const double _dinoX = 0.08;
  static const double _dinoW = 0.06;
  static const double _dinoH = 0.18;
  static const double _obsW = 0.032;

  late Ticker _ticker;
  Duration _last = Duration.zero;

  double _dinoY = _groundY;
  double _velY = 0;
  bool _onGround = true;
  bool _running = false;
  bool _gameOver = false;
  int _frames = 0;
  int _displayScore = 0;
  double _speed = 0.0024;
  int _highScore = 0;

  final List<_Obstacle> _obstacles = [];
  double _spawnTimer = 0;
  double _bgOffset = 0;

  @override
  void initState() {
    super.initState();
    // Force landscape
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _ticker = createTicker(_tick)..start();
  }

  void _tick(Duration elapsed) {
    if (!_running || _gameOver) {
      _last = elapsed;
      return;
    }
    final dt = (elapsed - _last).inMilliseconds / 1000.0;
    _last = elapsed;

    setState(() {
      _velY += _gravity;
      _dinoY += _velY;
      if (_dinoY >= _groundY) {
        _dinoY = _groundY;
        _velY = 0;
        _onGround = true;
      }

      _bgOffset += _speed * 0.3;
      _frames++;

      // Score increments once every 30 frames (~2/sec at 60fps) — 5x slower
      if (_frames % 30 == 0) _displayScore++;

      for (int i = 0; i < _obstacles.length; i++) {
        _obstacles[i].x -= _speed;
      }
      _obstacles.removeWhere((o) => o.x < -0.12);

      _spawnTimer += dt;
      final gap = 1.4 + Random().nextDouble() * 1.0;
      if (_spawnTimer > gap) {
        _obstacles.add(_Obstacle(x: 1.08, type: Random().nextInt(3)));
        _spawnTimer = 0;
      }

      // Speed increases very gradually
      _speed = 0.0024 + _frames * 0.0000015;

      for (final obs in _obstacles) {
        if (_collides(obs)) {
          _endGame();
          return;
        }
      }
    });
  }

  bool _collides(_Obstacle obs) {
    const m = 0.012;
    final dLeft = _dinoX + m;
    final dRight = _dinoX + _dinoW - m;
    final dBottom = _dinoY;
    final dTop = _dinoY - _dinoH + m * 2;
    final oLeft = obs.x + m;
    final oRight = obs.x + _obsW - m;
    final oTop = _groundY - obs.height;
    return dRight > oLeft && dLeft < oRight && dBottom > oTop;
  }

  void _endGame() {
    _gameOver = true;
    _running = false;
    if (_displayScore > _highScore) _highScore = _displayScore;
    widget.onGameOver(_displayScore ~/ 10);
  }

  void _handleTap() {
    if (_gameOver) {
      _restart();
      return;
    }
    if (!_running) {
      setState(() {
        _running = true;
      });
      return;
    }
    if (_onGround) {
      setState(() {
        _velY = _jumpForce;
        _onGround = false;
      });
    }
  }

  void _restart() {
    setState(() {
      _dinoY = _groundY;
      _velY = 0;
      _onGround = true;
      _running = true;
      _gameOver = false;
      _frames = 0;
      _displayScore = 0;
      _speed = 0.0024;
      _obstacles.clear();
      _spawnTimer = 0;
    });
  }

  @override
  void dispose() {
    // Restore portrait when leaving
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(colors: [
                  Color(0xFF060B18),
                  Color(0xFF0D1B3E),
                  Color(0xFF0A1628)
                ], begin: Alignment.topCenter, end: Alignment.bottomCenter)
              : const LinearGradient(colors: [
                  Color(0xFFDBEAFE),
                  Color(0xFFEFF6FF),
                  Color(0xFFDCFCE7)
                ], begin: Alignment.topCenter, end: Alignment.bottomCenter),
          borderRadius: BorderRadius.circular(24),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: CustomPaint(
            painter: _DinoPainter(
              dinoY: _dinoY,
              velY: _velY,
              onGround: _onGround,
              obstacles: List<_Obstacle>.from(_obstacles),
              displayScore: _displayScore,
              frames: _frames,
              running: _running,
              gameOver: _gameOver,
              isDark: isDark,
              bgOffset: _bgOffset,
              highScore: _highScore,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

class _Obstacle {
  double x;
  final int type;
  _Obstacle({required this.x, required this.type});
  double get height {
    switch (type) {
      case 0:
        return 0.18;
      case 1:
        return 0.26;
      case 2:
        return 0.20;
      default:
        return 0.18;
    }
  }
}

class _DinoPainter extends CustomPainter {
  final double dinoY, velY, bgOffset;
  final bool onGround, running, gameOver, isDark;
  final List<_Obstacle> obstacles;
  final int displayScore, frames, highScore;

  const _DinoPainter({
    required this.dinoY,
    required this.velY,
    required this.onGround,
    required this.obstacles,
    required this.displayScore,
    required this.frames,
    required this.running,
    required this.gameOver,
    required this.isDark,
    required this.bgOffset,
    required this.highScore,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final W = size.width;
    final H = size.height;

    if (isDark) {
      _drawStars(canvas, W, H);
      _drawMoon(canvas, W, H);
    } else {
      _drawClouds(canvas, W, H);
      _drawSun(canvas, W, H);
    }

    _drawMountains(canvas, W, H);
    _drawGround(canvas, W, H);

    for (final obs in obstacles) _drawCactus(canvas, W, H, obs);
    _drawDino(canvas, W, H);
    _drawHUD(canvas, W, H);

    if (!running && !gameOver) _drawStartScreen(canvas, size);
    if (gameOver) _drawGameOver(canvas, size);
  }

  // ── Stars ──────────────────────────────────────────
  void _drawStars(Canvas canvas, double W, double H) {
    final p = Paint();
    final pos = [
      [0.04, 0.06],
      [0.12, 0.04],
      [0.22, 0.10],
      [0.34, 0.03],
      [0.46, 0.08],
      [0.56, 0.05],
      [0.66, 0.12],
      [0.76, 0.04],
      [0.86, 0.09],
      [0.94, 0.06],
      [0.08, 0.18],
      [0.28, 0.15],
      [0.50, 0.20],
      [0.72, 0.14],
      [0.90, 0.19],
      [0.16, 0.28],
      [0.40, 0.25],
      [0.62, 0.30],
      [0.84, 0.24],
      [0.98, 0.28],
    ];
    for (int i = 0; i < pos.length; i++) {
      final sx = (pos[i][0] * W + bgOffset * W * 0.04) % W;
      final sy = pos[i][1] * H;
      final sz = i % 3 == 0
          ? 2.0
          : i % 3 == 1
              ? 1.3
              : 0.9;
      final op = 0.35 + (i % 4) * 0.15;
      p.color = Colors.white.withOpacity(op);
      canvas.drawCircle(Offset(sx, sy), sz, p);
      if (i % 4 == 0) {
        final lp = Paint()
          ..color = Colors.white.withOpacity(op * 0.45)
          ..strokeWidth = 0.7;
        canvas.drawLine(Offset(sx - 3.5, sy), Offset(sx + 3.5, sy), lp);
        canvas.drawLine(Offset(sx, sy - 3.5), Offset(sx, sy + 3.5), lp);
      }
    }
  }

  // ── Moon ──────────────────────────────────────────
  void _drawMoon(Canvas canvas, double W, double H) {
    final mX = W * 0.88;
    final mY = H * 0.14;
    canvas.drawCircle(Offset(mX, mY), 18,
        Paint()..color = const Color(0xFFE8F4FD).withOpacity(0.9));
    canvas.drawCircle(
        Offset(mX + 7, mY - 3), 15, Paint()..color = const Color(0xFF0D1B3E));
    canvas.drawCircle(
        Offset(mX, mY),
        26,
        Paint()
          ..color = const Color(0xFFBAE6FD).withOpacity(0.10)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14));
  }

  // ── Sun ───────────────────────────────────────────
  void _drawSun(Canvas canvas, double W, double H) {
    final sX = W * 0.90;
    final sY = H * 0.16;
    canvas.drawCircle(
        Offset(sX, sY),
        28,
        Paint()
          ..color = const Color(0xFFFBBF24).withOpacity(0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18));
    canvas.drawCircle(
        Offset(sX, sY),
        16,
        Paint()
          ..shader = const RadialGradient(colors: [
            Color(0xFFFDE68A),
            Color(0xFFF59E0B)
          ]).createShader(Rect.fromCircle(center: Offset(sX, sY), radius: 16)));
  }

  // ── Clouds ────────────────────────────────────────
  void _drawClouds(Canvas canvas, double W, double H) {
    final p = Paint()..color = Colors.white.withOpacity(0.88);
    for (final c in [
      [0.10, 0.08, 0.9],
      [0.38, 0.05, 0.65],
      [0.62, 0.11, 0.80],
      [0.84, 0.07, 0.70]
    ]) {
      final cx = ((c[0] * W - bgOffset * W * 0.06) % (W + 60)) - 30;
      _cloud(canvas, cx, c[1] * H, c[2] * 44, p);
    }
  }

  void _cloud(Canvas canvas, double cx, double cy, double r, Paint p) {
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: r * 2, height: r * 0.6),
        p);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx - r * 0.35, cy + r * 0.08),
            width: r * 0.9,
            height: r * 0.55),
        p);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx + r * 0.35, cy + r * 0.08),
            width: r * 0.9,
            height: r * 0.55),
        p);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx, cy + r * 0.12), width: r * 1.4, height: r * 0.5),
        p);
  }

  // ── Mountains background ──────────────────────────
  void _drawMountains(Canvas canvas, double W, double H) {
    final gY = H * 0.80;
    final mp = Paint()
      ..color = (isDark ? const Color(0xFF1E3A5F) : const Color(0xFFBFDBFE))
          .withOpacity(0.5);
    final mp2 = Paint()
      ..color = (isDark ? const Color(0xFF162D50) : const Color(0xFFDDE8FF))
          .withOpacity(0.6);

    // Far mountains
    final m1 = Path();
    final off1 = (bgOffset * W * 0.04) % W;
    for (int i = -1; i < 4; i++) {
      final mx = i * W * 0.35 - off1;
      m1.moveTo(mx, gY);
      m1.lineTo(mx + W * 0.12, gY - H * 0.28);
      m1.lineTo(mx + W * 0.24, gY);
    }
    canvas.drawPath(m1, mp2);

    // Near mountains
    final m2 = Path();
    final off2 = (bgOffset * W * 0.07) % W;
    for (int i = -1; i < 5; i++) {
      final mx = i * W * 0.28 - off2;
      m2.moveTo(mx, gY);
      m2.lineTo(mx + W * 0.09, gY - H * 0.18);
      m2.lineTo(mx + W * 0.18, gY);
    }
    canvas.drawPath(m2, mp);
  }

  // ── Ground ────────────────────────────────────────
  void _drawGround(Canvas canvas, double W, double H) {
    final gY = H * 0.80;
    canvas.drawRect(
        Rect.fromLTWH(0, gY, W, H - gY),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF1A3354), const Color(0xFF0D1B3E)]
                : [const Color(0xFF4ADE80), const Color(0xFF16A34A)],
          ).createShader(Rect.fromLTWH(0, gY, W, H - gY)));

    // Ground line
    canvas.drawLine(
        Offset(0, gY),
        Offset(W, gY),
        Paint()
          ..color = (isDark ? const Color(0xFF3B82F6) : const Color(0xFF22C55E))
              .withOpacity(0.5)
          ..strokeWidth = 2);

    // Scrolling ground marks
    final dp = Paint()..color = Colors.white.withOpacity(0.2);
    for (int i = 0; i < 30; i++) {
      final dx = ((i * 38.0 + bgOffset * W * 0.35) % W);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(dx, gY + 4, 12, 3), const Radius.circular(2)),
          dp);
    }
  }

  // ── Dino ──────────────────────────────────────────
  void _drawDino(Canvas canvas, double W, double H) {
    final dX = W * 0.08;
    final dW = W * 0.06;
    final dH = H * 0.18;
    final dTop = H * dinoY - dH;
    final cx = dX + dW / 2;
    final lp = running && !gameOver && onGround ? (frames ~/ 6) % 2 : 0;

    final c1 = isDark ? const Color(0xFF60A5FA) : const Color(0xFF22C55E);
    final c2 = isDark ? const Color(0xFF1D4ED8) : const Color(0xFF15803D);
    final c3 = isDark ? const Color(0xFF93C5FD) : const Color(0xFF86EFAC);

    final bg = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [c1, c2],
      ).createShader(Rect.fromLTWH(dX, dTop, dW, dH));

    // Shadow
    if (onGround) {
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(cx, H * 0.80 + 4), width: dW * 1.0, height: 6),
          Paint()
            ..color = Colors.black.withOpacity(0.16)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    }

    // Tail
    final tailP = Paint()..color = c2;
    final tail = Path()
      ..moveTo(dX + dW * 0.08, dTop + dH * 0.38)
      ..quadraticBezierTo(
          dX - dW * 0.22, dTop + dH * 0.52, dX - dW * 0.32, dTop + dH * 0.42)
      ..quadraticBezierTo(
          dX - dW * 0.18, dTop + dH * 0.64, dX + dW * 0.06, dTop + dH * 0.60)
      ..close();
    canvas.drawPath(tail, tailP);

    // Legs
    if (onGround) {
      final legP = Paint()..color = c2;
      if (lp == 0) {
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(
                    dX + dW * 0.54, dTop + dH * 0.80, dW * 0.24, dH * 0.24),
                const Radius.circular(4)),
            legP);
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(
                    dX + dW * 0.20, dTop + dH * 0.88, dW * 0.24, dH * 0.16),
                const Radius.circular(4)),
            legP);
      } else {
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(
                    dX + dW * 0.54, dTop + dH * 0.88, dW * 0.24, dH * 0.16),
                const Radius.circular(4)),
            legP);
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(
                    dX + dW * 0.20, dTop + dH * 0.80, dW * 0.24, dH * 0.24),
                const Radius.circular(4)),
            legP);
      }
    } else {
      final legP = Paint()..color = c2;
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(
                  dX + dW * 0.14, dTop + dH * 0.82, dW * 0.24, dH * 0.13),
              const Radius.circular(4)),
          legP);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(
                  dX + dW * 0.52, dTop + dH * 0.78, dW * 0.24, dH * 0.13),
              const Radius.circular(4)),
          legP);
    }

    // Body
    canvas.drawRRect(
        RRect.fromRectAndCorners(
            Rect.fromLTWH(dX, dTop + dH * 0.22, dW, dH * 0.70),
            topLeft: const Radius.circular(10),
            topRight: const Radius.circular(8),
            bottomLeft: const Radius.circular(8),
            bottomRight: const Radius.circular(8)),
        bg);

    // Belly
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(dX + dW * 0.40, dTop + dH * 0.58),
            width: dW * 0.50,
            height: dH * 0.36),
        Paint()..color = c3.withOpacity(0.32));

    // Spikes
    for (int i = 0; i < 3; i++) {
      final sx = dX + dW * 0.22 + i * dW * 0.19;
      final sy = dTop + dH * 0.22;
      canvas.drawPath(
          Path()
            ..moveTo(sx - 3, sy)
            ..lineTo(sx, sy - 7 - i * 2.0)
            ..lineTo(sx + 3, sy)
            ..close(),
          Paint()..color = c2);
    }

    // Head
    final headP = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [c3, c1],
      ).createShader(Rect.fromLTWH(dX + dW * 0.18, dTop, dW * 0.95, dH * 0.52));
    canvas.drawRRect(
        RRect.fromRectAndCorners(
            Rect.fromLTWH(dX + dW * 0.18, dTop, dW * 0.88, dH * 0.50),
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(16),
            bottomLeft: const Radius.circular(5),
            bottomRight: const Radius.circular(10)),
        headP);

    // Snout
    canvas.drawRRect(
        RRect.fromRectAndCorners(
            Rect.fromLTWH(
                dX + dW * 0.70, dTop + dH * 0.22, dW * 0.38, dH * 0.24),
            topLeft: const Radius.circular(3),
            topRight: const Radius.circular(8),
            bottomLeft: const Radius.circular(3),
            bottomRight: const Radius.circular(8)),
        Paint()..color = c3.withOpacity(0.68));

    // Nostril
    canvas.drawCircle(Offset(dX + dW * 0.95, dTop + dH * 0.28), 1.4,
        Paint()..color = c2.withOpacity(0.5));

    // Eye
    canvas.drawCircle(Offset(dX + dW * 0.78, dTop + dH * 0.14), 5.5,
        Paint()..color = Colors.white);
    canvas.drawCircle(Offset(dX + dW * 0.80, dTop + dH * 0.15), 3.5,
        Paint()..color = const Color(0xFF1E293B));
    canvas.drawCircle(Offset(dX + dW * 0.82, dTop + dH * 0.12), 1.4,
        Paint()..color = Colors.white);

    // Arm
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(
                dX + dW * 0.64, dTop + dH * 0.43, dW * 0.28, dH * 0.16),
            const Radius.circular(5)),
        Paint()..color = c1);

    // Speed lines when jumping
    if (!onGround) {
      final slp = Paint()
        ..color = c1.withOpacity(0.32)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;
      for (int i = 0; i < 3; i++) {
        final lx = dX - 6 - i * 9.0;
        final ly = dTop + dH * (0.30 + i * 0.13);
        canvas.drawLine(Offset(lx, ly), Offset(lx - 15, ly), slp);
      }
    }
  }

  // ── Cactus ────────────────────────────────────────
  void _drawCactus(Canvas canvas, double W, double H, _Obstacle obs) {
    final oX = W * obs.x;
    final oH = H * obs.height;
    final oW = W * 0.032;
    final oTop = H * 0.80 - oH;

    final cp = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [const Color(0xFF4A5F8C), const Color(0xFF1E3A5F)]
            : [const Color(0xFF16A34A), const Color(0xFF15803D)],
      ).createShader(Rect.fromLTWH(oX, oTop, oW, oH));

    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(oX, oTop, oW, oH), const Radius.circular(4)),
        cp);

    if (obs.type != 2) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(
                  oX - oW * 0.65, oTop + oH * 0.24, oW * 0.65, oH * 0.25),
              const Radius.circular(3)),
          cp);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(
                  oX - oW * 0.65, oTop + oH * 0.13, oW * 0.65, oH * 0.14),
              const Radius.circular(3)),
          cp);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(oX + oW, oTop + oH * 0.34, oW * 0.65, oH * 0.20),
              const Radius.circular(3)),
          cp);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(oX + oW, oTop + oH * 0.21, oW * 0.65, oH * 0.15),
              const Radius.circular(3)),
          cp);
    } else {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(
                  oX + oW * 1.4, oTop + oH * 0.22, oW * 0.85, oH * 0.78),
              const Radius.circular(4)),
          cp);
    }

    // Spines
    final sp = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 0.9
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 4; i++) {
      final sy = oTop + oH * (0.20 + i * 0.17);
      canvas.drawLine(Offset(oX - 2, sy), Offset(oX, sy + 2), sp);
      canvas.drawLine(Offset(oX + oW + 2, sy + 3), Offset(oX + oW, sy + 5), sp);
    }
  }

  // ── HUD ───────────────────────────────────────────
  void _drawHUD(Canvas canvas, double W, double H) {
    // Score pill
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(58, 10, 118, 28), const Radius.circular(8)),
        Paint()
          ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.07));
    _txt(canvas, 'Score  $displayScore', const Offset(66, 24), 12,
        isDark ? Colors.white.withOpacity(0.9) : const Color(0xFF1E293B),
        bold: true);

    // Best score
    if (highScore > 0) {
      _txt(
          canvas,
          'Best  $highScore',
          Offset(W - 80, 24),
          11,
          (isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB))
              .withOpacity(0.75));
    }

    // Level badge
    final lvl = (displayScore ~/ 30).clamp(0, 9);
    if (lvl > 0) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(W / 2, 24), width: 52, height: 22),
              const Radius.circular(11)),
          Paint()
            ..shader = const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFEF4444)])
                .createShader(Rect.fromCenter(
                    center: Offset(W / 2, 24), width: 52, height: 22)));
      _txtC(canvas, Size(W, 0), 'LV $lvl', 24, 11, Colors.white, bold: true);
    }
  }

  // ── Start ─────────────────────────────────────────
  void _drawStartScreen(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = Colors.black.withOpacity(0.28));
    final cx = size.width / 2;
    final cy = size.height / 2;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, cy), width: 260, height: 110),
            const Radius.circular(18)),
        Paint()
          ..color = (isDark ? const Color(0xFF1E3A5F) : Colors.white)
              .withOpacity(0.96));
    _txtC(canvas, size, 'TAP TO START', cy - 18, 16,
        isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
        bold: true);
    _txtC(canvas, size, 'Dodge the cacti  •  Tap to jump', cy + 4, 12,
        isDark ? Colors.white54 : Colors.black38);
    _txtC(
        canvas,
        size,
        '10 points = 1 credit  •  max 50 credits/day',
        cy + 22,
        11,
        isDark
            ? const Color(0xFF34D399).withOpacity(0.8)
            : const Color(0xFF059669));
  }

  // ── Game Over ─────────────────────────────────────
  void _drawGameOver(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = Colors.black.withOpacity(0.45));
    final cx = size.width / 2;
    final cy = size.height / 2;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, cy), width: 270, height: 130),
            const Radius.circular(20)),
        Paint()
          ..color = (isDark ? const Color(0xFF0F172A) : Colors.white)
              .withOpacity(0.97));
    _txtC(canvas, size, 'GAME OVER', cy - 30, 18, const Color(0xFFEF4444),
        bold: true);
    _txtC(
        canvas,
        size,
        'Score: $displayScore    Credits earned: ${displayScore ~/ 10}',
        cy - 6,
        12,
        isDark ? Colors.white70 : Colors.black54);
    _txtC(canvas, size, 'Best: $highScore', cy + 12, 11,
        isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB));
    // Button
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(cx, cy + 36), width: 160, height: 30),
            const Radius.circular(15)),
        Paint()
          ..shader = const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF4F46E5)])
              .createShader(Rect.fromCenter(
                  center: Offset(cx, cy + 36), width: 160, height: 30)));
    _txtC(canvas, size, 'TAP TO PLAY AGAIN', cy + 38, 11, Colors.white,
        bold: true);
  }

  void _txt(Canvas canvas, String text, Offset offset, double fs, Color color,
      {bool bold = false}) {
    final tp = TextPainter(
        text: TextSpan(
            text: text,
            style: TextStyle(
                color: color,
                fontSize: fs,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
        textDirection: TextDirection.ltr)
      ..layout();
    tp.paint(canvas, offset - Offset(0, tp.height / 2));
  }

  void _txtC(
      Canvas canvas, Size size, String text, double y, double fs, Color color,
      {bool bold = false}) {
    final tp = TextPainter(
        text: TextSpan(
            text: text,
            style: TextStyle(
                color: color,
                fontSize: fs,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                letterSpacing: bold ? 0.8 : 0.2)),
        textDirection: TextDirection.ltr)
      ..layout(maxWidth: size.width * 0.85);
    tp.paint(canvas, Offset((size.width - tp.width) / 2, y - tp.height / 2));
  }

  @override
  bool shouldRepaint(_DinoPainter o) => true;
}
