import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shahkar_connect/core/l10n/locale_controller.dart';
import 'package:shahkar_connect/core/prefs/app_prefs.dart';
import 'package:shahkar_connect/features/connect/presentation/diagnostics_page.dart';
import 'package:shahkar_connect/features/connect/security/kill_switch.dart';
import 'package:shahkar_connect/features/connect/security/network_watcher.dart';
import 'package:shahkar_connect/theme.dart';
import 'package:shahkar_connect/ui/settings_tiles.dart';
import 'package:shahkar_connect/ui/string_list_editor.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleController>().s;
    final prefs = context.watch<AppPrefs>();
    final killSwitch = context.watch<KillSwitchService>();
    final network = context.watch<NetworkWatcher>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 0, 6, 12),
          child: Text(
            s.settings,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: ShahkarTheme.fog,
            ),
          ),
        ),

        SettingsSectionHeader(s.securitySection),
        SettingsChoiceTile<KillSwitchMode>(
          icon: Icons.shield_moon_outlined,
          title: s.killSwitch,
          subtitle: s.killSwitchDesc,
          value: prefs.killSwitch,
          options: {
            KillSwitchMode.off: s.killSwitchOff,
            KillSwitchMode.auto: s.killSwitchAuto,
            KillSwitchMode.strict: s.killSwitchStrict,
          },
          onChanged: (value) async {
            await prefs.setKillSwitch(value);
            await killSwitch.syncWithMode();
          },
        ),
        if (prefs.killSwitch != KillSwitchMode.off &&
            killSwitch.state == KillSwitchState.unavailable)
          SettingsWarningTile(
            message: killSwitch.blocker == 'admin'
                ? s.killSwitchNeedsAdmin
                : s.killSwitchUnsupported,
            actionLabel: killSwitch.blocker == 'admin' ? s.runAsAdmin : null,
            onAction: killSwitch.blocker == 'admin'
                ? () => killSwitch.relaunchElevated()
                : null,
          ),
        SettingsChoiceTile<DnsMode>(
          icon: Icons.dns_outlined,
          title: s.dnsProtection,
          subtitle: s.dnsProtectionDesc,
          value: prefs.dns,
          options: {
            DnsMode.auto: s.dnsAuto,
            DnsMode.cloudflare: 'Cloudflare',
            DnsMode.google: 'Google',
            DnsMode.quad9: 'Quad9',
            DnsMode.adguard: 'AdGuard',
          },
          onChanged: prefs.setDns,
        ),
        SettingsSwitchTile(
          icon: Icons.filter_alt_outlined,
          title: s.blockIpv6,
          subtitle: s.blockIpv6Desc,
          value: prefs.blockIpv6,
          onChanged: prefs.setBlockIpv6,
        ),
        SettingsSwitchTile(
          icon: Icons.block_outlined,
          title: s.blockAds,
          subtitle: s.blockAdsDesc,
          value: prefs.blockAds,
          onChanged: prefs.setBlockAds,
        ),

        SettingsSectionHeader(s.automationSection),
        SettingsSwitchTile(
          icon: Icons.bolt_outlined,
          title: s.autoConnectLaunch,
          subtitle: s.autoConnectLaunchDesc,
          value: prefs.autoConnectOnLaunch,
          onChanged: prefs.setAutoConnectOnLaunch,
        ),
        SettingsSwitchTile(
          icon: Icons.speed_outlined,
          title: s.autoBestServer,
          subtitle: s.autoBestServerDesc,
          value: prefs.autoPickBestServer,
          onChanged: prefs.setAutoPickBestServer,
        ),
        SettingsChoiceTile<SmartSwitchMode>(
          icon: Icons.auto_awesome_outlined,
          title: s.smartSwitch,
          subtitle: s.smartSwitchDesc,
          value: prefs.smartSwitch,
          options: {
            SmartSwitchMode.off: s.smartSwitchOff,
            SmartSwitchMode.ask: s.smartSwitchAsk,
            SmartSwitchMode.auto: s.smartSwitchAuto,
          },
          onChanged: prefs.setSmartSwitch,
        ),
        SettingsSwitchTile(
          icon: Icons.restart_alt_outlined,
          title: s.autoReconnect,
          subtitle: s.autoReconnectDesc,
          value: prefs.autoReconnect,
          onChanged: prefs.setAutoReconnect,
        ),

        SettingsSectionHeader(s.networkSection),
        SettingsChoiceTile<RoutingProfile>(
          icon: Icons.alt_route_outlined,
          title: s.routingProfile,
          subtitle: s.routingProfileDesc,
          value: prefs.routing,
          options: {
            RoutingProfile.global: s.routingGlobal,
            RoutingProfile.domesticDirect: s.routingDomestic,
            RoutingProfile.selected: s.routingSelected,
          },
          onChanged: prefs.setRouting,
        ),
        StringListEditor(
          icon: Icons.apps_outlined,
          title: s.bypassApps,
          subtitle: s.splitTunnelingDesc,
          values: prefs.bypassApps,
          onChanged: prefs.setBypassApps,
          addLabel: s.addItem,
          hint: s.appExample,
          normalize: _normalizeProcess,
        ),
        if (prefs.routing == RoutingProfile.selected)
          StringListEditor(
            icon: Icons.vpn_lock_outlined,
            title: s.tunnelApps,
            values: prefs.tunnelApps,
            onChanged: prefs.setTunnelApps,
            addLabel: s.addItem,
            hint: s.appExample,
            normalize: _normalizeProcess,
          ),
        StringListEditor(
          icon: Icons.link_off_outlined,
          title: s.bypassDomains,
          values: prefs.bypassDomains,
          onChanged: prefs.setBypassDomains,
          addLabel: s.addItem,
          hint: s.domainExample,
          normalize: _normalizeDomain,
        ),
        SettingsSwitchTile(
          icon: Icons.lan_outlined,
          title: s.allowLan,
          subtitle: s.allowLanDesc,
          value: prefs.allowLan,
          onChanged: prefs.setAllowLan,
        ),

        SettingsSectionHeader(s.advancedSection),
        SettingsChoiceTile<MultiHopMode>(
          icon: Icons.swap_calls_outlined,
          title: s.multiHop,
          subtitle: s.multiHopDesc,
          value: prefs.multiHop,
          options: {
            MultiHopMode.off: s.multiHopOff,
            MultiHopMode.double: s.multiHopDouble,
          },
          onChanged: prefs.setMultiHop,
        ),
        SettingsSwitchTile(
          icon: Icons.network_check_outlined,
          title: s.shadowTesting,
          subtitle: s.shadowTestingDesc,
          value: prefs.shadowTesting,
          onChanged: prefs.setShadowTesting,
        ),
        SettingsSwitchTile(
          icon: Icons.straighten_outlined,
          title: prefs.tunedMtu == null
              ? s.adaptiveMtu
              : '${s.adaptiveMtu} · ${s.mtuValue} ${prefs.tunedMtu}',
          subtitle: s.adaptiveMtuDesc,
          value: prefs.adaptiveMtu,
          onChanged: (value) async {
            await prefs.setAdaptiveMtu(value);
            if (!value) await prefs.setTunedMtu(null);
          },
        ),
        SettingsSwitchTile(
          icon: Icons.radar_outlined,
          title: s.leakSentinel,
          subtitle: s.leakSentinelDesc,
          value: prefs.leakSentinel,
          onChanged: prefs.setLeakSentinel,
        ),
        SettingsSwitchTile(
          icon: Icons.wifi_tethering_outlined,
          title: s.autoConnectUntrusted,
          subtitle: s.autoConnectUntrustedDesc,
          value: prefs.autoConnectUntrusted,
          onChanged: prefs.setAutoConnectUntrusted,
        ),
        if (network.current.isWifi)
          SettingsCard(
            child: SettingsTileHead(
              icon: Icons.wifi_rounded,
              title: '${s.currentNetwork}: ${network.current.ssid}',
              subtitle: !network.current.secured
                  ? s.openNetwork
                  : (prefs.trustedNetworks.contains(network.current.ssid)
                      ? s.trustThisNetwork
                      : s.untrusted),
              trailing: prefs.trustedNetworks.contains(network.current.ssid)
                  ? null
                  : TextButton(
                      onPressed: () => prefs.setTrustedNetworks([
                        ...prefs.trustedNetworks,
                        network.current.ssid,
                      ]),
                      style: TextButton.styleFrom(
                        foregroundColor: ShahkarTheme.accentSoft,
                        minimumSize: const Size(0, 30),
                      ),
                      child: Text(
                        s.trustThisNetwork,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
            ),
          ),
        StringListEditor(
          icon: Icons.verified_user_outlined,
          title: s.trustedNetworks,
          subtitle: s.trustedNetworksDesc,
          values: prefs.trustedNetworks,
          onChanged: prefs.setTrustedNetworks,
          addLabel: s.addItem,
          hint: 'Wi-Fi SSID',
        ),
        SettingsNavTile(
          icon: Icons.monitor_heart_outlined,
          title: s.diagnostics,
          subtitle: s.diagnosticsDesc,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const DiagnosticsPage()),
          ),
        ),
      ],
    );
  }
}

/// Process rules match on the executable name, so strip any pasted path.
String _normalizeProcess(String raw) {
  final name = raw.split(RegExp(r'[\\/]')).last.trim();
  if (name.isEmpty) return '';
  return name.toLowerCase().endsWith('.exe') ? name : '$name.exe';
}

String _normalizeDomain(String raw) {
  var value = raw.trim().toLowerCase();
  value = value.replaceFirst(RegExp(r'^[a-z]+://'), '');
  value = value.split('/').first;
  return value;
}
