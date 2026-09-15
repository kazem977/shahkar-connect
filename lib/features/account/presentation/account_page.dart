import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shahkar_connect/core/api/api_client.dart';
import 'package:shahkar_connect/core/api/models.dart';
import 'package:shahkar_connect/core/l10n/locale_controller.dart';
import 'package:shahkar_connect/features/auth/data/auth_repository.dart';
import 'package:shahkar_connect/features/auth/presentation/login_page.dart';
import 'package:shahkar_connect/features/connect/guard/connection_guard.dart';
import 'package:shahkar_connect/features/connect/presentation/session_controller.dart';
import 'package:shahkar_connect/features/legal/privacy_page.dart';
import 'package:shahkar_connect/features/plans/presentation/plans_page.dart';
import 'package:shahkar_connect/theme.dart';
import 'package:shahkar_connect/ui/settings_tiles.dart';
import 'package:shahkar_connect/ui/vpnai_logo.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleController>().s;
    final session = context.watch<SessionController>();
    final guard = context.read<ConnectionGuard>();
    final entitlement = session.entitlement;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
      children: [
        const SizedBox(height: 4),
        const Center(child: VpnaiLogo(size: 60)),
        const SizedBox(height: 12),
        Text(
          entitlement?.username.isNotEmpty == true
              ? entitlement!.username
              : s.account,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: ShahkarTheme.fog,
          ),
        ),
        if (entitlement?.expiresAt != null) ...[
          const SizedBox(height: 5),
          Text(
            '${s.expires}: ${entitlement!.expiresAt}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11.5, color: ShahkarTheme.mute),
          ),
        ],
        const SizedBox(height: 18),

        SettingsSectionHeader(s.accountSection),
        SettingsCard(
          child: Column(
            children: [
              _Row(
                label: s.planActive,
                value: entitlement?.canConnect == true ? '✓' : '—',
                highlight: entitlement?.canConnect == true,
              ),
              const SizedBox(height: 8),
              _Row(
                label: s.remaining,
                value: entitlement?.trafficRemainingBytes != null
                    ? _fmtBytes(entitlement!.trafficRemainingBytes!)
                    : '—',
              ),
            ],
          ),
        ),
        SettingsNavTile(
          icon: Icons.workspace_premium_outlined,
          title: s.plans,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const PlansPage()),
          ),
        ),
        SettingsNavTile(
          icon: Icons.send_outlined,
          title: s.telegram,
          onTap: () => _linkTelegram(context),
        ),
        SettingsNavTile(
          icon: Icons.privacy_tip_outlined,
          title: s.privacy,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const PrivacyPage()),
          ),
        ),
        SettingsNavTile(
          icon: Icons.logout_rounded,
          title: s.logout,
          danger: true,
          onTap: () async {
            await guard.userDisconnect();
            if (!context.mounted) return;
            await context.read<AuthRepository>().logout();
            if (!context.mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute<void>(builder: (_) => const LoginPage()),
              (_) => false,
            );
          },
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(color: ShahkarTheme.mute, fontSize: 12),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
            color: highlight ? ShahkarTheme.connected : ShahkarTheme.fog,
          ),
        ),
      ],
    );
  }
}

Future<void> _linkTelegram(BuildContext context) async {
  final api = context.read<ApiClient>();
  final s = context.read<LocaleController>().s;
  try {
    final res = await api.dio.post('/api/v1/auth/telegram-link-code');
    final code = TelegramLinkCode.fromJson(res.data as Map<String, dynamic>);
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.telegramTitle),
        content: Text('${code.botCommand} ${code.code}'),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(
                ClipboardData(text: '${code.botCommand} ${code.code}'),
              );
              Navigator.pop(ctx);
            },
            child: Text(s.copy),
          ),
        ],
      ),
    );
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.telegramFail)),
    );
  }
}

String _fmtBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}
