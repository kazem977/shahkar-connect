import Foundation
import NetworkExtension
import os.log

/// Packet Tunnel Provider. Link libbox.xcframework produced by tool/build_libbox.sh.
class PacketTunnelProvider: NEPacketTunnelProvider {
    private let log = OSLog(subsystem: "com.shahkar.connect", category: "tunnel")

    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        let proto = self.protocolConfiguration as? NETunnelProviderProtocol
        guard let json = proto?.providerConfiguration?["json"] as? String else {
            completionHandler(NSError(domain: "shahkar", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "missing tunnel json",
            ]))
            return
        }
        let dir = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.shahkar.connect")
            ?? FileManager.default.temporaryDirectory
        let cfg = dir.appendingPathComponent("sing-box.json")
        do {
            try json.data(using: .utf8)?.write(to: cfg)
        } catch {
            completionHandler(error)
            return
        }
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "127.0.0.1")
        settings.ipv4Settings = NEIPv4Settings(addresses: ["172.19.0.1"], subnetMasks: ["255.255.255.252"])
        settings.ipv4Settings?.includedRoutes = [NEIPv4Route.default()]
        settings.dnsSettings = NEDNSSettings(servers: ["1.1.1.1"])
        setTunnelNetworkSettings(settings) { error in
            if let error = error {
                completionHandler(error)
                return
            }
            do {
                try LibboxRuntime.start(configPath: cfg.path, configJson: json)
                os_log("libbox started %{public}@", log: self.log, type: .info, cfg.path)
                completionHandler(nil)
            } catch {
                completionHandler(error)
            }
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        LibboxRuntime.stop()
        completionHandler()
    }
}

enum LibboxRuntime {
    private static var instance: NSObject?

    static func start(configPath: String, configJson: String) throws {
        stop()
        let classNames = [
            "LibboxLibbox",
            "Libbox",
            "LibboxBoxService",
        ]
        var loaded: AnyClass?
        for name in classNames {
            if let cls = NSClassFromString(name) {
                loaded = cls
                break
            }
        }
        guard let cls = loaded as? NSObject.Type else {
            throw NSError(domain: "shahkar", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "libbox xcframework missing; run tool/build_libbox.sh on macOS",
            ])
        }
        let selectors = ["newService:", "NewService:", "start:"]
        for name in selectors {
            let sel = NSSelectorFromString(name)
            if cls.responds(to: sel) {
                _ = cls.perform(sel, with: configJson)
                instance = cls.init()
                return
            }
        }
        throw NSError(domain: "shahkar", code: 3, userInfo: [
            NSLocalizedDescriptionKey: "libbox has no start method",
        ])
    }

    static func stop() {
        instance = nil
    }
}
