import Network
import Foundation

class NetworkManager: ObservableObject {
    static let shared = NetworkManager()
    
    private var monitor: NWPathMonitor
    private let queue = DispatchQueue.global(qos: .background)
    
    @Published var isConnectedToWifi: Bool = false
    @Published var isConnected: Bool = false
    
    init() {
        monitor = NWPathMonitor()
        startMonitoring()
    }
    
    private func startMonitoring() {
        NSLog("LOG: NetworkManager-startMonitoring")
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                // Detect if the device is connected to Wi-Fi
                if path.status == .satisfied {
                    self.isConnected = true
                    if path.usesInterfaceType(.wifi) {
                        self.isConnectedToWifi = true
                        NSLog("LOG: Connected to Wi-Fi")
                    } else if path.usesInterfaceType(.cellular) {
                        self.isConnectedToWifi = false
                        NSLog("LOG: Connected to Cellular (LTE, 5G, 4G)")
                    } else {
                        self.isConnectedToWifi = false
                        NSLog("LOG: Connected to Other Network (Ethernet, VPN, etc.)")
                    }
                } else {
                    self.isConnected = false
                    NSLog("LOG: No network connection")
                }
            }
        }
        monitor.start(queue: queue)
    }
    
    func stopMonitoring() {
        monitor.cancel()
    }
}
