import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shahkar_connect/features/auth/data/auth_repository.dart';
import 'package:shahkar_connect/features/auth/presentation/login_page.dart';
import 'package:shahkar_connect/features/connect/engine/vpn_engine.dart';
import 'package:shahkar_connect/features/connect/presentation/session_controller.dart';
import 'package:shahkar_connect/features/plans/presentation/plans_page.dart';
import 'package:shahkar_connect/features/settings/settings_page.dart';

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
    final connecting = session.busy ||
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
                _ConnectButton(
                  connected: connected,
                  connecting: connecting,
                  onTap: connecting
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
                      ? 'در حال بهینه‌سازی اتصال...'
                      : connected
                          ? 'متصل'
                          : 'قطع',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (session.selected != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      session.selected!.name,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
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
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () async {
                    await context.read<AuthRepository>().logout();
                    if (!context.mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute<void>(builder: (_) => const LoginPage()),
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

class _ConnectButton extends StatelessWidget {
  const _ConnectButton({
    required this.connected,
    required this.connecting,
    required this.onTap,
  });

  final bool connected;
  final bool connecting;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = connected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.outline;
    return Material(
      color: color.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          height: 180,
          width: 180,
          child: Center(
            child: connecting
                ? const CircularProgressIndicator()
                : Icon(
                    connected ? Icons.power_settings_new : Icons.power_settings_new,
                    size: 64,
                    color: color,
                  ),
          ),
        ),
      ),
    );
  }
}
