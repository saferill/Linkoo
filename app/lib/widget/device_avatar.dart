import 'package:flutter/material.dart';

/// A crisp, deterministic, illustrated avatar generator for Linko devices.
/// Produces 16 handcrafted, distinct, adorable cartoon species (Panda, Cat, Fox, Penguin,
/// Bear, Frog, Chick, Bunny, Robot, Astronaut, Dino, Boba, Donut, Croissant, Strawberry, Tiramisu)
/// with vibrant gradients and clean facial features.
class DeviceAvatar extends StatelessWidget {
  final String fingerprint;
  final double size;
  final double borderRadius;

  const DeviceAvatar({
    super.key,
    required this.fingerprint,
    this.size = 48,
    this.borderRadius = 14,
  });

  @override
  Widget build(BuildContext context) {
    final seed = _hashString(fingerprint);
    final spec = _AvatarSpec.fromSeed(seed);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CustomPaint(
        size: Size(size, size),
        painter: _AvatarPainter(spec: spec),
      ),
    );
  }

  static int _hashString(String input) {
    if (input.isEmpty) return 42;
    int hash = 5381;
    for (int i = 0; i < input.length; i++) {
      hash = ((hash << 5) + hash) + input.codeUnitAt(i);
      hash = hash & 0x7FFFFFFF;
    }
    return hash;
  }
}

class _AvatarSpec {
  final List<Color> bgColors;
  final int species; // 0..15 (16 unique species)
  final int expression; // 0..3 (variations in eyes/mouth)
  final int badgePattern; // 0..7

  const _AvatarSpec({
    required this.bgColors,
    required this.species,
    required this.expression,
    required this.badgePattern,
  });

  factory _AvatarSpec.fromSeed(int seed) {
    final prng = _PRNG(seed);
    return _AvatarSpec(
      bgColors: _bgGradients[prng.nextInt(_bgGradients.length)],
      species: prng.nextInt(16),
      expression: prng.nextInt(4),
      badgePattern: prng.nextInt(8),
    );
  }

  static const List<List<Color>> _bgGradients = [
    [Color(0xFF2E27A8), Color(0xFF5B4DFF)], // Indigo
    [Color(0xFF0077B6), Color(0xFF00B4D8)], // Ocean Sky
    [Color(0xFF2D6A4F), Color(0xFF52B788)], // Emerald Mint
    [Color(0xFF7209B7), Color(0xFFB5179E)], // Cyber Violet
    [Color(0xFFD00000), Color(0xFFFF5400)], // Warm Crimson
    [Color(0xFFFB8500), Color(0xFFFFB703)], // Golden Amber
    [Color(0xFF03045E), Color(0xFF023E8A)], // Deep Navy
    [Color(0xFF386641), Color(0xFF6A994E)], // Matcha Green
    [Color(0xFF9D0208), Color(0xFFD00000)], // Ruby Red
    [Color(0xFF480CA8), Color(0xFF3F37C9)], // Royal Indigo
    [Color(0xFF005F73), Color(0xFF0A9396)], // Deep Teal
    [Color(0xFF6D597A), Color(0xFFB56576)], // Dusty Rose
    [Color(0xFF582F0E), Color(0xFF7F4F24)], // Warm Caramel
    [Color(0xFF1F2421), Color(0xFF495867)], // Slate Charcoal
    [Color(0xFFE07A5F), Color(0xFFF4F1DE)], // Terracotta Cream
    [Color(0xFF1B4965), Color(0xFF62B6CB)], // Glacier Blue
  ];
}

class _PRNG {
  int _state;
  _PRNG(int seed) : _state = (seed == 0) ? 123456789 : seed;

  int nextInt(int max) {
    _state ^= (_state << 13) & 0x7FFFFFFF;
    _state ^= (_state >> 17);
    _state ^= (_state << 5) & 0x7FFFFFFF;
    return (_state % max).abs();
  }
}

class _AvatarPainter extends CustomPainter {
  final _AvatarSpec spec;

  _AvatarPainter({required this.spec});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final c = Offset(w / 2, h / 2);

    // 1. Draw Background Gradient
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: spec.bgColors,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // 2. Draw Subtle Pattern in background
    _drawPattern(canvas, size);

