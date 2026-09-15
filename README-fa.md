# شاهکار کانکت

اپ فلاتر چندسکویی برای پنل شاهکار. پنل همان ریپوی **Shahkarpanel** می‌ماند؛ این ریپو فقط کلاینت است تا روی مک/ویندوز کلون و بیلد شود بدون دست‌کاری سرور زنده.

```bash
git clone https://github.com/KhaJehAmiri/shahkar-connect.git
cd shahkar-connect
./tool/bootstrap.sh
./tool/check.sh
flutter run --dart-define-from-file=env/dev.env.example
```

قالب env: `env/dev.env.example`، `env/staging.env.example`، `env/prod.env.example`. جزئیات: `docs/SETUP.md`.

فلگ **`native_app_api`** در پنل باید روشن شود. تا آن زمان مسیر `/api/v1` برابر ۴۰۴ است و کاربران فعلی (ساب، کارینگ، تلگرام، پورتال) قطع نمی‌شوند.

کارهایی که فقط روی لپ‌تاپ انجام می‌شود: `docs/LAPTOP.md`.
