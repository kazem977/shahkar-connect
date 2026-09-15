import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shahkar_connect/core/api/api_client.dart';
import 'package:shahkar_connect/core/api/api_errors.dart';
import 'package:shahkar_connect/core/api/models.dart';
import 'package:shahkar_connect/core/l10n/locale_controller.dart';
import 'package:shahkar_connect/features/connect/presentation/session_controller.dart';
import 'package:shahkar_connect/features/iap/iap_service.dart';
import 'package:shahkar_connect/theme.dart';
import 'package:shahkar_connect/ui/app_chrome.dart';

class PlansPage extends StatefulWidget {
  const PlansPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<PlansPage> createState() => _PlansPageState();
}

class _PlansPageState extends State<PlansPage> {
  late Future<List<PlanOffer>> _future;
  bool _buying = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<PlanOffer>> _load() async {
    final api = context.read<ApiClient>();
    final res = await api.dio.get('/api/v1/plans');
    return parsePlanOffers(res.data);
  }

  Future<void> _buy(PlanOffer plan) async {
    final iap = context.read<IapService>();
    final s = context.read<LocaleController>().s;
    setState(() => _buying = true);
    try {
      final entitlement = await iap.buy(plan);
      if (!mounted) return;
      context.read<SessionController>().applyEntitlement(entitlement);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.planActive)),
      );
      if (!widget.embedded) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(iap.describeError(e))),
      );
    } finally {
      if (mounted) setState(() => _buying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleController>().s;
    final body = FutureBuilder<List<PlanOffer>>(
      future: _future,
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    describeApiError(snap.error!, s: s),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => setState(() => _future = _load()),
                    child: Text(s.retry),
                  ),
                ],
              ),
            ),
          );
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final plans = snap.data!;
        if (plans.isEmpty) {
          return Center(
            child: Text(s.noPlans, style: const TextStyle(fontSize: 13)),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: plans.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final p = plans[i];
            return Material(
              color: ShahkarTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
              child: ListTile(
                dense: true,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                title: Text(p.name),
                subtitle: Text(
                  [
                    if (p.durationDays != null) '${p.durationDays}d',
                    if (p.trafficGb != null) '${p.trafficGb} GB',
                  ].join(' · '),
                ),
                trailing: TextButton(
                  onPressed: _buying ? null : () => _buy(p),
                  child: Text(s.buy),
                ),
              ),
            );
          },
        );
      },
    );

    if (widget.embedded) return body;
    return AppScaffold(showBack: true, body: body);
  }
}
