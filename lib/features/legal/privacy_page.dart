import 'package:flutter/material.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('حریم خصوصی')),
        body: const SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Text(
            'شاهکار برای برقراری اتصال VPN نام کاربری پورتال، وضعیت اشتراک، '
            'و آمار نشست (حجم ترافیک و نود انتخاب‌شده) را با پنل شما رد و بدل می‌کند.\n\n'
            'رسید خرید استور روی دستگاه به‌عنوان اثبات پرداخت ذخیره یا ارسال نمی‌شود؛ '
            'پنل رسید را از اپل یا گوگل استعلام می‌کند.\n\n'
            'آدرس پرداخت بیرونی داخل اپ نمایش داده نمی‌شود. '
            'جزئیات حقوقی: docs/store/PRIVACY.md در ریپوی shahkar-connect.',
          ),
        ),
      ),
    );
  }
}
