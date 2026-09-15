import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:shahkar_connect/core/api/api_client.dart';
import 'package:shahkar_connect/core/desktop/window.dart';
import 'package:shahkar_connect/core/l10n/locale_controller.dart';
import 'package:shahkar_connect/core/prefs/app_prefs.dart';
import 'package:shahkar_connect/core/storage/token_store.dart';
import 'package:shahkar_connect/features/auth/data/auth_repository.dart';
import 'package:shahkar_connect/features/auth/presentation/login_page.dart';
import 'package:shahkar_connect/features/connect/engine/vpn_engine.dart';
import 'package:shahkar_connect/features/connect/guard/connection_guard.dart';
import 'package:shahkar_connect/features/connect/security/kill_switch.dart';
import 'package:shahkar_connect/features/connect/security/leak_sentinel.dart';
import 'package:shahkar_connect/features/connect/security/network_watcher.dart';
import 'package:shahkar_connect/features/connect/presentation/main_shell.dart';
import 'package:shahkar_connect/features/connect/presentation/session_controller.dart';
import 'package:shahkar_connect/features/iap/iap_service.dart';
import 'package:shahkar_connect/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDesktopWindow();
  const apiBase = String.fromEnvironment(
    'SHAHKAR_API_BASE',
    defaultValue: 'https://91.220.8.251',
  );
  const appVersion = String.fromEnvironment(
    'SHAHKAR_APP_VERSION',
    defaultValue: '0.1.0',
  );
  final tokens = TokenStore();
  await tokens.deviceId();
  final locale = LocaleController();
  await locale.load();
  final prefs = await AppPrefs.load();
  final api =
      ApiClient(baseUrl: apiBase, tokens: tokens, appVersion: appVersion);
  final auth = AuthRepository(api: api, tokens: tokens);
  final iap = IapService(api);
  final loggedIn = await tokens.hasSession();

  final session = SessionController(
    api: api,
    engine: VpnEngine.forPlatform(),
    prefs: prefs,
  );
  final killSwitch = KillSwitchService(prefs: prefs);
  final leakSentinel = LeakSentinel();
  final networkWatcher = NetworkWatcher();
  final guard = ConnectionGuard(
    session: session,
    prefs: prefs,
    killSwitch: killSwitch,
    leakSentinel: leakSentinel,
    networkWatcher: networkWatcher,
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: api),
        Provider<AuthRepository>.value(value: auth),
        Provider<IapService>.value(value: iap),
        ChangeNotifierProvider.value(value: locale),
        ChangeNotifierProvider.value(value: prefs),
        ChangeNotifierProvider.value(value: killSwitch),
        ChangeNotifierProvider.value(value: leakSentinel),
        ChangeNotifierProvider.value(value: networkWatcher),
        ChangeNotifierProvider.value(value: session),
        ChangeNotifierProvider.value(value: guard),
      ],
      child: VpnaiApp(loggedIn: loggedIn),
    ),
  );
}

class VpnaiApp extends StatelessWidget {
  const VpnaiApp({super.key, required this.loggedIn});

  final bool loggedIn;

  static final _shadDark = ShadThemeData(
    brightness: Brightness.dark,
    colorScheme: const ShadVioletColorScheme.dark(
      background: Color(0xFF05060A),
      primary: Color(0xFF8B7CFF),
      ring: Color(0xFF8B7CFF),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocaleController>();
    return ScreenUtilInit(
      designSize: kVpnaiWindow,
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, _) {
        return ShadApp.custom(
          theme: _shadDark,
          darkTheme: _shadDark,
          themeMode: ThemeMode.dark,
          appBuilder: (context) {
            return MaterialApp(
              title: 'vpnai',
              debugShowCheckedModeBanner: false,
              theme: ShahkarTheme.dark(loc.locale),
              themeMode: ThemeMode.dark,
              locale: loc.locale,
              supportedLocales: const [
                Locale('fa'),
                Locale('en'),
                Locale('zh'),
                Locale('ru'),
              ],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: loggedIn ? const MainShell() : const LoginPage(),
            );
          },
        );
      },
    );
  }
}
