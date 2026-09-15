#!/usr/bin/env python3
"""Copy VPN plugin sources into generated platform trees. Idempotent."""
from __future__ import annotations

import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

ANDROID_PERMISSIONS = [
    "android.permission.INTERNET",
    "android.permission.FOREGROUND_SERVICE",
    "android.permission.FOREGROUND_SERVICE_SPECIAL_USE",
    "android.permission.POST_NOTIFICATIONS",
    "android.permission.ACCESS_NETWORK_STATE",
]

SERVICE_XML = """        <service
            android:name="com.shahkar.connect.vpn.ShahkarVpnService"
            android:exported="false"
            android:foregroundServiceType="specialUse"
            android:permission="android.permission.BIND_VPN_SERVICE"
            android:stopWithTask="false">
            <property
                android:name="android.app.PROPERTY_SPECIAL_USE_FGS_SUBTYPE"
                android:value="vpn" />
            <intent-filter>
                <action android:name="android.net.VpnService" />
            </intent-filter>
        </service>
    </application>"""

IOS_RUNNER_ENTITLEMENTS = """<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.developer.networking.networkextension</key>
	<array>
		<string>packet-tunnel-provider</string>
	</array>
	<key>com.apple.security.application-groups</key>
	<array>
		<string>group.com.shahkar.connect</string>
	</array>
</dict>
</plist>
"""

PACKET_TUNNEL_INFO = """<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDisplayName</key>
	<string>Shahkar Tunnel</string>
	<key>CFBundleIdentifier</key>
	<string>com.shahkar.connect.tunnel</string>
	<key>CFBundleName</key>
	<string>PacketTunnel</string>
	<key>CFBundlePackageType</key>
	<string>XPC!</string>
	<key>CFBundleShortVersionString</key>
	<string>1.0</string>
	<key>CFBundleVersion</key>
	<string>1</string>
	<key>NSExtension</key>
	<dict>
		<key>NSExtensionPointIdentifier</key>
		<string>com.apple.networkextension.packet-tunnel</string>
		<key>NSExtensionPrincipalClass</key>
		<string>$(PRODUCT_MODULE_NAME).PacketTunnelProvider</string>
	</dict>
</dict>
</plist>
"""

PACKET_TUNNEL_ENTITLEMENTS = """<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.developer.networking.networkextension</key>
	<array>
		<string>packet-tunnel-provider</string>
	</array>
	<key>com.apple.security.application-groups</key>
	<array>
		<string>group.com.shahkar.connect</string>
	</array>
	<key>com.apple.security.network.client</key>
	<true/>
	<key>com.apple.security.network.server</key>
	<true/>
</dict>
</plist>
"""


def _write_main_activity(main: Path) -> None:
    text = main.read_text(encoding="utf-8")
    pkg = "com.shahkar.connect.shahkar_connect"
    for line in text.splitlines():
        if line.startswith("package "):
            pkg = line.split()[1]
            break
    main.write_text(
        f"""package {pkg}

import com.shahkar.connect.vpn.ShahkarVpnPlugin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {{
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {{
        super.configureFlutterEngine(flutterEngine)
        ShahkarVpnPlugin.register(this, flutterEngine)
    }}
}}
""",
        encoding="utf-8",
    )


def _ensure_permission(xml: str, name: str) -> str:
    needle = f'android:name="{name}"'
    if needle in xml:
        return xml
    return xml.replace(
        "<application",
        f'    <uses-permission android:name="{name}" />\n    <application',
        1,
    )


def _copy_android() -> None:
    dest = ROOT / "android/app/src/main/kotlin/com/shahkar/connect/vpn"
    dest.mkdir(parents=True, exist_ok=True)
    src = ROOT / "native/android"
    for path in src.glob("*.kt"):
        shutil.copyfile(path, dest / path.name)

    aar = ROOT / "native/bin/libbox.aar"
    if aar.exists():
        libs = ROOT / "android/app/libs"
        libs.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(aar, libs / "libbox.aar")
        _ensure_aar_dep()

    mains = list((ROOT / "android").glob("**/MainActivity.kt"))
    if mains:
        main = mains[0]
        pkg = "com.shahkar.connect.shahkar_connect"
        for line in main.read_text(encoding="utf-8").splitlines():
            if line.startswith("package "):
                pkg = line.split()[1].strip()
                break
        main.write_text(
            f"""package {pkg}

import com.shahkar.connect.vpn.ShahkarVpnPlugin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {{
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {{
        super.configureFlutterEngine(flutterEngine)
        ShahkarVpnPlugin.register(this, flutterEngine)
    }}
}}
""",
            encoding="utf-8",
        )

    manifest = ROOT / "android/app/src/main/AndroidManifest.xml"
    if not manifest.exists():
        return
    xml = manifest.read_text(encoding="utf-8")
    xml = xml.replace('android:label="shahkar_connect"', 'android:label="شاهکار"')
    for perm in ANDROID_PERMISSIONS:
        xml = _ensure_permission(xml, perm)
    if "ShahkarVpnService" not in xml:
        xml = xml.replace("</application>", SERVICE_XML, 1)
    elif "foregroundServiceType" not in xml:
        xml = xml.replace(
            'android:permission="android.permission.BIND_VPN_SERVICE">',
            'android:foregroundServiceType="specialUse"\n'
            '            android:permission="android.permission.BIND_VPN_SERVICE">',
            1,
        )
    manifest.write_text(xml, encoding="utf-8")
    _patch_android_repos()
    _patch_android_sdk_versions()


