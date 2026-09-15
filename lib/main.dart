import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shahkar_connect/core/api/api_client.dart';
import 'package:shahkar_connect/core/storage/token_store.dart';
import 'package:shahkar_connect/features/auth/data/auth_repository.dart';
import 'package:shahkar_connect/features/auth/presentation/login_page.dart';
import 'package:shahkar_connect/features/connect/engine/vpn_engine.dart';
import 'package:shahkar_connect/features/connect/presentation/home_page.dart';
import 'package:shahkar_connect/features/connect/presentation/session_controller.dart';
import 'package:shahkar_connect/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const apiBase = String.fromEnvironment(
    'SHAHKAR_API_BASE',
    defaultValue: 'https://panel.example.com',
  );
  final tokens = TokenStore();
  final api = ApiClient(baseUrl: apiBase, tokens: tokens);
  final auth = AuthRepository(api: api, tokens: tokens);
  final loggedIn = await tokens.hasSession();

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: api),
        Provider<AuthRepository>.value(value: auth),
        ChangeNotifierProvider(
          create:
              (_) =>
                  SessionController(api: api, engine: VpnEngine.forPlatform()),
        ),
      ],
      child: ShahkarApp(loggedIn: loggedIn),
    ),
  );
}

class ShahkarApp extends StatelessWidget {
  const ShahkarApp({super.key, required this.loggedIn});

  final bool loggedIn;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shahkar',
      debugShowCheckedModeBanner: false,
      theme: ShahkarTheme.light,
      darkTheme: ShahkarTheme.dark,
      themeMode: ThemeMode.system,
      locale: const Locale('fa'),
      supportedLocales: const [Locale('fa'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: loggedIn ? const HomePage() : const LoginPage(),
    );
  }
}
