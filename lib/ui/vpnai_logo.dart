import 'package:flutter/material.dart';

/// Shared vpnai brand mark used in chrome, auth, and elsewhere.
class VpnaiLogo extends StatelessWidget {
  const VpnaiLogo({
    super.key,
    this.size = 28,
    this.radius,
  });

  final double size;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final r = radius ?? size / 2;
    return ClipRRect(
      borderRadius: BorderRadius.circular(r),
      child: Image.asset(
        'assets/brand/vpnai-mark.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        gaplessPlayback: true,
      ),
    );
  }
}
