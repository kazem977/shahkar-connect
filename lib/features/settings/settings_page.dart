import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('تنظیمات')),
        body: ListView(
          children: const [
            ListTile(
              title: Text('تم'),
              subtitle: Text('پیروی از تنظیمات سیستم (روشن / تیره)'),
            ),
            ListTile(
              title: Text('پشتیبانی'),
              subtitle: Text('از داخل حساب پنل با پشتیبانی در تماس باشید.'),
            ),
          ],
        ),
      ),
    );
  }
}
