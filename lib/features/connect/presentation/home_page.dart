import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:shahkar_connect/core/l10n/locale_controller.dart';
import 'package:shahkar_connect/core/l10n/s.dart';
import 'package:shahkar_connect/features/connect/data/vpn_server.dart';
import 'package:shahkar_connect/features/connect/engine/traffic_rate.dart';
import 'package:shahkar_connect/features/connect/engine/vpn_engine.dart';
import 'package:shahkar_connect/features/connect/guard/connection_guard.dart';
import 'package:shahkar_connect/features/connect/presentation/server_list_page.dart';
import 'package:shahkar_connect/features/connect/presentation/session_controller.dart';
import 'package:shahkar_connect/features/connect/presentation/widgets/guard_widgets.dart';
import 'package:shahkar_connect/features/connect/security/kill_switch.dart';
import 'package:shahkar_connect/features/connect/security/leak_sentinel.dart';
import 'package:shahkar_connect/features/plans/presentation/plans_page.dart';
import 'package:shahkar_connect/theme.dart';
import 'package:shahkar_connect/ui/vpnai_logo.dart';
import 'package:shahkar_connect/ui/vpnai_wordmark.dart';

/// Palette sampled from the reference design.
abstract final class VpnGlass {
  static const dark = Color(0xFF07080A);
  static const panel = Color(0xFF0E1013);
  static const stroke = Color(0xFF23272C);

  static const teal = Color(0xFF17B290);
  static const tealGlow = Color(0xFF12E3B0);
  static const tealDeep = Color(0xFF0D4A40);

  static const indigo = Color(0xFF6C63FF);
  static const indigoDeep = Color(0xFF4B44D6);
  static const navActive = Color(0xFF5B63F0);
  static const navIdle = Color(0xFF8A8C90);

  static const up = Color(0xFFE4556E);
  static const down = Color(0xFF2FD8A8);
}

