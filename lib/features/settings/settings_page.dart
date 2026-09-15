import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shahkar_connect/core/api/api_client.dart';
import 'package:shahkar_connect/core/api/models.dart';
import 'package:shahkar_connect/features/legal/privacy_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('تنظیمات')),
        body: ListView(
          children: [
            const ListTile(
              title: Text('تم'),
              subtitle: Text('پیروی از تنظیمات سیستم (روشن / تیره)'),
            ),
            ListTile(
              title: const Text('اتصال تلگرام'),
              subtitle: const Text('یک کد بگیرید و در ربات بفرستید: /app کد'),
              onTap: () => _linkTelegram(context),
            ),
            ListTile(
              title: const Text('حریم خصوصی'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const PrivacyPage()),
                );
              },
            ),
            const ListTile(
              title: Text('پشتیبانی'),
              subtitle: Text('از داخل حساب پنل با پشتیبانی در تماس باشید.'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _linkTelegram(BuildContext context) async {
  final api = context.read<ApiClient>();
  try {
    final res = await api.dio.post('/api/v1/auth/telegram-link-code');
    final code = TelegramLinkCode.fromJson(res.data as Map<String, dynamic>);
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('کد اتصال تلگرام'),
            content: Text('${code.botCommand} ${code.code}'),
            actions: [
              TextButton(
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: '${code.botCommand} ${code.code}'),
                  );
                  Navigator.pop(ctx);
                },
                child: const Text('کپی'),
              ),
            ],
          ),
    );
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('کد تلگرام ساخته نشد. بعداً تلاش کنید.')),
    );
  }
}
