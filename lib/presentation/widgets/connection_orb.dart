import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:rah_app/core/theme/rah_colors.dart';
import 'package:rah_app/domain/entities/aether_state.dart';
import 'package:rah_app/l10n/generated/app_localizations.dart';



class ConnectionOrb extends StatefulWidget {
  const ConnectionOrb({
    super.key,
    required this.state,
    required this.onTap,
    this.disabledSeconds = 0,
  });

  final AetherState state;
  final VoidCallback? onTap;
  final int disabledSeconds;

  @override
  State<ConnectionOrb> createState() => _OrbState();
}

class _OrbState extends State<ConnectionOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.of(context).disableAnimations;
    _sync();
  }

  @override
  void didUpdateWidget(ConnectionOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final animate =
        !_reduceMotion &&
        (widget.state == AetherState.starting ||
            widget.state == AetherState.connected);
    if (animate) {
      if (!_c.isAnimating) _c.repeat();
    } else {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Color get _color => switch (widget.state) {
    AetherState.connected => RahColors.jade,
    AetherState.starting || AetherState.stopping => RahColors.amber,
    AetherState.error => RahColors.coral,
    AetherState.idle => RahColors.mist,
  };

  bool get _filled =>
      widget.state == AetherState.connected ||
      widget.state == AetherState.starting ||
      widget.state == AetherState.stopping;

  String _label(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return switch (widget.state) {
      AetherState.connected => l.disconnecting,
      AetherState.starting => l.cancelConnection,
      AetherState.stopping => l.disconnecting,
      _ => l.connect,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: widget.onTap != null,
      label: _label(context),
      child: SizedBox(
        width: 300,
        height: 300,
        child: TweenAnimationBuilder<Color?>(
          tween: ColorTween(end: _color),
          duration: const Duration(milliseconds: 400),
          builder: (context, color, _) {
            final c = color ?? _color;
            return Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _c,
                      builder: (_, __) => CustomPaint(
                        painter: _OrbPainter(
                          t: _c.value,
                          color: c,
                          state: widget.state,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 156,
                  height: 156,
                  child: Material(
                    type: MaterialType.transparency,
                    child: InkResponse(
                      customBorder: const CircleBorder(),
                      onTap: widget.onTap,
                      splashColor: c.withValues(alpha: 0.25),
                      child: Center(
                        child: widget.disabledSeconds > 0
                            ? Text(
                                '${widget.disabledSeconds}',
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w700,
                                  color: RahColors.ink,
                                ),
                              )
                            : Icon(
                                Icons.power_settings_new_rounded,
                                size: 54,
                                color: _filled ? RahColors.ink : c,
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OrbPainter extends CustomPainter {
  _OrbPainter({required this.t, required this.color, required this.state});

  final double t;
  final Color color;
  final AetherState state;

  static const _core = 78.0;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final maxR = size.shortestSide / 2;
    final scanning = state == AetherState.starting;
    final connected = state == AetherState.connected;

    if (scanning || connected) {
      final breathe = connected ? 0.5 + 0.5 * math.sin(t * 2 * math.pi) : 0.6;
      canvas.drawCircle(
        c,
        maxR,
        Paint()
          ..shader = RadialGradient(
            colors: [
              color.withValues(alpha: 0.24 + 0.10 * breathe),
              color.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: c, radius: maxR)),
      );
    }

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    if (scanning) {
      // Rings travel outward while the core looks for a route.
      for (var i = 0; i < 3; i++) {
        final p = (t + i / 3) % 1.0;
        ring.color = color.withValues(alpha: (1 - p) * 0.55);
        canvas.drawCircle(c, _core + (maxR - _core) * p, ring);
      }
    } else if (connected) {
      ring.color = color.withValues(alpha: 0.35);
      canvas.drawCircle(c, _core + 16, ring);
      ring.color = color.withValues(alpha: 0.16);
      canvas.drawCircle(c, _core + 38, ring);
    } else {
      ring.color = color.withValues(alpha: 0.4);
      canvas.drawCircle(c, _core + 16, ring);
    }

    final filled = scanning || connected || state == AetherState.stopping;
    if (filled) {
      canvas.drawCircle(
        c,
        _core,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.3, -0.4),
            colors: [Color.lerp(color, Colors.white, 0.28)!, color],
          ).createShader(Rect.fromCircle(center: c, radius: _core)),
      );
    } else {
      canvas.drawCircle(c, _core, Paint()..color = RahColors.panel);
      canvas.drawCircle(
        c,
        _core,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = color.withValues(alpha: 0.7),
      );
    }
  }

  @override
  bool shouldRepaint(_OrbPainter old) =>
      old.t != t || old.color != color || old.state != state;
}

// ---------------------------------------------------------------------------
