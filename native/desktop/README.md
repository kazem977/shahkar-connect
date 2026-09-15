# Desktop sing-box

`DesktopVpnEngine` starts `SINGBOX_BIN` or `native/bin/sing-box` /
`native/bin/sing-box.exe` with `sing-box run -c <config>`. Fetch a release with
`./tool/fetch_singbox.sh` or `.\tool\fetch_singbox.ps1`.

TUN on Linux needs `CAP_NET_ADMIN`; Windows needs Administrator so WinTUN can
create the adapter (`wintun.dll` is copied next to the binary). A mixed inbound
on `127.0.0.1:2080` is added as a local fallback proxy.
