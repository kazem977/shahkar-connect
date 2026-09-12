# شاهکار کانکت

اپ فلاتر چندسکویی برای پنل شاهکار. پنل همان ریپوی **Shahkarpanel** می‌ماند؛ این ریپو فقط کلاینت است تا روی مک/ویندوز کلون و بیلد شود بدون دست‌کاری سرور زنده.

```bash
git clone https://github.com/KhaJehAmiri/shahkar-connect.git
cd shahkar-connect
./tool/bootstrap.sh
flutter run --dart-define=SHAHKAR_API_BASE=https://your-panel.example
```

فلگ **`native_app_api`** در پنل باید روشن شود. تا آن زمان مسیر `/api/v1` برابر ۴۰۴ است و کاربران فعلی (ساب، کارینگ، تلگرام، پورتال) قطع نمی‌شوند.
