import NetworkExtension
import os.log

/// Packet Tunnel Provider. Link libbox.xcframework produced by tool/build_libbox.sh.
class PacketTunnelProvider: NEPacketTunnelProvider {
    private let log = OSLog(subsystem: "com.shahkar.connect", category: "tunnel")

    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        let proto = self.protocolConfiguration as? NETunnelProviderProtocol
        guard let json = proto?.providerConfiguration?["json"] as? String else {
            completionHandler(NSError(domain: "shahkar", code: 1))
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
            os_log("tunnel settings applied; start libbox with %{public}@", log: self.log, type: .info, cfg.path)
            completionHandler(nil)
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}
