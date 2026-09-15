# Laptop checklist (Shahkar Connect)

This server cannot compile Android/iOS VPN binaries or run a device. Clone the
app on a Mac (iOS) or any machine with Flutter (Android / desktop).

**Windows (PowerShell):**

```powershell
git clone https://github.com/KhaJehAmiri/shahkar-connect.git
cd shahkar-connect
.\tool\bootstrap.ps1
.\tool\fetch_singbox.ps1
.\tool\check.ps1
flutter run -d windows --dart-define=SHAHKAR_API_BASE=https://YOUR-LAB-PANEL
```

**macOS / Linux:**

```bash
git clone https://github.com/KhaJehAmiri/shahkar-connect.git
cd shahkar-connect
./tool/bootstrap.sh
./tool/check.sh
```

Point `env/dev.env.example` at a **lab** panel, not production, until
`native_app_api` is enabled:

```bash
flutter run --dart-define=SHAHKAR_API_BASE=https://YOUR-LAB-PANEL
```

Desktop TUN needs administrator / `CAP_NET_ADMIN`. The engine also exposes a
local mixed inbound on `127.0.0.1:2080`.

If `pub.dev` returns 403, set:

```powershell
$env:PUB_HOSTED_URL = "https://pub.flutter-io.cn"
$env:FLUTTER_STORAGE_BASE_URL = "https://storage.flutter-io.cn"
```

## Tunnel binaries

| Platform | Script | Result |
|---|---|---|
| Windows desktop | `.\tool\fetch_singbox.ps1` | `native/bin/sing-box.exe` + `wintun.dll` |
| Linux / macOS desktop | `./tool/fetch_singbox.sh` | `native/bin/sing-box` |
| Android | `./tool/build_libbox.sh` (Go + NDK) | `native/bin/libbox.aar` |
| iOS | same, on macOS with Xcode + paid Apple Developer | `native/bin/libbox.xcframework` + Network Extension target |

Then add the AAR/xcframework to the generated `android/` / `ios/` trees
(`bootstrap` already copies Kotlin/Swift glue and, on a Mac, Packet Tunnel
sources under `ios/PacketTunnel/`).

## What still needs a human

1. Apple Developer: Network Extension + App Groups `group.com.shahkar.connect`.
   In Xcode add a Packet Tunnel target whose bundle id is
   `com.shahkar.connect.PacketTunnel` and whose sources live in `ios/PacketTunnel/`.
2. Google Play: VPN policy declaration (draft: `docs/store/GOOGLE_VPN_POLICY.md`).
3. Store listing screenshots from a real device (`docs/store/LISTING.md`).
4. App Store / Play IAP products matching `app_plan_store_skus`.
5. Do **not** merge or enable the panel flag until a device has connected
   through sing-box against a lab node.
