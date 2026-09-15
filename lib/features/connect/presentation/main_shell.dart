import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:shahkar_connect/core/l10n/locale_controller.dart';
import 'package:shahkar_connect/core/l10n/s.dart';
import 'package:shahkar_connect/features/account/presentation/account_page.dart';
import 'package:shahkar_connect/features/connect/guard/connection_guard.dart';
import 'package:shahkar_connect/features/connect/presentation/home_page.dart';
import 'package:shahkar_connect/features/offer/presentation/offer_page.dart';
import 'package:shahkar_connect/features/settings/settings_page.dart';
import 'package:shahkar_connect/ui/app_chrome.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Restores kill-switch state and starts quality monitoring for the session.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConnectionGuard>().start();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleController>().s;
    return AppScaffold(
      showBrand: false,
      backgroundColor: VpnGlass.dark,
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _index,
              children: const [
                HomePage(),
                OfferPage(),
                SettingsPage(),
                AccountPage(),
              ],
            ),
          ),
          _BottomNav(
            index: _index,
            s: s,
            onChanged: (i) => setState(() => _index = i),
          ),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.index,
    required this.s,
    required this.onChanged,
  });

  final int index;
  final S s;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(4.w, 9.h, 4.w, 11.h),
      decoration: const BoxDecoration(
        color: Color(0xFF040506),
        border: Border(top: BorderSide(color: Color(0xFF15181C))),
      ),
      child: Row(
        children: [
          _NavItem(
            selected: index == 0,
            icon: index == 0 ? Icons.home_rounded : Icons.home_outlined,
            label: s.home,
            onTap: () => onChanged(0),
          ),
          _NavItem(
            selected: index == 1,
            icon: Icons.notifications_none_rounded,
            label: s.offer,
            onTap: () => onChanged(1),
          ),
          _NavItem(
            selected: index == 2,
            icon: Icons.settings_outlined,
            label: s.settings,
            onTap: () => onChanged(2),
          ),
          _NavItem(
            selected: index == 3,
            icon: Icons.person_outline_rounded,
            label: s.account,
            onTap: () => onChanged(3),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? VpnGlass.navActive : VpnGlass.navIdle;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 4.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 21.sp, color: color),
              SizedBox(height: 4.h),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9.5.sp,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