    // 3. Draw Character Species
    switch (spec.species) {
      case 0:
        _drawPanda(canvas, c, w);
        break;
      case 1:
        _drawCat(canvas, c, w);
        break;
      case 2:
        _drawFox(canvas, c, w);
        break;
      case 3:
        _drawPenguin(canvas, c, w);
        break;
      case 4:
        _drawBear(canvas, c, w);
        break;
      case 5:
        _drawFrog(canvas, c, w);
        break;
      case 6:
        _drawChick(canvas, c, w);
        break;
      case 7:
        _drawBunny(canvas, c, w);
        break;
      case 8:
        _drawRobot(canvas, c, w);
        break;
      case 9:
        _drawAstronaut(canvas, c, w);
        break;
      case 10:
        _drawDino(canvas, c, w);
        break;
      case 11:
        _drawBoba(canvas, c, w);
        break;
      case 12:
        _drawDonut(canvas, c, w);
        break;
      case 13:
        _drawCroissant(canvas, c, w);
        break;
      case 14:
        _drawStrawberry(canvas, c, w);
        break;
      case 15:
      default:
        _drawTiramisu(canvas, c, w);
        break;
    }
  }

  void _drawPattern(Canvas canvas, Size size) {
    final pPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;

    if (spec.badgePattern % 2 == 0) {
      // Sparks
      canvas.drawCircle(Offset(w * 0.18, h * 0.2), w * 0.04, pPaint);
      canvas.drawCircle(Offset(w * 0.82, h * 0.22), w * 0.05, pPaint);
    } else {
      // Ring
      final ringPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.04;
      canvas.drawCircle(Offset(w / 2, h / 2), w * 0.44, ringPaint);
    }
  }

  // 0. PANDA: White face, black round ears, black eye patches, cute nose
  void _drawPanda(Canvas canvas, Offset c, double w) {
    final blackPaint = Paint()..color = const Color(0xFF1E1E24);
    final whitePaint = Paint()..color = Colors.white;
    final pinkPaint = Paint()..color = const Color(0xFFFF85A1).withValues(alpha: 0.5);

    // Ears
    canvas.drawCircle(Offset(c.dx - w * 0.24, c.dy - w * 0.22), w * 0.12, blackPaint);
    canvas.drawCircle(Offset(c.dx + w * 0.24, c.dy - w * 0.22), w * 0.12, blackPaint);

    // Head
    canvas.drawCircle(Offset(c.dx, c.dy + w * 0.04), w * 0.32, whitePaint);

    // Eye Patches (Angled ovals)
    canvas.drawOval(Rect.fromCenter(center: Offset(c.dx - w * 0.13, c.dy - w * 0.02), width: w * 0.16, height: w * 0.2), blackPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(c.dx + w * 0.13, c.dy - w * 0.02), width: w * 0.16, height: w * 0.2), blackPaint);

    // Shiny Eyes
    canvas.drawCircle(Offset(c.dx - w * 0.12, c.dy - w * 0.04), w * 0.035, whitePaint);
    canvas.drawCircle(Offset(c.dx + w * 0.12, c.dy - w * 0.04), w * 0.035, whitePaint);

    // Nose
    canvas.drawOval(Rect.fromCenter(center: Offset(c.dx, c.dy + w * 0.08), width: w * 0.08, height: w * 0.05), blackPaint);

    // Blush
    canvas.drawCircle(Offset(c.dx - w * 0.2, c.dy + w * 0.12), w * 0.05, pinkPaint);
    canvas.drawCircle(Offset(c.dx + w * 0.2, c.dy + w * 0.12), w * 0.05, pinkPaint);
  }

  // 1. CAT: Cream head, triangular ears, whiskers, :3 mouth
  void _drawCat(Canvas canvas, Offset c, double w) {
    final catColor = Paint()..color = const Color(0xFFFFD166);
    final earPink = Paint()..color = const Color(0xFFFF99C8);
    final darkPaint = Paint()..color = const Color(0xFF2B2D42);

    // Triangular Ears
    final earL = Path()
      ..moveTo(c.dx - w * 0.3, c.dy)
      ..lineTo(c.dx - w * 0.26, c.dy - w * 0.32)
      ..lineTo(c.dx - w * 0.08, c.dy - w * 0.2)
      ..close();
    final earR = Path()
      ..moveTo(c.dx + w * 0.3, c.dy)
      ..lineTo(c.dx + w * 0.26, c.dy - w * 0.32)
      ..lineTo(c.dx + w * 0.08, c.dy - w * 0.2)
      ..close();
    canvas.drawPath(earL, catColor);
    canvas.drawPath(earR, catColor);

    // Inner Ears
    final inL = Path()
      ..moveTo(c.dx - w * 0.26, c.dy - w * 0.05)
      ..lineTo(c.dx - w * 0.23, c.dy - w * 0.26)
      ..lineTo(c.dx - w * 0.11, c.dy - w * 0.16)
      ..close();
    final inR = Path()
      ..moveTo(c.dx + w * 0.26, c.dy - w * 0.05)
      ..lineTo(c.dx + w * 0.23, c.dy - w * 0.26)
      ..lineTo(c.dx + w * 0.11, c.dy - w * 0.16)
      ..close();
    canvas.drawPath(inL, earPink);
    canvas.drawPath(inR, earPink);

    // Head
    canvas.drawCircle(Offset(c.dx, c.dy + w * 0.04), w * 0.31, catColor);

    // Eyes
    canvas.drawCircle(Offset(c.dx - w * 0.12, c.dy), w * 0.045, darkPaint);
    canvas.drawCircle(Offset(c.dx + w * 0.12, c.dy), w * 0.045, darkPaint);
    canvas.drawCircle(Offset(c.dx - w * 0.135, c.dy - w * 0.015), w * 0.018, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(c.dx + w * 0.105, c.dy - w * 0.015), w * 0.018, Paint()..color = Colors.white);

    // Pink Nose
    canvas.drawCircle(Offset(c.dx, c.dy + w * 0.07), w * 0.025, earPink);

    // Whiskers
    final linePaint = Paint()
      ..color = const Color(0xFF2B2D42)
      ..strokeWidth = w * 0.025
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(c.dx - w * 0.18, c.dy + w * 0.07), Offset(c.dx - w * 0.32, c.dy + w * 0.05), linePaint);
    canvas.drawLine(Offset(c.dx + w * 0.18, c.dy + w * 0.07), Offset(c.dx + w * 0.32, c.dy + w * 0.05), linePaint);
  }

  // 2. FOX: Bright orange head, white cheeks, cute dark nose
  void _drawFox(Canvas canvas, Offset c, double w) {
    final orangePaint = Paint()..color = const Color(0xFFF77F00);
    final whitePaint = Paint()..color = Colors.white;
    final darkPaint = Paint()..color = const Color(0xFF1E1E24);

    // Ears
    final earL = Path()
      ..moveTo(c.dx - w * 0.3, c.dy)
      ..lineTo(c.dx - w * 0.25, c.dy - w * 0.34)
      ..lineTo(c.dx - w * 0.08, c.dy - w * 0.2)
      ..close();
    final earR = Path()
      ..moveTo(c.dx + w * 0.3, c.dy)
      ..lineTo(c.dx + w * 0.25, c.dy - w * 0.34)
      ..lineTo(c.dx + w * 0.08, c.dy - w * 0.2)
      ..close();
    canvas.drawPath(earL, darkPaint);
    canvas.drawPath(earR, darkPaint);

    // Head
    canvas.drawCircle(Offset(c.dx, c.dy + w * 0.04), w * 0.31, orangePaint);

    // White Cheek Mask
    final mask = Path()
      ..moveTo(c.dx, c.dy)
      ..lineTo(c.dx - w * 0.28, c.dy + w * 0.1)
      ..quadraticBezierTo(c.dx, c.dy + w * 0.35, c.dx + w * 0.28, c.dy + w * 0.1)
      ..close();
    canvas.drawPath(mask, whitePaint);

    // Eyes
    canvas.drawCircle(Offset(c.dx - w * 0.12, c.dy - w * 0.02), w * 0.04, darkPaint);
    canvas.drawCircle(Offset(c.dx + w * 0.12, c.dy - w * 0.02), w * 0.04, darkPaint);

    // Nose
    canvas.drawCircle(Offset(c.dx, c.dy + w * 0.14), w * 0.04, darkPaint);
  }

  // 3. PENGUIN: Dark blue head, white mask, yellow triangle beak
  void _drawPenguin(Canvas canvas, Offset c, double w) {
    final bodyPaint = Paint()..color = const Color(0xFF1D3557);
    final whitePaint = Paint()..color = Colors.white;
    final beakPaint = Paint()..color = const Color(0xFFFFB703);

    // Head
    canvas.drawCircle(Offset(c.dx, c.dy + w * 0.04), w * 0.32, bodyPaint);

    // White Face Mask
    canvas.drawOval(Rect.fromCenter(center: Offset(c.dx - w * 0.08, c.dy + w * 0.05), width: w * 0.2, height: w * 0.26), whitePaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(c.dx + w * 0.08, c.dy + w * 0.05), width: w * 0.2, height: w * 0.26), whitePaint);

    // Eyes
    final eyePaint = Paint()..color = const Color(0xFF1E1E24);
    canvas.drawCircle(Offset(c.dx - w * 0.08, c.dy + w * 0.02), w * 0.045, eyePaint);
    canvas.drawCircle(Offset(c.dx + w * 0.08, c.dy + w * 0.02), w * 0.045, eyePaint);
    canvas.drawCircle(Offset(c.dx - w * 0.095, c.dy), w * 0.018, whitePaint);
    canvas.drawCircle(Offset(c.dx + w * 0.065, c.dy), w * 0.018, whitePaint);

    // Beak
    final beak = Path()
      ..moveTo(c.dx - w * 0.06, c.dy + w * 0.08)
      ..lineTo(c.dx + w * 0.06, c.dy + w * 0.08)
      ..lineTo(c.dx, c.dy + w * 0.17)
      ..close();
    canvas.drawPath(beak, beakPaint);
  }

  // 4. BEAR: Honey brown round face, cute snout circle, black nose
  void _drawBear(Canvas canvas, Offset c, double w) {
    final bearColor = Paint()..color = const Color(0xFFB08968);
    final snoutColor = Paint()..color = const Color(0xFFE6CCB2);
    final darkPaint = Paint()..color = const Color(0xFF2B1E17);

    // Ears
    canvas.drawCircle(Offset(c.dx - w * 0.24, c.dy - w * 0.2), w * 0.11, bearColor);
    canvas.drawCircle(Offset(c.dx + w * 0.24, c.dy - w * 0.2), w * 0.11, bearColor);
    canvas.drawCircle(Offset(c.dx - w * 0.24, c.dy - w * 0.2), w * 0.06, snoutColor);
    canvas.drawCircle(Offset(c.dx + w * 0.24, c.dy - w * 0.2), w * 0.06, snoutColor);

    // Head
    canvas.drawCircle(Offset(c.dx, c.dy + w * 0.04), w * 0.31, bearColor);

    // Snout
    canvas.drawOval(Rect.fromCenter(center: Offset(c.dx, c.dy + w * 0.12), width: w * 0.26, height: w * 0.18), snoutColor);

    // Eyes
    canvas.drawCircle(Offset(c.dx - w * 0.12, c.dy - w * 0.02), w * 0.04, darkPaint);
    canvas.drawCircle(Offset(c.dx + w * 0.12, c.dy - w * 0.02), w * 0.04, darkPaint);

    // Nose
    canvas.drawOval(Rect.fromCenter(center: Offset(c.dx, c.dy + w * 0.08), width: w * 0.08, height: w * 0.05), darkPaint);
  }

  // 5. FROG: Lime green, bulging round eyes on top, wide happy smile
  void _drawFrog(Canvas canvas, Offset c, double w) {
    final greenPaint = Paint()..color = const Color(0xFF70E000);
    final whitePaint = Paint()..color = Colors.white;
    final darkPaint = Paint()..color = const Color(0xFF1E1E24);
    final pinkPaint = Paint()..color = const Color(0xFFFF70A6).withValues(alpha: 0.5);

    // Bulging Eyes on Top
    canvas.drawCircle(Offset(c.dx - w * 0.18, c.dy - w * 0.16), w * 0.13, greenPaint);
    canvas.drawCircle(Offset(c.dx + w * 0.18, c.dy - w * 0.16), w * 0.13, greenPaint);

    canvas.drawCircle(Offset(c.dx - w * 0.18, c.dy - w * 0.16), w * 0.09, whitePaint);
    canvas.drawCircle(Offset(c.dx + w * 0.18, c.dy - w * 0.16), w * 0.09, whitePaint);

    canvas.drawCircle(Offset(c.dx - w * 0.18, c.dy - w * 0.16), w * 0.05, darkPaint);
    canvas.drawCircle(Offset(c.dx + w * 0.18, c.dy - w * 0.16), w * 0.05, darkPaint);

    // Head
    canvas.drawOval(Rect.fromCenter(center: Offset(c.dx, c.dy + w * 0.06), width: w * 0.64, height: w * 0.48), greenPaint);

    // Blush
    canvas.drawCircle(Offset(c.dx - w * 0.2, c.dy + w * 0.1), w * 0.05, pinkPaint);
    canvas.drawCircle(Offset(c.dx + w * 0.2, c.dy + w * 0.1), w * 0.05, pinkPaint);

    // Wide Smile
    final smilePaint = Paint()
      ..color = darkPaint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.035
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(c.dx - w * 0.12, c.dy + w * 0.1)
      ..quadraticBezierTo(c.dx, c.dy + w * 0.2, c.dx + w * 0.12, c.dy + w * 0.1);
    canvas.drawPath(path, smilePaint);
  }

  // 6. CHICK: Sunshine yellow, orange beak, top feather tuft
  void _drawChick(Canvas canvas, Offset c, double w) {
    final yellowPaint = Paint()..color = const Color(0xFFFFD000);
    final orangePaint = Paint()..color = const Color(0xFFFF6B35);
    final darkPaint = Paint()..color = const Color(0xFF1E1E24);

    // Top Tuft
    canvas.drawCircle(Offset(c.dx - w * 0.04, c.dy - w * 0.28), w * 0.06, yellowPaint);
    canvas.drawCircle(Offset(c.dx + w * 0.04, c.dy - w * 0.3), w * 0.07, yellowPaint);

    // Head
    canvas.drawCircle(Offset(c.dx, c.dy + w * 0.02), w * 0.31, yellowPaint);

    // Eyes
    canvas.drawCircle(Offset(c.dx - w * 0.12, c.dy), w * 0.045, darkPaint);
    canvas.drawCircle(Offset(c.dx + w * 0.12, c.dy), w * 0.045, darkPaint);
    canvas.drawCircle(Offset(c.dx - w * 0.135, c.dy - w * 0.015), w * 0.018, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(c.dx + w * 0.105, c.dy - w * 0.015), w * 0.018, Paint()..color = Colors.white);

    // Beak
    final beak = Path()
      ..moveTo(c.dx - w * 0.08, c.dy + w * 0.06)
      ..lineTo(c.dx + w * 0.08, c.dy + w * 0.06)
      ..lineTo(c.dx, c.dy + w * 0.16)
      ..close();
    canvas.drawPath(beak, orangePaint);
  }

  // 7. BUNNY: Long ears with pink inside, white round face, twitchy nose
  void _drawBunny(Canvas canvas, Offset c, double w) {
    final whitePaint = Paint()..color = Colors.white;
    final pinkPaint = Paint()..color = const Color(0xFFFF99C8);
    final darkPaint = Paint()..color = const Color(0xFF2B2D42);

    // Long Ears
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(c.dx - w * 0.13, c.dy - w * 0.26), width: w * 0.12, height: w * 0.32), Radius.circular(w * 0.06)), whitePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(c.dx + w * 0.13, c.dy - w * 0.26), width: w * 0.12, height: w * 0.32), Radius.circular(w * 0.06)), whitePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(c.dx - w * 0.13, c.dy - w * 0.26), width: w * 0.06, height: w * 0.22), Radius.circular(w * 0.03)), pinkPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(c.dx + w * 0.13, c.dy - w * 0.26), width: w * 0.06, height: w * 0.22), Radius.circular(w * 0.03)), pinkPaint);

    // Head
    canvas.drawCircle(Offset(c.dx, c.dy + w * 0.06), w * 0.3, whitePaint);

    // Eyes
    canvas.drawCircle(Offset(c.dx - w * 0.12, c.dy + w * 0.03), w * 0.04, darkPaint);
    canvas.drawCircle(Offset(c.dx + w * 0.12, c.dy + w * 0.03), w * 0.04, darkPaint);

    // Pink Nose
    canvas.drawCircle(Offset(c.dx, c.dy + w * 0.1), w * 0.025, pinkPaint);
  }

  // 8. ROBOT: Metallic cyan head, bright screen, glowing eyes, antenna
  void _drawRobot(Canvas canvas, Offset c, double w) {
    final metalPaint = Paint()..color = const Color(0xFF48CAE4);
    final screenPaint = Paint()..color = const Color(0xFF03045E);
    final glowPaint = Paint()..color = const Color(0xFF00F5D4);

    // Antenna
    canvas.drawLine(
      Offset(c.dx, c.dy - w * 0.2),
      Offset(c.dx, c.dy - w * 0.36),
      Paint()
        ..color = const Color(0xFF0077B6)
        ..strokeWidth = w * 0.04
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(Offset(c.dx, c.dy - w * 0.36), w * 0.06, Paint()..color = const Color(0xFFFFD166));

    // Head Box
    final headRect = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(c.dx, c.dy + w * 0.04), width: w * 0.62, height: w * 0.52), Radius.circular(w * 0.12));
    canvas.drawRRect(headRect, metalPaint);

    // Screen
    final screenRect = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(c.dx, c.dy + w * 0.04), width: w * 0.48, height: w * 0.36), Radius.circular(w * 0.08));
    canvas.drawRRect(screenRect, screenPaint);

    // Glowing Eyes
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(c.dx - w * 0.12, c.dy + w * 0.02), width: w * 0.09, height: w * 0.09), Radius.circular(w * 0.02)), glowPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(c.dx + w * 0.12, c.dy + w * 0.02), width: w * 0.09, height: w * 0.09), Radius.circular(w * 0.02)), glowPaint);
  }

  // 9. ASTRONAUT: White dome helmet, cyan reflective visor
  void _drawAstronaut(Canvas canvas, Offset c, double w) {
    final helmetPaint = Paint()..color = const Color(0xFFF8F9FA);
    final visorPaint = Paint()..color = const Color(0xFF0077B6);

    // Helmet Dome
    canvas.drawCircle(Offset(c.dx, c.dy + w * 0.02), w * 0.34, helmetPaint);

    // Cyan Visor
    final visorRect = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(c.dx, c.dy + w * 0.02), width: w * 0.48, height: w * 0.36), Radius.circular(w * 0.14));
    canvas.drawRRect(visorRect, visorPaint);

    // Friendly Visor Face
    final faceGlow = Paint()..color = const Color(0xFF90E0EF);
    canvas.drawCircle(Offset(c.dx - w * 0.11, c.dy), w * 0.035, faceGlow);
    canvas.drawCircle(Offset(c.dx + w * 0.11, c.dy), w * 0.035, faceGlow);

    // Reflection Glare
    final glare = Path()
      ..moveTo(c.dx - w * 0.18, c.dy - w * 0.1)
      ..lineTo(c.dx - w * 0.08, c.dy - w * 0.1)
      ..lineTo(c.dx - w * 0.14, c.dy + w * 0.06)
      ..close();
    canvas.drawPath(glare, Paint()..color = Colors.white.withValues(alpha: 0.3));
  }

  // 10. DINO: Mint green, yellow dorsal crest, toothy happy grin
  void _drawDino(Canvas canvas, Offset c, double w) {
    final greenPaint = Paint()..color = const Color(0xFF38B000);
    final yellowPaint = Paint()..color = const Color(0xFFFFD166);
    final darkPaint = Paint()..color = const Color(0xFF1E1E24);

    // Dorsal Spikes
    canvas.drawCircle(Offset(c.dx - w * 0.22, c.dy - w * 0.18), w * 0.07, yellowPaint);
    canvas.drawCircle(Offset(c.dx, c.dy - w * 0.28), w * 0.08, yellowPaint);
    canvas.drawCircle(Offset(c.dx + w * 0.22, c.dy - w * 0.18), w * 0.07, yellowPaint);

    // Head
    canvas.drawCircle(Offset(c.dx, c.dy + w * 0.04), w * 0.31, greenPaint);

    // Eyes
    canvas.drawCircle(Offset(c.dx - w * 0.12, c.dy - w * 0.02), w * 0.045, darkPaint);
    canvas.drawCircle(Offset(c.dx + w * 0.12, c.dy - w * 0.02), w * 0.045, darkPaint);
    canvas.drawCircle(Offset(c.dx - w * 0.135, c.dy - w * 0.035), w * 0.018, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(c.dx + w * 0.105, c.dy - w * 0.035), w * 0.018, Paint()..color = Colors.white);

    // Toothy Smile
    final smile = Path()
      ..moveTo(c.dx - w * 0.12, c.dy + w * 0.1)
      ..quadraticBezierTo(c.dx, c.dy + w * 0.22, c.dx + w * 0.12, c.dy + w * 0.1)
      ..close();
    canvas.drawPath(smile, Paint()..color = Colors.white);
    canvas.drawPath(
      smile,
      Paint()
        ..color = darkPaint.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.02,
    );
  }

  // 11. BOBA: Pink milk cup, dark pearls, smiling face, straw
  void _drawBoba(Canvas canvas, Offset c, double w) {
    final cupPaint = Paint()..color = const Color(0xFFFFC6FF);
    final darkPaint = Paint()..color = const Color(0xFF2B2D42);

    // Straw
    canvas.drawLine(
      Offset(c.dx + w * 0.06, c.dy - w * 0.1),
      Offset(c.dx + w * 0.16, c.dy - w * 0.36),
      Paint()
        ..color = const Color(0xFFFF70A6)
        ..strokeWidth = w * 0.06
        ..strokeCap = StrokeCap.round,
    );

    // Cup
    final cup = Path()
      ..moveTo(c.dx - w * 0.22, c.dy - w * 0.12)
      ..lineTo(c.dx + w * 0.22, c.dy - w * 0.12)
      ..lineTo(c.dx + w * 0.17, c.dy + w * 0.3)
      ..lineTo(c.dx - w * 0.17, c.dy + w * 0.3)
      ..close();
    canvas.drawPath(cup, cupPaint);

    // Boba Pearls at bottom
    canvas.drawCircle(Offset(c.dx - w * 0.08, c.dy + w * 0.22), w * 0.04, darkPaint);
    canvas.drawCircle(Offset(c.dx, c.dy + w * 0.24), w * 0.04, darkPaint);
    canvas.drawCircle(Offset(c.dx + w * 0.08, c.dy + w * 0.22), w * 0.04, darkPaint);

    // Cute Face
    canvas.drawCircle(Offset(c.dx - w * 0.09, c.dy + w * 0.04), w * 0.035, darkPaint);
    canvas.drawCircle(Offset(c.dx + w * 0.09, c.dy + w * 0.04), w * 0.035, darkPaint);
  }

  // 12. DONUT: Chocolate glazed donut, sprinkles, cute smile
  void _drawDonut(Canvas canvas, Offset c, double w) {
    final doughPaint = Paint()..color = const Color(0xFFE9C46A);
    final chocoPaint = Paint()..color = const Color(0xFF6F1D1B);
    final darkPaint = Paint()..color = const Color(0xFF1E1E24);

    // Dough Base
    canvas.drawCircle(Offset(c.dx, c.dy + w * 0.02), w * 0.34, doughPaint);

    // Chocolate Glaze
    canvas.drawCircle(Offset(c.dx, c.dy + w * 0.02), w * 0.29, chocoPaint);

    // Center Hole
    canvas.drawCircle(Offset(c.dx, c.dy + w * 0.02), w * 0.11, spec.bgColors[0] == Colors.transparent ? doughPaint : Paint()..color = spec.bgColors[0]);

    // Sprinkles
    canvas.drawCircle(Offset(c.dx - w * 0.16, c.dy - w * 0.1), w * 0.02, Paint()..color = const Color(0xFFFF99C8));
    canvas.drawCircle(Offset(c.dx + w * 0.14, c.dy - w * 0.12), w * 0.02, Paint()..color = const Color(0xFF00F5D4));
    canvas.drawCircle(Offset(c.dx + w * 0.18, c.dy + w * 0.06), w * 0.02, Paint()..color = const Color(0xFFFFD166));

    // Cute Eyes on Glaze
    canvas.drawCircle(Offset(c.dx - w * 0.14, c.dy + w * 0.12), w * 0.03, Colors.white == darkPaint.color ? darkPaint : Paint()..color = Colors.white);
    canvas.drawCircle(Offset(c.dx + w * 0.14, c.dy + w * 0.12), w * 0.03, Colors.white == darkPaint.color ? darkPaint : Paint()..color = Colors.white);
  }

  // 13. CROISSANT: Golden curved pastry, rosy cheeks
  void _drawCroissant(Canvas canvas, Offset c, double w) {
    final goldPaint = Paint()..color = const Color(0xFFF4A261);
    final darkPaint = Paint()..color = const Color(0xFF1E1E24);
    final pinkPaint = Paint()..color = const Color(0xFFFF70A6).withValues(alpha: 0.6);

    // Main Crescent
    final crescent = Path()
      ..moveTo(c.dx - w * 0.3, c.dy + w * 0.14)
      ..quadraticBezierTo(c.dx, c.dy - w * 0.28, c.dx + w * 0.3, c.dy + w * 0.14)
      ..quadraticBezierTo(c.dx, c.dy - w * 0.05, c.dx - w * 0.3, c.dy + w * 0.14)
      ..close();
    canvas.drawPath(crescent, goldPaint);

    // Happy Wink Eyes (^^)
    final pathL = Path()
      ..moveTo(c.dx - w * 0.12, c.dy - w * 0.04)
      ..quadraticBezierTo(c.dx - w * 0.08, c.dy - w * 0.08, c.dx - w * 0.04, c.dy - w * 0.04);
    final pathR = Path()
      ..moveTo(c.dx + w * 0.04, c.dy - w * 0.04)
      ..quadraticBezierTo(c.dx + w * 0.08, c.dy - w * 0.08, c.dx + w * 0.12, c.dy - w * 0.04);
    final eyeP = Paint()
      ..color = darkPaint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.03
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(pathL, eyeP);
    canvas.drawPath(pathR, eyeP);

    // Blush
    canvas.drawCircle(Offset(c.dx - w * 0.13, c.dy + w * 0.02), w * 0.035, pinkPaint);
    canvas.drawCircle(Offset(c.dx + w * 0.13, c.dy + w * 0.02), w * 0.035, pinkPaint);
  }

  // 14. STRAWBERRY: Ruby red, yellow seeds, green leafy crown
  void _drawStrawberry(Canvas canvas, Offset c, double w) {
    final redPaint = Paint()..color = const Color(0xFFE63946);
    final greenPaint = Paint()..color = const Color(0xFF52B788);
    final darkPaint = Paint()..color = const Color(0xFF1E1E24);
    final seedPaint = Paint()..color = const Color(0xFFFFD166);

    // Leaf Crown
    canvas.drawCircle(Offset(c.dx - w * 0.12, c.dy - w * 0.2), w * 0.08, greenPaint);
    canvas.drawCircle(Offset(c.dx + w * 0.12, c.dy - w * 0.2), w * 0.08, greenPaint);
    canvas.drawCircle(Offset(c.dx, c.dy - w * 0.24), w * 0.09, greenPaint);

    // Berry Body
    final berry = Path()
      ..moveTo(c.dx - w * 0.24, c.dy - w * 0.14)
      ..lineTo(c.dx + w * 0.24, c.dy - w * 0.14)
      ..quadraticBezierTo(c.dx + w * 0.22, c.dy + w * 0.18, c.dx, c.dy + w * 0.32)
      ..quadraticBezierTo(c.dx - w * 0.22, c.dy + w * 0.18, c.dx - w * 0.24, c.dy - w * 0.14)
      ..close();
    canvas.drawPath(berry, redPaint);

    // Seeds
    canvas.drawCircle(Offset(c.dx - w * 0.14, c.dy - w * 0.04), w * 0.015, seedPaint);
    canvas.drawCircle(Offset(c.dx + w * 0.14, c.dy - w * 0.04), w * 0.015, seedPaint);
    canvas.drawCircle(Offset(c.dx, c.dy + w * 0.18), w * 0.015, seedPaint);

    // Eyes
    canvas.drawCircle(Offset(c.dx - w * 0.09, c.dy + w * 0.04), w * 0.035, darkPaint);
    canvas.drawCircle(Offset(c.dx + w * 0.09, c.dy + w * 0.04), w * 0.035, darkPaint);
  }

  // 15. TIRAMISU: Layered cake slice with cocoa powder and chocolate curls
  void _drawTiramisu(Canvas canvas, Offset c, double w) {
    final creamPaint = Paint()..color = const Color(0xFFFFF1E6);
    final cakePaint = Paint()..color = const Color(0xFFDDA15E);
    final cocoaPaint = Paint()..color = const Color(0xFF6F1D1B);
    final darkPaint = Paint()..color = const Color(0xFF1E1E24);
    final pinkPaint = Paint()..color = const Color(0xFFFF99C8).withValues(alpha: 0.7);

    // Layer 1 (Bottom Cake)
    final rrectB = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(c.dx, c.dy + w * 0.18), width: w * 0.54, height: w * 0.12), Radius.circular(w * 0.04));
    canvas.drawRRect(rrectB, cakePaint);

    // Layer 2 (Mascarpone Cream)
    final rrectM = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(c.dx, c.dy + w * 0.06), width: w * 0.56, height: w * 0.14), Radius.circular(w * 0.04));
    canvas.drawRRect(rrectM, creamPaint);

    // Layer 3 (Top Cocoa Powder)
    final rrectT = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(c.dx, c.dy - w * 0.06), width: w * 0.54, height: w * 0.12), Radius.circular(w * 0.04));
    canvas.drawRRect(rrectT, cocoaPaint);

    // Mint Leaf on top
    canvas.drawOval(Rect.fromCenter(center: Offset(c.dx - w * 0.06, c.dy - w * 0.18), width: w * 0.1, height: w * 0.06), Paint()..color = const Color(0xFF52B788));
    canvas.drawOval(Rect.fromCenter(center: Offset(c.dx + w * 0.06, c.dy - w * 0.18), width: w * 0.1, height: w * 0.06), Paint()..color = const Color(0xFF74C69D));

    // Cute Eyes on Cream Layer
    canvas.drawCircle(Offset(c.dx - w * 0.11, c.dy + w * 0.06), w * 0.035, darkPaint);
    canvas.drawCircle(Offset(c.dx + w * 0.11, c.dy + w * 0.06), w * 0.035, darkPaint);

    // Blush
    canvas.drawCircle(Offset(c.dx - w * 0.19, c.dy + w * 0.08), w * 0.03, pinkPaint);
    canvas.drawCircle(Offset(c.dx + w * 0.19, c.dy + w * 0.08), w * 0.03, pinkPaint);
  }

  @override
  bool shouldRepaint(covariant _AvatarPainter oldDelegate) =>
      oldDelegate.spec.species != spec.species ||
      oldDelegate.spec.bgColors != spec.bgColors ||
      oldDelegate.spec.badgePattern != spec.badgePattern;
}