enum _UiConnectState { idle, selecting, connected }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  _UiConnectState _uiState = _UiConnectState.idle;
  int _selectedIndex = 0;

  late final AnimationController _powerPulseController;
  late final AnimationController _powerScaleController;

  Timer? _cycleTimer;
  int _cycleTick = 0;

  @override
  void initState() {
    super.initState();
    _powerPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _powerScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      lowerBound: 0.9,
      upperBound: 1.0,
      value: 1.0,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = context.read<SessionController>();
      session.refreshEntitlement();
      _syncIndexFromSession(session);
    });
  }

  @override
  void dispose() {
    _cycleTimer?.cancel();
    _powerPulseController.dispose();
    _powerScaleController.dispose();
    super.dispose();
  }

  void _syncIndexFromSession(SessionController session) {
    final countries = session.countryServers;
    if (countries.isEmpty) return;
    final id = session.selectedServer?.id;
    final i = countries.indexWhere((s) => s.id == id);
    final gb = countries.indexWhere((s) => s.regionCode == 'GB');
    setState(() {
      _selectedIndex = i >= 0 ? i : (gb >= 0 ? gb : 0);
      if (session.isConnected) _uiState = _UiConnectState.connected;
    });
  }

  String _speedLabel(double bps) {
    if (bps <= 0) return '0 mb';
    final mb = bps / (1024 * 1024);
    if (mb >= 1) return '${mb.toStringAsFixed(0)} mb';
    final kb = bps / 1024;
    if (kb >= 1) return '${kb.toStringAsFixed(0)} kb';
    return formatBps(bps).toLowerCase();
  }

  Future<void> _openServers() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ServerListPage()),
    );
    if (!mounted) return;
    _syncIndexFromSession(context.read<SessionController>());
  }

  Future<void> _onPowerTap() async {
    final session = context.read<SessionController>();
    final guard = context.read<ConnectionGuard>();
    final countries = session.countryServers;
    if (countries.isEmpty) return;

    if (_uiState == _UiConnectState.connected || session.isConnected) {
      await guard.userDisconnect();
      if (!mounted) return;
      setState(() => _uiState = _UiConnectState.idle);
      return;
    }
    if (_uiState == _UiConnectState.selecting) return;

    unawaited(
      _powerScaleController.reverse().then((_) => _powerScaleController.forward()),
    );
    await _runSlotSelectThenConnect(session, countries);
  }

  Future<void> _runSlotSelectThenConnect(
    SessionController session,
    List<VpnServer> countries,
  ) async {
    setState(() => _uiState = _UiConnectState.selecting);

    final random = Random();
    final preferred = session.selectedServer;
    var targetIndex = preferred == null
        ? random.nextInt(countries.length)
        : countries.indexWhere((s) => s.id == preferred.id);
    if (targetIndex < 0) targetIndex = random.nextInt(countries.length);

    _cycleTick = 0;
    const totalSteps = 18;
    var delay = 40;
    final done = Completer<void>();

    void tick() {
      if (!mounted) {
        done.complete();
        return;
      }
      _cycleTick++;
      setState(() {
        _selectedIndex = (_selectedIndex + 1) % countries.length;
      });

      if (_cycleTick >= totalSteps) {
        setState(() => _selectedIndex = targetIndex);
        done.complete();
        return;
      }

      delay = (delay * 1.18).round().clamp(40, 260);
      _cycleTimer = Timer(Duration(milliseconds: delay), tick);
    }

    tick();
    await done.future;
    if (!mounted) return;

    await context
        .read<ConnectionGuard>()
        .connectTo(countries[_selectedIndex]);
    if (!mounted) return;

    setState(() {
      _uiState = session.isConnected
          ? _UiConnectState.connected
          : _UiConnectState.idle;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleController>().s;
    final session = context.watch<SessionController>();
    final guard = context.watch<ConnectionGuard>();
    final killSwitch = context.watch<KillSwitchService>();
    final leaks = context.watch<LeakSentinel>();
    final countries = session.countryServers;
    if (countries.isEmpty) {
      return const ColoredBox(
        color: VpnGlass.dark,
        child: Center(
          child: CircularProgressIndicator(color: VpnGlass.teal),
        ),
      );
    }

    final engineConnected =
        session.engineState.kind == ConnectionStateKind.connected;
    final connecting = session.busy ||
        session.engineState.kind == ConnectionStateKind.connecting ||
        _uiState == _UiConnectState.selecting;

    final connected =
        engineConnected || _uiState == _UiConnectState.connected;
    final selecting = _uiState == _UiConnectState.selecting;

    final safeIndex = _selectedIndex.clamp(0, countries.length - 1);
    final selected = countries[safeIndex];

    final down = connected ? _speedLabel(session.rate.downBps) : '0 mb';
    final up = connected ? _speedLabel(session.rate.upBps) : '0 mb';
    final ping = connected
        ? '${selected.latencyMs ?? session.pingMs ?? 80} ms'
        : '-- ms';

    return ColoredBox(
      color: VpnGlass.dark,
      child: LayoutBuilder(
        builder: (context, box) {
          final h = box.maxHeight;
          final powerSize = 82.r;

          return Stack(
            children: [
              Positioned.fill(child: _AuroraBackground(active: connected)),
              Positioned(
                top: h * 0.015,
                left: 18.w,
                right: 18.w,
                child: _TopBar(
                  premiumLabel: s.premium,
                  onPremium: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const PlansPage(),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                top: h * 0.175,
                left: 0,
                right: 0,
                child: Center(
                  child: _StatusPill(
                    connected: connected && !selecting,
                    selecting: selecting || connecting && !connected,
                    protectedLabel: s.protectedStatus,
                    unprotectedLabel: s.unprotectedStatus,
                    selectingLabel: s.connecting,
                  ),
                ),
              ),
              Positioned(
                top: h * 0.265,
                left: 0,
                right: 0,
                child: _StatsRow(download: down, upload: up, ping: ping),
              ),
              if (connected || guard.scanning)
                Positioned(
                  top: h * 0.40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: QualityChip(
                      quality: guard.quality,
                      scanning: guard.scanning,
                      s: s,
                    ),
                  ),
                ),
              Positioned(
                top: h * 0.55 - powerSize / 2,
                left: 0,
                right: 0,
                child: Center(
                  child: _PowerButton(
                    size: powerSize,
                    connected: connected,
                    selecting: selecting || connecting,
                    pulseController: _powerPulseController,
                    scaleController: _powerScaleController,
                    onTap: connecting && !connected && !selecting
                        ? null
                        : _onPowerTap,
                  ),
                ),
              ),
              Positioned(
                top: h * 0.74,
                left: 0,
                right: 0,
                child: _LocationStrip(
                  servers: countries,
                  selectedIndex: safeIndex,
                  onTap: selecting
                      ? null
                      : (i) {
                          setState(() => _selectedIndex = i);
                          session.selectServer(countries[i]);
                        },
                ),
              ),
              Positioned(
                top: h * 0.885,
                left: 0,
                right: 0,
                child: Center(
                  child: _LocationDropdownChip(
                    name: selected.name,
                    flagAsset: selected.flagAsset,
                    flagEmoji: selected.flag,
                    onTap: selecting ? null : _openServers,
                  ),
                ),
              ),
              if (session.error != null && !killSwitch.engaged)
                Positioned(
                  bottom: 4.h,
                  left: 24.w,
                  right: 24.w,
                  child: Text(
                    session.error!,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: ShahkarTheme.danger,
                    ),
                  ),
                ),
              if (killSwitch.engaged)
                Positioned(
                  top: h * 0.10,
                  left: 12.w,
                  right: 12.w,
                  child: LockdownCard(
                    s: s,
                    reconnecting: guard.notice == GuardNotice.reconnecting,
                    onUnlock: () => guard.userDisconnect(),
                  ),
                )
              else if (leaks.leaking && connected)
                Positioned(
                  top: h * 0.10,
                  left: 12.w,
                  right: 12.w,
                  child: GuardNoticeBar(
                    text: s.leakDetected,
                    tone: ShahkarTheme.danger,
                    onClose: () {},
                  ),
                ),
              if (guard.suggestion != null)
                Positioned(
                  bottom: 8.h,
                  left: 12.w,
                  right: 12.w,
                  child: SwitchSuggestionCard(
                    suggestion: guard.suggestion!,
                    s: s,
                    onAccept: () => guard.applySuggestion(),
                    onDismiss: guard.dismissSuggestion,
                  ),
                ),
              if (guard.suggestion == null && guard.notice != null)
                Positioned(
                  bottom: 8.h,
                  left: 12.w,
                  right: 12.w,
                  child: GuardNoticeBar(
                    text: _noticeText(s, guard),
                    onClose: guard.clearNotice,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

String _noticeText(S s, ConnectionGuard guard) {
  switch (guard.notice) {
    case GuardNotice.switched:
      return s.switchedToBody(guard.noticeDetail ?? '');
    case GuardNotice.reconnected:
      return s.reconnected;
    case GuardNotice.reconnecting:
      return s.reconnecting;
    case GuardNotice.internetDown:
      return s.internetDown;
    case GuardNotice.locked:
      return s.internetLocked;
    case null:
      return '';
  }
}

/// Dark canvas with a teal aurora that ends in a soft wave.
class _AuroraBackground extends StatelessWidget {
  const _AuroraBackground({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipPath(
          clipper: _WaveClipper(),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Vertical wash: near-black at the top, teal near the wave.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: active
                        ? const [
                            Color(0xFF16201E),
                            Color(0xFF124036),
                            Color(0xFF166A58),
                          ]
                        : const [
                            Color(0xFF131A19),
                            Color(0xFF11362F),
                            Color(0xFF14584B),
                          ],
                    stops: const [0.0, 0.42, 0.66],
                  ),
                ),
              ),
              CustomPaint(painter: _GridPainter()),
              Align(
                alignment: const Alignment(0, -0.12),
                child: Opacity(
                  opacity: active ? 0.55 : 0.42,
                  child: Image.asset(
                    'assets/brand/world-map-fine.png',
                    width: 420.w,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
              // Bloom centred on the connect button.
              Align(
                alignment: const Alignment(0, 0.24),
                child: FractionallySizedBox(
                  widthFactor: 0.95,
                  heightFactor: 0.5,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          VpnGlass.tealGlow
                              .withValues(alpha: active ? 0.26 : 0.20),
                          VpnGlass.tealGlow.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Glowing rim along the wave.
        CustomPaint(painter: _WaveRimPainter(active: active)),
      ],
    );
  }
}

/// Smooth wave that crests slightly in the middle.
Path _wavePath(Size size) {
  final w = size.width;
  final side = size.height * _sideEdge;
  final center = size.height * _centerEdge;
  return Path()
    ..moveTo(0, 0)
    ..lineTo(w, 0)
    ..lineTo(w, side)
    ..cubicTo(w * 0.80, side, w * 0.74, center, w * 0.5, center)
    ..cubicTo(w * 0.26, center, w * 0.20, side, 0, side)
    ..close();
}

/// Sides of the wave sit higher, the middle dips below the connect button.
const _sideEdge = 0.635;
const _centerEdge = 0.70;

/// Just the curved edge, used for the glowing rim.
Path _waveEdgePath(Size size) {
  final w = size.width;
  final side = size.height * _sideEdge;
  final center = size.height * _centerEdge;
  return Path()
    ..moveTo(w, side)
    ..cubicTo(w * 0.80, side, w * 0.74, center, w * 0.5, center)
    ..cubicTo(w * 0.26, center, w * 0.20, side, 0, side);
}

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => _wavePath(size);

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _WaveRimPainter extends CustomPainter {
  _WaveRimPainter({required this.active});

  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _waveEdgePath(size);
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = VpnGlass.tealGlow.withValues(alpha: active ? 0.60 : 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = VpnGlass.tealGlow.withValues(alpha: active ? 0.55 : 0.38);
    canvas.drawPath(path, glow);
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant _WaveRimPainter oldDelegate) =>
      oldDelegate.active != active;
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.025)
      ..strokeWidth = 0.6;
    const step = 26.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => false;
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.premiumLabel, required this.onPremium});

  final String premiumLabel;
  final VoidCallback onPremium;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        VpnaiLogo(size: 26.r),
        SizedBox(width: 9.w),
        VpnaiWordmark(fontSize: 17.sp),
        const Spacer(),
        GestureDetector(
          onTap: onPremium,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 7.h),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF8B83FF), VpnGlass.indigoDeep],
              ),
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: VpnGlass.indigo.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                  size: 15.sp,
                ),
                SizedBox(width: 6.w),
                Text(
                  premiumLabel,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.connected,
    required this.selecting,
    required this.protectedLabel,
    required this.unprotectedLabel,
    required this.selectingLabel,
  });

  final bool connected;
  final bool selecting;
  final String protectedLabel;
  final String unprotectedLabel;
  final String selectingLabel;

  @override
  Widget build(BuildContext context) {
    final text = selecting
        ? selectingLabel
        : connected
            ? protectedLabel
            : unprotectedLabel;

    final Color fill;
    final Color content;
    if (selecting) {
      fill = const Color(0xFFF5A623).withValues(alpha: 0.16);
      content = const Color(0xFFF7C271);
    } else if (connected) {
      fill = VpnGlass.teal;
      content = Colors.white;
    } else {
      fill = Colors.white.withValues(alpha: 0.06);
      content = Colors.white54;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(20.r),
        border: connected
            ? null
            : Border.all(color: Colors.white.withValues(alpha: 0.10)),
        boxShadow: connected
            ? [
                BoxShadow(
                  color: VpnGlass.teal.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.gpp_good_rounded, size: 15.sp, color: content),
          SizedBox(width: 6.w),
          Text(
            text,
            style: TextStyle(
              color: content,
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.download,
    required this.upload,
    required this.ping,
  });

  final String download;
  final String upload;
  final String ping;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _StatItem(
          icon: Icons.arrow_downward_rounded,
          color: VpnGlass.down,
          value: download,
        ),
        SizedBox(width: 40.w),
        _StatItem(
          icon: Icons.arrow_upward_rounded,
          color: VpnGlass.up,
          value: upload,
        ),
        SizedBox(width: 40.w),
        _StatItem(
          icon: Icons.bar_chart_rounded,
          color: VpnGlass.indigo,
          value: ping,
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.color,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 17.sp),
        SizedBox(height: 6.h),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

/// Squircle connect button with a soft indigo bloom.
class _PowerButton extends StatelessWidget {
  const _PowerButton({
    required this.size,
    required this.connected,
    required this.selecting,
    required this.pulseController,
    required this.scaleController,
    required this.onTap,
  });

  final double size;
  final bool connected;
  final bool selecting;
  final AnimationController pulseController;
  final AnimationController scaleController;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final glow = connected ? VpnGlass.tealGlow : VpnGlass.indigo;
    final radius = BorderRadius.circular(size * 0.32);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([pulseController, scaleController]),
        builder: (context, child) {
          final pulse = 0.55 + pulseController.value * 0.45;
          return Transform.scale(
            scale: scaleController.value,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                borderRadius: radius,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: connected
                      ? const [Color(0xFF2FE0B4), Color(0xFF12A184)]
                      : const [Color(0xFF8B83FF), VpnGlass.indigoDeep],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: glow.withValues(alpha: 0.45 * pulse),
                    blurRadius: 44,
                    spreadRadius: 6,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: selecting
                  ? Padding(
                      padding: EdgeInsets.all(size * 0.30),
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.6,
                      ),
                    )
                  : Icon(
                      Icons.power_settings_new_rounded,
                      color: Colors.white,
                      size: size * 0.42,
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _LocationStrip extends StatefulWidget {
  const _LocationStrip({
    required this.servers,
    required this.selectedIndex,
    required this.onTap,
  });

  final List<VpnServer> servers;
  final int selectedIndex;
  final ValueChanged<int>? onTap;

  @override
  State<_LocationStrip> createState() => _LocationStripState();
}

class _LocationStripState extends State<_LocationStrip> {
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _centerSelected(false));
  }

  @override
  void didUpdateWidget(_LocationStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _centerSelected(true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Keeps the active flag under the centre of the strip.
  void _centerSelected(bool animate) {
    if (!_controller.hasClients) return;
    final small = 36.r;
    final large = 50.r;
    final gap = 10.w;
    final before = widget.selectedIndex * (small + gap);
    final target = 14.w + before + large / 2 - _controller.position.viewportDimension / 2;
    final clamped = target.clamp(0.0, _controller.position.maxScrollExtent);
    if (animate) {
      _controller.animateTo(
        clamped,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    } else {
      _controller.jumpTo(clamped);
    }
  }

  @override
  Widget build(BuildContext context) {
    final servers = widget.servers;
    final onTap = widget.onTap;

    return SizedBox(
      height: 58.h,
      child: ListView.separated(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 14.w),
        itemCount: servers.length,
        separatorBuilder: (_, __) => SizedBox(width: 10.w),
        itemBuilder: (context, index) {
          final isSelected = index == widget.selectedIndex;
          final server = servers[index];
          final diameter = isSelected ? 50.r : 36.r;

          return Center(
            child: GestureDetector(
              onTap: onTap == null ? null : () => onTap(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                width: diameter,
                height: diameter,
                padding: EdgeInsets.all(isSelected ? 2.5 : 0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? const Color(0xFF0B0D10) : null,
                  border: Border.all(
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.12),
                    width: isSelected ? 1.6 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.6),
                            blurRadius: 12,
                          ),
                        ]
                      : null,
                ),
                child: Opacity(
                  opacity: isSelected ? 1 : 0.55,
                  child: ClipOval(
                    child: server.flagAsset != null
                        ? Image.asset(
                            server.flagAsset!,
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.high,
                          )
                        : ColoredBox(
                            color: const Color(0xFF15181C),
                            child: Center(
                              child: Text(
                                server.flag,
                                style: TextStyle(
                                  fontSize: isSelected ? 22.sp : 16.sp,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LocationDropdownChip extends StatelessWidget {
  const _LocationDropdownChip({
    required this.name,
    required this.flagEmoji,
    this.flagAsset,
    this.onTap,
  });

  final String name;
  final String flagEmoji;
  final String? flagAsset;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: VpnGlass.panel,
          borderRadius: BorderRadius.circular(22.r),
          border: Border.all(color: VpnGlass.stroke),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (flagAsset != null)
              ClipOval(
                child: Image.asset(
                  flagAsset!,
                  width: 18.r,
                  height: 18.r,
                  fit: BoxFit.cover,
                ),
              )
            else
              Text(flagEmoji, style: TextStyle(fontSize: 15.sp)),
            SizedBox(width: 8.w),
            Text(
              name,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 4.w),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.white60,
              size: 17.sp,
            ),
          ],
        ),
      ),
    );
  }
}
