import Flutter
import Foundation
import NetworkExtension

final class ShahkarVpnPlugin: NSObject, FlutterPlugin {
    static let methods = "com.shahkar.connect/vpn"
    static let state = "com.shahkar.connect/vpn_state"
    static let stats = "com.shahkar.connect/vpn_stats"
    private var manager: NETunnelProviderManager?
    private var stateSink: FlutterEventSink?
    private var observer: NSObjectProtocol?

    static func register(with registrar: FlutterPluginRegistrar) {
        let instance = ShahkarVpnPlugin()
        let channel = FlutterMethodChannel(name: methods, binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: channel)
        FlutterEventChannel(name: state, binaryMessenger: registrar.messenger())
            .setStreamHandler(StateStream(plugin: instance))
        FlutterEventChannel(name: stats, binaryMessenger: registrar.messenger())
            .setStreamHandler(NullStream())
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "start":
            let json = (call.arguments as? [String: Any])?["json"] as? String ?? ""
            start(json: json, result: result)
        case "stop":
            manager?.connection.stopVPNTunnel()
            stateSink?(["kind": "idle"])
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func start(json: String, result: @escaping FlutterResult) {
        NETunnelProviderManager.loadAllFromPreferences { managers, error in
            if let error = error {
                result(FlutterError(code: "LOAD", message: error.localizedDescription, details: nil))
                return
            }
            let mgr = managers?.first ?? NETunnelProviderManager()
            let proto = NETunnelProviderProtocol()
            proto.providerBundleIdentifier = "com.shahkar.connect.PacketTunnel"
            proto.serverAddress = "Shahkar"
            proto.providerConfiguration = ["json": json]
            mgr.protocolConfiguration = proto
            mgr.localizedDescription = "Shahkar"
            mgr.isEnabled = true
            mgr.saveToPreferences { saveErr in
                if let saveErr = saveErr {
                    result(FlutterError(code: "SAVE", message: saveErr.localizedDescription, details: nil))
                    return
                }
                mgr.loadFromPreferences { loadErr in
                    if let loadErr = loadErr {
                        result(FlutterError(code: "RELOAD", message: loadErr.localizedDescription, details: nil))
                        return
                    }
                    self.observe(mgr)
                    do {
                        try mgr.connection.startVPNTunnel()
                        self.manager = mgr
                        self.stateSink?(["kind": "connecting"])
                        result(nil)
                    } catch {
                        result(FlutterError(code: "START", message: error.localizedDescription, details: nil))
                    }
                }
            }
        }
    }

    private func observe(_ mgr: NETunnelProviderManager) {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
        observer = NotificationCenter.default.addObserver(
            forName: .NEVPNStatusDidChange,
            object: mgr.connection,
            queue: .main
        ) { [weak self] _ in
            switch mgr.connection.status {
            case .connected:
                self?.stateSink?(["kind": "connected"])
            case .connecting, .reasserting:
                self?.stateSink?(["kind": "connecting"])
            case .disconnecting:
                self?.stateSink?(["kind": "idle"])
            case .disconnected, .invalid:
                self?.stateSink?(["kind": "idle"])
            @unknown default:
                break
            }
        }
    }

    fileprivate class StateStream: NSObject, FlutterStreamHandler {
        weak var plugin: ShahkarVpnPlugin?
        init(plugin: ShahkarVpnPlugin) { self.plugin = plugin }
        func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
            plugin?.stateSink = events
            return nil
        }
        func onCancel(withArguments arguments: Any?) -> FlutterError? {
            plugin?.stateSink = nil
            return nil
        }
    }

    fileprivate class NullStream: NSObject, FlutterStreamHandler {
        func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? { nil }
        func onCancel(withArguments arguments: Any?) -> FlutterError? { nil }
    }
}
