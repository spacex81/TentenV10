import SwiftUI

@main
struct TentenV10App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    init() {
        _ = DatabaseManager.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

