# Phase 0 — local setup

Two repositories. Do not copy this Flutter tree into the live panel checkout;
Shahkar's `.gitignore` ignores `lib/` and a bind-mount restart must not pick
up the native-app Alembic head.

| Repo | Role | GitHub |
|---|---|---|
| `Shahkarpanel` | FastAPI panel, branch `feat/native-app-v1` | https://github.com/KhaJehAmiri/Shahkarpanel |
| `shahkar-connect` | Flutter client (this repo) | https://github.com/KhaJehAmiri/shahkar-connect |

## Flutter (laptop with Flutter SDK)

```bash
git clone https://github.com/KhaJehAmiri/shahkar-connect.git
cd shahkar-connect
./tool/bootstrap.sh
./tool/check.sh
flutter run --dart-define-from-file=env/dev.env.example
```

`./tool/bootstrap.sh` runs `flutter create` for iOS, Android, Windows, macOS,
and Linux, then copies VPN glue from `native/`. Generated platform trees stay
untracked (`/android/` …). Laptop-only steps: `docs/LAPTOP.md`.

## Panel API (do not restart production from this)

Templates: `env/dev.env.example`, `env/staging.env.example`, `env/prod.env.example`
on `feat/native-app-v1`. Copy keys into `/var/lib/shahkar/.env` when you are
ready to enable the API:

- `NATIVE_APP_WEBHOOK_SECRET` — empty means webhooks fail closed
- `NATIVE_APP_IAP_MOCK` — `true` only on lab/staging; **false in production**

`native_app_api` defaults **off**. Until a sudo admin toggles it, `/api/v1/*`
is 404 and subscription / Karing / Telegram / portal clients are unchanged.

Do not merge `feat/native-app-v1` to `master`, do not run `alembic upgrade` on
the live database, and do not restart the panel container unless you intend
to apply migration `nn44ii55dd66`.
