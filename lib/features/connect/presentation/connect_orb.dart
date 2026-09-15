import 'package:flutter/material.dart';
import 'package:shahkar_connect/theme.dart';

/// Purple rounded-square power button exactly like the mockup.
class ConnectOrb extends StatefulWidget {
  const ConnectOrb({
    super.key,
    required this.connected,
    required this.connecting,
    required this.onTap,
    this.size = 128,
    this.connectLabel = 'Connect',
    this.disconnectLabel = 'Disconnect',
    this.connectingLabel = 'Connecting',
  });

  final bool connected;
  final bool connecting;
  final VoidCallback? onTap;
  final double size;
  final String connectLabel;
  final String disconnectLabel;
  final String connectingLabel;

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
      duration: const Duration(milliseconds: 2000),
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
    final radius = widget.size * 0.28;

    return Semantics(
      button: true,
      label: widget.connecting
          ? widget.connectingLabel
          : widget.connected
              ? widget.disconnectLabel
              : widget.connectLabel,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) {
          final t = reduce ? 0.45 : _pulse.value;
          return Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              boxShadow: [
                BoxShadow(
                  color: ShahkarTheme.accent.withValues(alpha: 0.45 + t * 0.2),
                  blurRadius: 32 + t * 12,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: ShahkarTheme.protectedTeal.withValues(alpha: 0.18),
                  blurRadius: 40,
                  offset: const Offset(0, 18),
                ),
              ],
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFB4A7FF),
                  Color(0xFF7B6CFF),
                  Color(0xFF5A48E8),
                  Color(0xFF3D2FC4),
                ],
                stops: [0.0, 0.35, 0.7, 1.0],
              ),
            ),
            child: child,
          );
        },
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(radius),
            child: Center(
              child: widget.connecting
                  ? const SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.6,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      Icons.power_settings_new_rounded,
                      size: widget.size * 0.42,
                      color: Colors.white,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
