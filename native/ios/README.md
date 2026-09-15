# iOS Packet Tunnel Provider

`PacketTunnelProvider.swift` is the Network Extension entry. On a Mac with a
paid Apple Developer account:

1. Run `./tool/bootstrap.sh` then `./tool/build_libbox.sh`.
2. In Xcode, add a Packet Tunnel target:
   - Bundle id: `com.shahkar.connect.PacketTunnel`
   - App Group: `group.com.shahkar.connect`
   - Entitlements: `ios/PacketTunnel/PacketTunnel.entitlements`
   - Info.plist: `ios/PacketTunnel/Info.plist`
3. Link `native/bin/libbox.xcframework`.

`ShahkarVpnPlugin.swift` is copied into `ios/Runner/` by bootstrap.
