# Laptop checklist (Shahkar Connect)

This server cannot compile Android/iOS VPN binaries or run a device. Clone the
app on a Mac (iOS) or any machine with Flutter (Android / desktop).

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

## Tunnel binaries

| Platform | Script | Result |
|---|---|---|
| Linux / Windows / macOS desktop | `./tool/fetch_singbox.sh` | `native/bin/sing-box` |
| Android | `./tool/build_libbox.sh` (Go + NDK) | `native/bin/libbox.aar` |
| iOS | same, on macOS with Xcode + paid Apple Developer | `native/bin/libbox.xcframework` + Network Extension target |

Then add the AAR/xcframework to the generated `android/` / `ios/` trees
(`bootstrap.sh` already copies Kotlin/Swift glue).

## What still needs a human

1. Apple Developer: Network Extension + App Groups `group.com.shahkar.connect`.
2. Google Play: VPN policy declaration (draft: `docs/store/GOOGLE_VPN_POLICY.md`).
3. Store listing screenshots from a real device (`docs/store/LISTING.md`).
4. App Store / Play IAP products matching `app_plan_store_skus`.
5. Do **not** merge or enable the panel flag until a device has connected
   through sing-box against a lab node.
