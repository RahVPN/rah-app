import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Paints flags in Flutter instead of using regional-indicator emoji, whose
/// glyph and color support depends on the host Linux desktop's emoji fonts.
class CountryFlagIcon extends StatelessWidget {
  const CountryFlagIcon({super.key, required this.country, this.width = 28});

  final String? country;
  final double width;

  @override
  Widget build(BuildContext context) {
    final code = country?.toUpperCase();
    if (code == null ||
        !RegExp(r'^[A-Z]{2}$').hasMatch(code) ||
        code == 'XX' ||
        code == 'T1') {
      return const SizedBox.shrink();
    }
    if (code == 'IR') {
      return Image.asset(
        'assets/icon/iran_flag_emoji.png',
        width: width,
        height: width * 0.67,
        fit: BoxFit.cover,
        semanticLabel: 'Iran flag',
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: CustomPaint(
        size: Size(width, width * 0.67),
        painter: _FlagPainter(code),
        child: SizedBox(width: width, height: width * 0.67),
      ),
    );
  }
}

class _FlagPainter extends CustomPainter {
  const _FlagPainter(this.code);

  final String code;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const colors = _colors;
    void rect(Color color, double x, double y, double width, double height) {
      canvas.drawRect(
        Rect.fromLTWH(x * w, y * h, width * w, height * h),
        Paint()..color = color,
      );
    }

    void horizontal(List<Color> stripes) {
      final stripeHeight = 1 / stripes.length;
      for (var i = 0; i < stripes.length; i++) {
        rect(stripes[i], 0, i * stripeHeight, 1, stripeHeight + 0.002);
      }
    }

    void vertical(List<Color> stripes) {
      final stripeWidth = 1 / stripes.length;
      for (var i = 0; i < stripes.length; i++) {
        rect(stripes[i], i * stripeWidth, 0, stripeWidth + 0.002, 1);
      }
    }

