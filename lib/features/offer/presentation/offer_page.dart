import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shahkar_connect/core/l10n/locale_controller.dart';
import 'package:shahkar_connect/features/plans/presentation/plans_page.dart';
import 'package:shahkar_connect/theme.dart';

/// Offer & Update tab — surfaces plans inside the main shell.
class OfferPage extends StatelessWidget {
  const OfferPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleController>().s;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 4),
          child: Text(
            s.offer,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: ShahkarTheme.fog,
            ),
          ),
        ),
        const Expanded(child: PlansPage(embedded: true)),
      ],
    );
  }
}
