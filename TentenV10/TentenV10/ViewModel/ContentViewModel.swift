import Combine
import Foundation

class ContentViewModel: ObservableObject {
    @Published var isUserLoggedIn = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        bindAuthManager()
    }
    
    private func bindAuthManager() {
        AuthManager.shared.$isUserLoggedIn
            .receive(on: DispatchQueue.main)
            .assign(to: &$isUserLoggedIn)
    }
}
