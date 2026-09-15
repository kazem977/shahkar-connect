# iOS Packet Tunnel Provider

`PacketTunnelProvider.swift` is the Network Extension entry. Add a Packet
Tunnel target in Xcode on a Mac with a paid Apple Developer account, then
link `native/bin/libbox.xcframework` from `./tool/build_libbox.sh`.

`ShahkarVpnPlugin.swift` is copied into `ios/Runner/` by bootstrap.
