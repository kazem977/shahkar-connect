import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shahkar_connect/features/auth/data/auth_repository.dart';
import 'package:shahkar_connect/features/auth/presentation/login_page.dart';
import 'package:shahkar_connect/features/connect/engine/traffic_rate.dart';
import 'package:shahkar_connect/features/connect/engine/vpn_engine.dart';
import 'package:shahkar_connect/features/connect/presentation/connect_orb.dart';
import 'package:shahkar_connect/features/connect/presentation/session_controller.dart';
import 'package:shahkar_connect/features/plans/presentation/plans_page.dart';
import 'package:shahkar_connect/features/settings/settings_page.dart';
import 'package:shahkar_connect/theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SessionController>().refreshEntitlement();
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final connected = session.engineState.kind == ConnectionStateKind.connected;
    final connecting =
        session.busy ||
        session.engineState.kind == ConnectionStateKind.connecting ||
        session.engineState.kind == ConnectionStateKind.optimizing;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('شاهکار'),
          actions: [
            IconButton(
              tooltip: 'پلن‌ها',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const PlansPage()),
                );
              },
              icon: const Icon(Icons.workspace_premium_outlined),
            ),
            IconButton(
              tooltip: 'تنظیمات',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
                );
              },
              icon: const Icon(Icons.settings_outlined),
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                ConnectOrb(
                  connected: connected,
                  connecting: connecting,
                  onTap:
                      connecting
                          ? null
                          : () {
                            if (connected) {
                              session.disconnect();
                            } else {
                              session.connect();
                            }
                          },
                ),
                const SizedBox(height: 24),
                Text(
                  connecting
                      ? (session.engineState.kind ==
                              ConnectionStateKind.optimizing
                          ? 'جابه‌جایی سرور...'
                          : 'در حال بهینه‌سازی اتصال...')
                      : connected
                      ? 'متصل'
                      : 'قطع',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (session.selected != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      [
                        session.selected!.name,
                        if (session.selected!.region != null)
                          session.selected!.region!,
                      ].join(' · '),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                if (connected) ...[
                  const SizedBox(height: 20),
                  _SpeedRow(
                    up: formatBps(session.rate.upBps),
                    down: formatBps(session.rate.downBps),
                  ),
                ],
                if (session.entitlement?.canConnect == false)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Text(
                      'حساب کاربری شما پلن فعال ندارد. برای فعال‌سازی به پشتیبانی مراجعه کنید.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (session.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      session.error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () async {
                    await context.read<AuthRepository>().logout();
                    if (!context.mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute<void>(
                        builder: (_) => const LoginPage(),
                      ),
                      (_) => false,
                    );
                  },
                  child: const Text('خروج'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SpeedRow extends StatelessWidget {
  const _SpeedRow({required this.up, required this.down});

  final String up;
  final String down;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.7);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SpeedChip(label: 'آپلود', value: up, color: muted),
        const SizedBox(width: 16),
        _SpeedChip(label: 'دانلود', value: down, color: ShahkarTheme.connected),
      ],
    );
  }
}

class _SpeedChip extends StatelessWidget {
  const _SpeedChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: color),
        ),
      ],
    );
  }
}
