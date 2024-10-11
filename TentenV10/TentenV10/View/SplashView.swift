import SwiftUI
import Combine

struct SplashView: View {
    @State private var isActive = false
    @ObservedObject var viewModel = HomeViewModel.shared

    var body: some View {
        ZStack {
            Image("app_bg")
                .resizable()
                .scaledToFill() // Scale the image to fill the screen
                .ignoresSafeArea()
            
            Image("app_logo")
        }
        .onAppear {
            // Show splash screen for 1 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation {
                    isActive = true
                }
            }
            
            // 
        }
        .fullScreenCover(isPresented: $isActive) {
            // Navigate to ContentView after the splash screen
            ContentView()
        }
    }
}

// Preview for SplashView
struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView()
    }
}