    switch (code) {
      case 'DE':
        horizontal([colors.black, colors.red, colors.gold]);
      case 'NL':
        horizontal([colors.red, colors.white, colors.blue]);
      case 'FR':
        vertical([colors.blue, colors.white, colors.red]);
      case 'GB':
        _paintUnitedKingdom(canvas, size, colors);
      case 'US':
        _paintUnitedStates(canvas, size, colors);
      case 'CA':
        rect(colors.red, 0, 0, 0.25, 1);
        rect(colors.white, 0.25, 0, 0.5, 1);
        rect(colors.red, 0.75, 0, 0.25, 1);
        final maple = Path()
          ..moveTo(w * 0.50, h * 0.22)
          ..lineTo(w * 0.57, h * 0.39)
          ..lineTo(w * 0.68, h * 0.34)
          ..lineTo(w * 0.63, h * 0.50)
          ..lineTo(w * 0.72, h * 0.56)
          ..lineTo(w * 0.57, h * 0.61)
          ..lineTo(w * 0.55, h * 0.77)
          ..lineTo(w * 0.45, h * 0.77)
          ..lineTo(w * 0.43, h * 0.61)
          ..lineTo(w * 0.28, h * 0.56)
          ..lineTo(w * 0.37, h * 0.50)
          ..lineTo(w * 0.32, h * 0.34)
          ..lineTo(w * 0.43, h * 0.39)
          ..close();
        canvas.drawPath(maple, Paint()..color = colors.red);
      case 'SE':
        rect(colors.blue, 0, 0, 1, 1);
        rect(colors.gold, 0.30, 0, 0.10, 1);
        rect(colors.gold, 0, 0.42, 1, 0.16);
      case 'FI':
        rect(colors.white, 0, 0, 1, 1);
        rect(colors.blue, 0.30, 0, 0.12, 1);
        rect(colors.blue, 0, 0.42, 1, 0.16);
      case 'CH':
        rect(colors.red, 0, 0, 1, 1);
        rect(colors.white, 0.42, 0.22, 0.16, 0.56);
        rect(colors.white, 0.28, 0.40, 0.44, 0.20);
      case 'LU':
        horizontal([colors.red, colors.white, const Color(0xff6da9d2)]);
      case 'AT':
        horizontal([colors.red, colors.white, colors.red]);
      case 'JP':
        rect(colors.white, 0, 0, 1, 1);
        canvas.drawCircle(
          Offset(w * 0.5, h * 0.5),
          h * 0.27,
          Paint()..color = colors.red,
        );
      case 'IT':
      case 'IE':
      case 'BE':
      case 'RO':
        vertical(switch (code) {
          'IT' => [colors.green, colors.white, colors.red],
          'IE' => [colors.green, colors.white, colors.orange],
          'BE' => [colors.black, colors.gold, colors.red],
          _ => [colors.blue, colors.gold, colors.red],
        });
      case 'DK':
        rect(colors.red, 0, 0, 1, 1);
        rect(colors.white, 0.30, 0, 0.10, 1);
        rect(colors.white, 0, 0.43, 1, 0.14);
      case 'NO':
        rect(colors.red, 0, 0, 1, 1);
        rect(colors.white, 0.27, 0, 0.16, 1);
        rect(colors.white, 0, 0.38, 1, 0.24);
        rect(colors.blue, 0.31, 0, 0.08, 1);
        rect(colors.blue, 0, 0.43, 1, 0.14);
      case 'GR':
        horizontal([
          colors.blue,
          colors.white,
          colors.blue,
          colors.white,
          colors.blue,
        ]);
        rect(colors.blue, 0, 0, 0.4, 0.56);
        rect(colors.white, 0.15, 0, 0.1, 0.56);
        rect(colors.white, 0, 0.23, 0.4, 0.1);
      case 'UA':
        horizontal([colors.blue, colors.gold]);
      case 'PL':
        horizontal([colors.white, colors.red]);
      case 'ES':
        horizontal([colors.red, colors.gold, colors.red]);
      case 'BG':
        horizontal([colors.white, colors.green, colors.red]);
      case 'HU':
        horizontal([colors.red, colors.white, colors.green]);
      case 'LT':
        horizontal([colors.gold, colors.green, colors.red]);
      case 'LV':
        horizontal([colors.maroon, colors.white, colors.maroon]);
      case 'EE':
        horizontal([colors.blue, colors.black, colors.white]);
      case 'SG':
        horizontal([colors.red, colors.white]);
      case 'PT':
        vertical([colors.green, colors.red]);
        canvas.drawCircle(
          Offset(w * 0.39, h * 0.5),
          h * 0.15,
          Paint()..color = colors.gold,
        );
      case 'AE':
        horizontal([colors.green, colors.white, colors.black]);
        rect(colors.red, 0, 0, 0.24, 1);
      case 'CZ':
        horizontal([colors.white, colors.red]);
        final triangle = Path()
          ..moveTo(0, 0)
          ..lineTo(w * 0.48, h * 0.5)
          ..lineTo(0, h)
          ..close();
        canvas.drawPath(triangle, Paint()..color = colors.blue);
      case 'IN':
        horizontal([colors.orange, colors.white, colors.green]);
        canvas.drawCircle(
          Offset(w * 0.5, h * 0.5),
          h * 0.13,
          Paint()
            ..color = colors.blue
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
      case 'AU':
        rect(colors.blue, 0, 0, 1, 1);
        canvas.save();
        canvas.clipRect(Rect.fromLTWH(0, 0, w * 0.5, h * 0.5));
        canvas.scale(0.50, 0.50);
        _paintUnitedKingdom(canvas, Size(w, h), colors);
        canvas.restore();
        for (final point in [
          Offset(w * 0.73, h * 0.26),
          Offset(w * 0.86, h * 0.48),
          Offset(w * 0.68, h * 0.70),
          Offset(w * 0.88, h * 0.82),
          Offset(w * 0.52, h * 0.88),
        ]) {
          canvas.drawCircle(point, 1.1, Paint()..color = colors.white);
        }
      case 'HK':
        rect(colors.red, 0, 0, 1, 1);
        for (var petal = 0; petal < 5; petal++) {
          final angle = -math.pi / 2 + petal * 2 * math.pi / 5;
          canvas.drawCircle(
            Offset(
              w * (0.5 + 0.15 * math.cos(angle)),
              h * (0.5 + 0.18 * math.sin(angle)),
            ),
            h * 0.10,
            Paint()..color = colors.white,
          );
        }
        canvas.drawCircle(
          Offset(w * 0.5, h * 0.5),
          h * 0.055,
          Paint()..color = colors.red,
        );
      case 'KR':
        rect(colors.white, 0, 0, 1, 1);
        canvas.drawCircle(
          Offset(w * 0.5, h * 0.43),
          h * 0.20,
          Paint()..color = colors.red,
        );
        canvas.drawArc(
          Rect.fromCircle(center: Offset(w * 0.5, h * 0.57), radius: h * 0.20),
          0,
          math.pi,
          true,
          Paint()..color = colors.blue,
        );
      case 'BR':
        rect(colors.green, 0, 0, 1, 1);
        final diamond = Path()
          ..moveTo(w * 0.5, h * 0.14)
          ..lineTo(w * 0.86, h * 0.5)
          ..lineTo(w * 0.5, h * 0.86)
          ..lineTo(w * 0.14, h * 0.5)
          ..close();
        canvas.drawPath(diamond, Paint()..color = colors.gold);
        canvas.drawCircle(
          Offset(w * 0.5, h * 0.5),
          h * 0.20,
          Paint()..color = colors.blue,
        );
      case 'TR':
        rect(colors.red, 0, 0, 1, 1);
        canvas.drawCircle(
          Offset(w * 0.43, h * 0.5),
          h * 0.25,
          Paint()..color = colors.white,
        );
        canvas.drawCircle(
          Offset(w * 0.49, h * 0.46),
          h * 0.20,
          Paint()..color = colors.red,
        );
        _star(canvas, Offset(w * 0.68, h * 0.5), h * 0.12, colors.white);
      default:
        rect(const Color(0xffe8edf2), 0, 0, 1, 1);
        final text = TextPainter(
          text: TextSpan(
            text: code,
            style: const TextStyle(
              color: Color(0xff394858),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: w);
        text.paint(canvas, Offset((w - text.width) / 2, (h - text.height) / 2));
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(3)),
      Paint()
        ..color = const Color(0x55000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7,
    );
  }

  void _paintUnitedKingdom(Canvas canvas, Size size, _FlagColors c) {
    final w = size.width;
    final h = size.height;
    canvas.drawColor(c.blue, BlendMode.src);
    void diagonal(Color color, double thickness) {
      final paint = Paint()
        ..color = color
        ..strokeWidth = thickness
        ..strokeCap = StrokeCap.square;
      canvas.drawLine(Offset.zero, Offset(w, h), paint);
      canvas.drawLine(Offset(w, 0), Offset(0, h), paint);
    }

    diagonal(c.white, h * 0.42);
    diagonal(c.red, h * 0.17);
    canvas.drawRect(
      Rect.fromLTWH(w * 0.40, 0, w * 0.20, h),
      Paint()..color = c.white,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.34, w, h * 0.32),
      Paint()..color = c.white,
    );
    canvas.drawRect(
      Rect.fromLTWH(w * 0.45, 0, w * 0.10, h),
      Paint()..color = c.red,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.41, w, h * 0.18),
      Paint()..color = c.red,
    );
  }

