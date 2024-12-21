//import SwiftUI
//import KakaoSDKCommon
//import KakaoSDKAuth
//
//@main
//struct TentenV10App: App {
//    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
//    init() {
//        KakaoSDK.initSDK(appKey:"aefdd4db2fe061703b2470f7d2c130a8")
//    }
//    
//    var body: some Scene {
//        WindowGroup {
//            ContentView()
//                .onOpenURL { url in
//                    if (AuthApi.isKakaoTalkLoginUrl(url)) {
//                        _ = AuthController.handleOpenUrl(url: url)
//                    }
//                }
//        }
//    }
//}
//

import SwiftUI
import KakaoSDKCommon
import KakaoSDKAuth

@main
struct TentenV10App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @StateObject private var viewModel = HomeViewModel()
    @Environment(\.scenePhase) private var scenePhase
    
    // Initialize Kakao SDK with the app key
    init() {
        KakaoSDK.initSDK(appKey: "aefdd4db2fe061703b2470f7d2c130a8")
    }
    
    var body: some Scene {
        WindowGroup {
            SplashView() // Start with SplashView as the initial screen
                .onOpenURL { url in
                    if AuthApi.isKakaoTalkLoginUrl(url) {
                        _ = AuthController.handleOpenUrl(url: url)
                    }
                }
                .onAppear {
                    // Call handleScenePhaseChange manually on first launch
//                    viewModel.handleScenePhaseChange(to: .active)
                }
                .onChange(of: scenePhase) { _, newScenePhase in
//                    viewModel.handleScenePhaseChange(to: newScenePhase)
                }
        }
    }
}
