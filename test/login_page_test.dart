import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shahkar_connect/core/api/api_client.dart';
import 'package:shahkar_connect/core/l10n/locale_controller.dart';
import 'package:shahkar_connect/core/storage/token_store.dart';
import 'package:shahkar_connect/features/auth/data/auth_repository.dart';
import 'package:shahkar_connect/features/auth/presentation/login_page.dart';
import 'package:shahkar_connect/theme.dart';

void main() {
  testWidgets('login page shows vpnai form', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final tokens = TokenStore();
    final api = ApiClient(baseUrl: 'https://example.com', tokens: tokens);
    final locale = LocaleController();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AuthRepository>.value(
            value: AuthRepository(api: api, tokens: tokens),
          ),
          ChangeNotifierProvider.value(value: locale),
        ],
        child: MaterialApp(
          theme: ShahkarTheme.dark(locale.locale),
          home: const LoginPage(),
        ),
      ),
    );
    expect(find.text('vpnai'), findsWidgets);
    expect(find.text('ورود'), findsOneWidget);
    expect(find.text('نام کاربری'), findsOneWidget);
  });
}