  void _paintUnitedStates(Canvas canvas, Size size, _FlagColors c) {
    final stripeHeight = size.height / 13;
    for (var i = 0; i < 13; i++) {
      canvas.drawRect(
        Rect.fromLTWH(0, i * stripeHeight, size.width, stripeHeight + 0.2),
        Paint()..color = i.isEven ? c.red : c.white,
      );
    }
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width * 0.42, stripeHeight * 7),
      Paint()..color = c.blue,
    );
    for (var row = 0; row < 5; row++) {
      for (var col = 0; col < 5; col++) {
        canvas.drawCircle(
          Offset(
            size.width * (0.06 + col * 0.075),
            stripeHeight * (0.65 + row * 1.3),
          ),
          0.45,
          Paint()..color = c.white,
        );
      }
    }
  }

  void _star(Canvas canvas, Offset center, double radius, Color color) {
    final path = Path();
    for (var point = 0; point < 10; point++) {
      final r = point.isEven ? radius : radius * 0.42;
      final angle = -math.pi / 2 + point * math.pi / 5;
      final p = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );
      if (point == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_FlagPainter oldDelegate) => oldDelegate.code != code;
}

class _FlagColors {
  const _FlagColors();

  final black = const Color(0xff111111);
  final blue = const Color(0xff174a8b);
  final red = const Color(0xffd21f35);
  final white = const Color(0xffffffff);
  final gold = const Color(0xffffd43b);
  final green = const Color(0xff178746);
  final orange = const Color(0xffff9933);
  final maroon = const Color(0xff8c1c35);
}

const _colors = _FlagColors();
