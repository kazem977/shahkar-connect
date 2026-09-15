#!/usr/bin/env python3
"""Copy VPN plugin sources into generated android/ios trees. Idempotent."""
from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def _copy_android() -> None:
    dest = ROOT / "android/app/src/main/kotlin/com/shahkar/connect/vpn"
    dest.mkdir(parents=True, exist_ok=True)
    src = ROOT / "native/android"
    for name in ("ShahkarVpnService.kt", "ShahkarVpnPlugin.kt"):
        (dest / name).write_text((src / name).read_text(encoding="utf-8"), encoding="utf-8")
    mains = list((ROOT / "android").glob("**/MainActivity.kt"))
    if not mains:
        return
    main = mains[0]
    text = main.read_text(encoding="utf-8")
    if "ShahkarVpnPlugin.register" in text:
        return
    if "import com.shahkar.connect.vpn.ShahkarVpnPlugin" not in text:
        text = text.replace(
            "package com.shahkar.connect\n",
            "package com.shahkar.connect\n\n"
            "import com.shahkar.connect.vpn.ShahkarVpnPlugin\n"
            "import io.flutter.embedding.engine.FlutterEngine\n",
            1,
        )
    if "configureFlutterEngine" in text:
        text = text.replace(
            "super.configureFlutterEngine(flutterEngine)",
            "super.configureFlutterEngine(flutterEngine)\n"
            "        ShahkarVpnPlugin.register(this, flutterEngine)",
            1,
        )
    else:
        text = text.rstrip()
        if text.endswith("}"):
            text = text[: text.rfind("}")]
        text += (
            "\n    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {\n"
            "        super.configureFlutterEngine(flutterEngine)\n"
            "        ShahkarVpnPlugin.register(this, flutterEngine)\n"
            "    }\n}\n"
        )
    main.write_text(text, encoding="utf-8")

    manifest = ROOT / "android/app/src/main/AndroidManifest.xml"
    if not manifest.exists():
        return
    xml = manifest.read_text(encoding="utf-8")
    if "ShahkarVpnService" in xml:
        return
    xml = xml.replace(
        "</application>",
        """        <service
            android:name="com.shahkar.connect.vpn.ShahkarVpnService"
            android:exported="false"
            android:permission="android.permission.BIND_VPN_SERVICE">
            <intent-filter>
                <action android:name="android.net.VpnService" />
            </intent-filter>
        </service>
    </application>""",
        1,
    )
    if "android.permission.FOREGROUND_SERVICE" not in xml:
        xml = xml.replace(
            "<application",
            '    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />\n    <application',
            1,
        )
    manifest.write_text(xml, encoding="utf-8")


def _copy_ios() -> None:
    runner = ROOT / "ios/Runner"
    if not runner.exists():
        return
    plugin_src = ROOT / "native/ios/ShahkarVpnPlugin.swift"
    (runner / "ShahkarVpnPlugin.swift").write_text(
        plugin_src.read_text(encoding="utf-8"), encoding="utf-8"
    )
    delegate = runner / "AppDelegate.swift"
    if not delegate.exists():
        return
    swift = delegate.read_text(encoding="utf-8")
    if "ShahkarVpnPlugin.register" in swift:
        return
    swift = swift.replace(
        "GeneratedPluginRegistrant.register(with: self)",
        "GeneratedPluginRegistrant.register(with: self)\n    ShahkarVpnPlugin.register(with: self)",
        1,
    )
    delegate.write_text(swift, encoding="utf-8")


def main() -> None:
    if (ROOT / "android").exists():
        _copy_android()
    if (ROOT / "ios").exists():
        _copy_ios()
    print("VPN glue copied into generated platform trees (gitignored).")


if __name__ == "__main__":
    main()
