import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shahkar_connect/core/l10n/locale_controller.dart';
import 'package:shahkar_connect/ui/app_chrome.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleController>().s;
    return AppScaffold(
      showBack: true,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          s.privacyBody,
          style: const TextStyle(fontSize: 13, height: 1.5),
        ),
      ),
    );
  }
}
