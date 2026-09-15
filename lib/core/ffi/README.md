# Native FFI / method channel

Dart talks to the OS VPN stack through `MethodChannel('com.shahkar.connect/vpn')`.
Platform trees are created by `./tool/bootstrap.sh`. Binaries stay in
`native/bin/` (gitignored).