_FLUTTER_ENGINE_REPOS = """        exclusiveContent {
            forRepository {
                maven { url = uri("https://storage.flutter-io.cn/download.flutter.io") }
            }
            filter {
                includeGroup("io.flutter")
            }
        }
        maven { url = uri("https://maven.aliyun.com/repository/google") }
        maven { url = uri("https://maven.aliyun.com/repository/central") }
        maven { url = uri("https://maven.aliyun.com/repository/public") }
        maven { url = uri("https://maven.aliyun.com/repository/gradle-plugin") }
"""


def _patch_android_repos() -> None:
    """Prefer Aliyun + flutter-io.cn so Gradle works when Google Maven is blocked."""
    settings = ROOT / "android/settings.gradle"
    if settings.exists():
        text = settings.read_text(encoding="utf-8")
        if "storage.flutter-io.cn" not in text:
            if "dependencyResolutionManagement" in text:
                text = text.replace(
                    "        google()\n        mavenCentral()",
                    _FLUTTER_ENGINE_REPOS + "        google()\n        mavenCentral()",
                    1,
                )
            else:
                text += """
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_PROJECT)
    repositories {
""" + _FLUTTER_ENGINE_REPOS + """        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
"""
        if "PREFER_SETTINGS" in text:
            text = text.replace("PREFER_SETTINGS", "PREFER_PROJECT")
        if "maven.aliyun.com" not in text:
            text = text.replace(
                "    repositories {\n        google()\n",
                "    repositories {\n" + _FLUTTER_ENGINE_REPOS + "        google()\n",
                1,
            )
        settings.write_text(text, encoding="utf-8")
    build = ROOT / "android/build.gradle"
    if build.exists():
        text = build.read_text(encoding="utf-8")
        if "storage.flutter-io.cn" not in text:
            text = text.replace(
                "    repositories {\n        google()\n",
                "    repositories {\n" + _FLUTTER_ENGINE_REPOS + "        google()\n",
                1,
            )
        if "maven.aliyun.com" not in text and "storage.flutter-io.cn" not in text:
            text = text.replace(
                "    repositories {\n        google()\n",
                "    repositories {\n" + _FLUTTER_ENGINE_REPOS + "        google()\n",
                1,
            )
        build.write_text(text, encoding="utf-8")


def _patch_android_sdk_versions() -> None:
    gradle = ROOT / "android/app/build.gradle"
    if not gradle.exists():
        return
    text = gradle.read_text(encoding="utf-8")
    text = text.replace("compileSdk = flutter.compileSdkVersion", "compileSdk = 35")
    if "buildToolsVersion" not in text and "compileSdk = 35" in text:
        text = text.replace(
            "compileSdk = 35",
            'compileSdk = 35\n    buildToolsVersion = "35.0.1"',
            1,
        )
    text = text.replace("ndkVersion = flutter.ndkVersion", 'ndkVersion = "27.0.12077973"')
    text = text.replace("minSdk = flutter.minSdkVersion", "minSdk = 24")
    text = text.replace("JavaVersion.VERSION_1_8", "JavaVersion.VERSION_17")
    gradle.write_text(text, encoding="utf-8")
    props = ROOT / "android/gradle.properties"
    if props.exists():
        p = props.read_text(encoding="utf-8")
        if "android.suppressUnsupportedCompileSdk" not in p:
            props.write_text(
                p.rstrip() + "\nandroid.suppressUnsupportedCompileSdk=35\n",
                encoding="utf-8",
            )


