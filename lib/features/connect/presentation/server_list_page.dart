import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shahkar_connect/core/l10n/locale_controller.dart';
import 'package:shahkar_connect/features/connect/data/vpn_server.dart';
import 'package:shahkar_connect/features/connect/presentation/session_controller.dart';
import 'package:shahkar_connect/theme.dart';
import 'package:shahkar_connect/ui/app_chrome.dart';

class ServerListPage extends StatefulWidget {
  const ServerListPage({super.key});

  @override
  State<ServerListPage> createState() => _ServerListPageState();
}

class _ServerListPageState extends State<ServerListPage> {
  final _query = TextEditingController();
  bool _streamGameOnly = false;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleController>().s;
    final session = context.watch<SessionController>();
    final q = _query.text.trim().toLowerCase();

    bool matches(VpnServer server) {
      if (q.isEmpty) return true;
      return server.name.toLowerCase().contains(q) ||
          server.location.toLowerCase().contains(q) ||
          server.regionCode.toLowerCase().contains(q);
    }

    final all = session.servers.where(matches).toList();
    final countries = all
        .where((e) => e.category == ServerCategory.country)
        .toList();
    final streams =
        all.where((e) => e.category == ServerCategory.stream).toList();
    final games = all.where((e) => e.category == ServerCategory.game).toList();

    return AppScaffold(
      showBack: true,
      showBrand: false,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              s.serverList,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: ShahkarTheme.fog,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _query,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontSize: 13, color: ShahkarTheme.fog),
              decoration: InputDecoration(
                hintText: s.searchServers,
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: ShahkarTheme.mute,
                  size: 20,
                ),
                filled: true,
                fillColor: ShahkarTheme.surfaceElevated,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: ShahkarTheme.accent.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _FilterToggle(
              allLabel: s.allServers,
              streamGameLabel: s.streamAndGame,
              streamGameOnly: _streamGameOnly,
              onChanged: (v) => setState(() => _streamGameOnly = v),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  if (!_streamGameOnly && countries.isNotEmpty) ...[
                    _SectionLabel(s.allServers.toUpperCase()),
                    ...countries.map(
                      (server) => _ServerTile(
                        server: server,
                        selected: session.selectedServer?.id == server.id,
                        onTap: () {
                          session.selectServer(server);
                          Navigator.of(context).pop();
                        },
                        onFavorite: () => session.toggleFavorite(server.id),
                      ),
                    ),
                  ],
                  if (streams.isNotEmpty) ...[
                    _SectionLabel(s.streamSection),
                    ...streams.map(
                      (server) => _ServerTile(
                        server: server,
                        selected: session.selectedServer?.id == server.id,
                        onTap: () {
                          session.selectServer(server);
                          Navigator.of(context).pop();
                        },
                        onFavorite: () => session.toggleFavorite(server.id),
                      ),
                    ),
                  ],
                  if (games.isNotEmpty) ...[
                    _SectionLabel(s.gameSection),
                    ...games.map(
                      (server) => _ServerTile(
                        server: server,
                        selected: session.selectedServer?.id == server.id,
                        onTap: () {
                          session.selectServer(server);
                          Navigator.of(context).pop();
                        },
                        onFavorite: () => session.toggleFavorite(server.id),
                      ),
                    ),
                  ],
                  if (_streamGameOnly && streams.isEmpty && games.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Text(
                        s.noServer,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: ShahkarTheme.mute),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterToggle extends StatelessWidget {
  const _FilterToggle({
    required this.allLabel,
    required this.streamGameLabel,
    required this.streamGameOnly,
    required this.onChanged,
  });

  final String allLabel;
  final String streamGameLabel;
  final bool streamGameOnly;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: ShahkarTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Seg(
              label: allLabel,
              selected: !streamGameOnly,
              onTap: () => onChanged(false),
            ),
          ),
          Expanded(
            child: _Seg(
              label: streamGameLabel,
              selected: streamGameOnly,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _Seg extends StatelessWidget {
  const _Seg({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? ShahkarTheme.accent : Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : ShahkarTheme.mute,
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: ShahkarTheme.mute,
        ),
      ),
    );
  }
}

class _ServerTile extends StatelessWidget {
  const _ServerTile({
    required this.server,
    required this.selected,
    required this.onTap,
    required this.onFavorite,
  });

  final VpnServer server;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    final latency = server.latencyMs;
    final bars = latency == null
        ? 2
        : latency < 70
            ? 4
            : latency < 100
                ? 3
                : 2;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? ShahkarTheme.accent.withValues(alpha: 0.12)
            : ShahkarTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                _LeadingIcon(server: server),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        server.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: ShahkarTheme.fog,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        server.location,
                        style: const TextStyle(
                          fontSize: 11,
                          color: ShahkarTheme.mute,
                        ),
                      ),
                    ],
                  ),
                ),
                if (latency != null)
                  Text(
                    '${latency}ms',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: ShahkarTheme.mute,
                    ),
                  ),
                const SizedBox(width: 8),
                _SignalBars(level: bars),
                const SizedBox(width: 6),
                if (server.premium)
                  const Icon(
                    Icons.lock_rounded,
                    size: 16,
                    color: ShahkarTheme.mute,
                  )
                else
                  IconButton(
                    onPressed: onFavorite,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                    icon: Icon(
                      server.favorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 18,
                      color: server.favorite
                          ? ShahkarTheme.accent
                          : ShahkarTheme.mute,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LeadingIcon extends StatelessWidget {
  const _LeadingIcon({required this.server});
  final VpnServer server;

  @override
  Widget build(BuildContext context) {
    if (server.category == ServerCategory.country) {
      return Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: ShahkarTheme.surface,
          shape: BoxShape.circle,
        ),
        child: Text(server.flag, style: const TextStyle(fontSize: 20)),
      );
    }
    final icon = server.category == ServerCategory.game
        ? Icons.sports_esports_rounded
        : Icons.play_circle_fill_rounded;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: ShahkarTheme.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: ShahkarTheme.accent, size: 22),
    );
  }
}

class _SignalBars extends StatelessWidget {
  const _SignalBars({required this.level});
  final int level;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(4, (i) {
        final on = i < level;
        return Container(
          margin: const EdgeInsets.only(left: 1.5),
          width: 3,
          height: 4.0 + i * 2.5,
          decoration: BoxDecoration(
            color: on ? ShahkarTheme.connected : ShahkarTheme.line,
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }
}
