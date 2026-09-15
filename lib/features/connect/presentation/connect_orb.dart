import 'package:flutter/material.dart';
import 'package:shahkar_connect/theme.dart';

class ConnectOrb extends StatefulWidget {
  const ConnectOrb({
    super.key,
    required this.connected,
    required this.connecting,
    required this.onTap,
  });

  final bool connected;
  final bool connecting;
  final VoidCallback? onTap;

  @override
  State<ConnectOrb> createState() => _ConnectOrbState();
}

class _ConnectOrbState extends State<ConnectOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final color =
        widget.connected
            ? ShahkarTheme.connected
            : Theme.of(context).colorScheme.outline;
    return Semantics(
      button: true,
      label:
          widget.connecting
              ? 'در حال اتصال'
              : widget.connected
              ? 'قطع اتصال'
              : 'اتصال',
      child: Material(
        color: color.withValues(alpha: 0.10),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: widget.onTap,
          child: SizedBox(
            height: 200,
            width: 200,
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (context, child) {
                final t = reduce ? 0.35 : _pulse.value;
                return CustomPaint(
                  painter: _OrbPainter(
                    color: color,
                    connected: widget.connected,
                    connecting: widget.connecting,
                    t: t,
                  ),
                  child: child,
                );
              },
              child: Center(
                child:
                    widget.connecting
                        ? SizedBox(
                          height: 36,
                          width: 36,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: color,
                          ),
                        )
                        : Icon(
                          Icons.power_settings_new,
                          size: 64,
                          color: color,
                        ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrbPainter extends CustomPainter {
  _OrbPainter({
    required this.color,
    required this.connected,
    required this.connecting,
    required this.t,
  });

  final Color color;
  final bool connected;
  final bool connecting;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final base = size.shortestSide / 2 - 8;
    for (var i = 0; i < 3; i++) {
      final grow = connected || connecting ? t * 10 * (i + 1) : 0.0;
      final paint =
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = connected ? 2.2 : 1.2
            ..color = color.withValues(alpha: 0.18 + (0.12 * (2 - i)) * t);
      canvas.drawCircle(c, base - i * 14 + grow, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbPainter old) =>
      old.t != t || old.connected != connected || old.color != color;
}
