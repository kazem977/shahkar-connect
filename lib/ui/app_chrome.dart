import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shahkar_connect/core/desktop/window.dart';
import 'package:shahkar_connect/core/l10n/locale_controller.dart';
import 'package:shahkar_connect/core/l10n/s.dart';
import 'package:shahkar_connect/theme.dart';
import 'package:shahkar_connect/ui/vpnai_logo.dart';
import 'package:shahkar_connect/ui/vpnai_wordmark.dart';
import 'package:window_manager/window_manager.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.body,
    this.showBack = false,
    this.showBrand = true,
    this.resizeToAvoidBottomInset = true,
    this.backgroundColor,
  });

  final Widget body;
  final bool showBack;
  final bool showBrand;
  final bool resizeToAvoidBottomInset;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocaleController>();
    return Directionality(
      textDirection: loc.s.rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: backgroundColor ?? ShahkarTheme.ink,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        body: Column(
          children: [
            _TitleBar(s: loc.s, showBack: showBack, showBrand: showBrand),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

class _TitleBar extends StatelessWidget {
  const _TitleBar({
    required this.s,
    required this.showBack,
    required this.showBrand,
  });

  final S s;
  final bool showBack;
  final bool showBrand;

  @override
  Widget build(BuildContext context) {
    final loc = context.read<LocaleController>();
    final bar = SizedBox(
      height: 34,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            if (showBack)
              _BarIcon(
                tooltip: s.back,
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => Navigator.of(context).maybePop(),
              )
            else
              const SizedBox(width: 4),
            if (showBrand) ...[
              const VpnaiLogo(size: 22),
              const SizedBox(width: 8),
              const VpnaiWordmark(fontSize: 13, glow: false, dim: true),
            ],
            const Spacer(),
            PopupMenuButton<String>(
              tooltip: s.language,
              padding: EdgeInsets.zero,
              offset: const Offset(0, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: ShahkarTheme.line),
              ),
              color: ShahkarTheme.surface,
              onSelected: loc.setCode,
              itemBuilder: (context) => [
                for (final item in S.locales)
                  PopupMenuItem(
                    value: item.code,
                    height: 40,
                    child: Row(
                      children: [
                        Text(item.flag, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 10),
                        Text(
                          item.code.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: item.code == loc.locale.languageCode
                                ? ShahkarTheme.accent
                                : ShahkarTheme.mute,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: item.code == loc.locale.languageCode
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: item.code == loc.locale.languageCode
                                ? ShahkarTheme.accent
                                : ShahkarTheme.fog,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(
                  Icons.language_rounded,
                  size: 18,
                  color: ShahkarTheme.mute,
                ),
              ),
            ),
            if (isDesktopShell) ...[
              _BarIcon(
                tooltip: s.minimize,
                icon: Icons.remove_rounded,
                onTap: minimizeVpnaiWindow,
              ),
              _BarIcon(
                tooltip: s.close,
                icon: Icons.close_rounded,
                onTap: closeVpnaiWindow,
                hoverDanger: true,
              ),
            ],
          ],
        ),
      ),
    );
    if (!isDesktopShell) return bar;
    return DragToMoveArea(child: bar);
  }
}

class _BarIcon extends StatelessWidget {
  const _BarIcon({
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.hoverDanger = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;
  final bool hoverDanger;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      hoverColor:
          hoverDanger ? ShahkarTheme.danger.withValues(alpha: 0.14) : null,
      icon: Icon(
        icon,
        size: 16,
        color: hoverDanger ? ShahkarTheme.mute : ShahkarTheme.mute,
      ),
    );
  }
}
