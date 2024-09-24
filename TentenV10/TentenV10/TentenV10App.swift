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
    
    // Initialize Kakao SDK with the app key
    init() {
        KakaoSDK.initSDK(appKey: "aefdd4db2fe061703b2470f7d2c130a8")
    }
    
    var body: some Scene {
        WindowGroup {
//            SplashView() // Start with SplashView as the initial screen
//                .onOpenURL { url in
//                    if AuthApi.isKakaoTalkLoginUrl(url) {
//                        _ = AuthController.handleOpenUrl(url: url)
//                    }
//                }
            MicPermissionView()
        }
    }
}