def _ensure_aar_dep() -> None:
    snippet = 'implementation(files("libs/libbox.aar"))'
    groovy = 'implementation files("libs/libbox.aar")'
    kts = ROOT / "android/app/build.gradle.kts"
    groovy_path = ROOT / "android/app/build.gradle"
    if kts.exists():
        text = kts.read_text(encoding="utf-8")
        if "libbox.aar" in text:
            return
        if "dependencies {" in text:
            text = text.replace("dependencies {", f"dependencies {{\n    {snippet}", 1)
            kts.write_text(text, encoding="utf-8")
        return
    if groovy_path.exists():
        text = groovy_path.read_text(encoding="utf-8")
        if "libbox.aar" in text:
            return
        if "dependencies {" in text:
            text = text.replace("dependencies {", f"dependencies {{\n    {groovy}", 1)
            groovy_path.write_text(text, encoding="utf-8")


def _copy_ios() -> None:
    runner = ROOT / "ios/Runner"
    if not runner.exists():
        return
    plugin_src = ROOT / "native/ios/ShahkarVpnPlugin.swift"
    (runner / "ShahkarVpnPlugin.swift").write_text(
        plugin_src.read_text(encoding="utf-8"), encoding="utf-8"
    )
    tunnel_dir = ROOT / "ios/PacketTunnel"
    tunnel_dir.mkdir(parents=True, exist_ok=True)
    (tunnel_dir / "PacketTunnelProvider.swift").write_text(
        (ROOT / "native/ios/PacketTunnelProvider.swift").read_text(encoding="utf-8"),
        encoding="utf-8",
    )
    (tunnel_dir / "Info.plist").write_text(PACKET_TUNNEL_INFO, encoding="utf-8")
    (tunnel_dir / "PacketTunnel.entitlements").write_text(
        PACKET_TUNNEL_ENTITLEMENTS, encoding="utf-8"
    )
    for name in ("Debug.entitlements", "Release.entitlements", "Runner.entitlements"):
        path = runner / name
        if path.exists() or name == "Runner.entitlements":
            current = path.read_text(encoding="utf-8") if path.exists() else ""
            if "packet-tunnel-provider" not in current:
                path.write_text(IOS_RUNNER_ENTITLEMENTS, encoding="utf-8")
    xcframework = ROOT / "native/bin/libbox.xcframework"
    if xcframework.exists():
        dest = ROOT / "ios/Frameworks/libbox.xcframework"
        dest.parent.mkdir(parents=True, exist_ok=True)
        if dest.exists():
            shutil.rmtree(dest)
        shutil.copytree(xcframework, dest)
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


def _patch_macos() -> None:
    macos = ROOT / "macos/Runner"
    if not macos.exists():
        return
    for entitlements in macos.glob("*.entitlements"):
        text = entitlements.read_text(encoding="utf-8")
        text = text.replace(
            "<key>com.apple.security.app-sandbox</key>\n	<true/>",
            "<key>com.apple.security.app-sandbox</key>\n	<false/>",
        )
        if "com.apple.security.network.client" not in text:
            text = text.replace(
                "</dict>",
                "	<key>com.apple.security.network.client</key>\n	<true/>\n"
                "	<key>com.apple.security.network.server</key>\n	<true/>\n</dict>",
                1,
            )
        entitlements.write_text(text, encoding="utf-8")


def _patch_windows() -> None:
    cmake = ROOT / "windows/CMakeLists.txt"
    if not cmake.exists():
        return
    text = cmake.read_text(encoding="utf-8")
    if "sing-box.exe" in text:
        return
    snippet = """
set(SINGBOX_BIN "${CMAKE_SOURCE_DIR}/../native/bin/sing-box.exe")
if(EXISTS ${SINGBOX_BIN})
  install(FILES "${SINGBOX_BIN}" DESTINATION "${INSTALL_BUNDLE_LIB_DIR}" COMPONENT Runtime)
endif()
set(WINTUN_DLL "${CMAKE_SOURCE_DIR}/../native/bin/wintun.dll")
if(EXISTS ${WINTUN_DLL})
  install(FILES "${WINTUN_DLL}" DESTINATION "${INSTALL_BUNDLE_LIB_DIR}" COMPONENT Runtime)
endif()
"""
    cmake.write_text(text.rstrip() + "\n" + snippet, encoding="utf-8")


def main() -> None:
    if (ROOT / "android").exists():
        _copy_android()
    if (ROOT / "ios").exists():
        _copy_ios()
    if (ROOT / "macos").exists():
        _patch_macos()
    if (ROOT / "windows").exists():
        _patch_windows()
    print("VPN glue copied into generated platform trees (gitignored).")


if __name__ == "__main__":
    main()
