# Shahkar Connect

Flutter client for the Shahkar panel. One codebase for iOS, Android, Windows, macOS, and Linux.

The panel repo stays **Shahkarpanel**. This repo is only the app, so you can clone it on a laptop and build without touching the live panel.

## Clone and build locally

```bash
git clone https://github.com/KhaJehAmiri/shahkar-connect.git
cd shahkar-connect
./tool/bootstrap.sh
flutter run
```

Pass the panel URL at build time:

```bash
flutter run --dart-define=SHAHKAR_API_BASE=https://your-panel.example
```

The panel must have feature flag **`native_app_api`** enabled. Until then `/api/v1/*` returns 404 and existing VPN users are unaffected.

## What talks to what

- Login uses the **same portal username/password** already on `users`.
- Entitlement is `users.status` / `expire` / traffic — not a second subscription table.
- Node shortlist comes from live `nodes` + public `hosts`. The app then TLS-probes those hosts and picks the fastest.
- sing-box / Network Extension / VpnService bindings are phase 4 (`lib/features/connect/engine`).

Backend contract: `Shahkarpanel` → `docs/NATIVE_APP.md`.
