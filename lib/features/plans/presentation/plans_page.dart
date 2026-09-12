import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shahkar_connect/core/api/api_client.dart';
import 'package:shahkar_connect/core/api/models.dart';

class PlansPage extends StatefulWidget {
  const PlansPage({super.key});

  @override
  State<PlansPage> createState() => _PlansPageState();
}

class _PlansPageState extends State<PlansPage> {
  late Future<List<PlanOffer>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<PlanOffer>> _load() async {
    final api = context.read<ApiClient>();
    final res = await api.dio.get('/api/v1/plans');
    final list = (res.data as List<dynamic>).cast<Map<String, dynamic>>();
    return list.map(PlanOffer.fromJson).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('پلن‌ها')),
        body: FutureBuilder<List<PlanOffer>>(
          future: _future,
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final plans = snap.data!;
            if (plans.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'حساب کاربری شما پلن فعال ندارد. برای فعال‌سازی به پشتیبانی مراجعه کنید.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: plans.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final p = plans[i];
                return Card(
                  child: ListTile(
                    title: Text(p.name),
                    subtitle: Text(
                      [
                        if (p.durationDays != null) '${p.durationDays} روز',
                        if (p.trafficGb != null) '${p.trafficGb} GB',
                      ].join(' · '),
                    ),
                    trailing: const Icon(Icons.lock_outline),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
