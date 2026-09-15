import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shahkar_connect/core/l10n/s.dart';

class LocaleController extends ChangeNotifier {
  LocaleController();

  static const _key = 'vpnai_locale';
  Locale locale = const Locale('fa');

  S get s => S(locale.languageCode);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key) ?? 'fa';
    locale = Locale(_supported(code));
  }

  Future<void> setCode(String code) async {
    locale = Locale(_supported(code));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.languageCode);
    notifyListeners();
  }

  String _supported(String code) {
    const ok = {'fa', 'en', 'zh', 'ru'};
    return ok.contains(code) ? code : 'fa';
  }
}
