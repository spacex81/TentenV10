import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @ObservedObject var viewModel = ContentViewModel()
    
    init() {
        _ = DatabaseManager.shared
    }
    
    var body: some View {
        VStack {
            if viewModel.isUserLoggedIn {
                HomeView()
            } else {
                AuthView()
            }
        }
        .environmentObject(viewModel)
    }
}
