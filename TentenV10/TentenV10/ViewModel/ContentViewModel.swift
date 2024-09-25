import Combine
import UIKit
import Foundation

class ContentViewModel: ObservableObject {
    static let shared = ContentViewModel()
    
    let authManager = AuthManager.shared
    
    @Published var isUserLoggedIn = true
    @Published var isOnboardingComplete = true
    private var previousOnboarding: OnboardingStep = .username
    @Published var onboardingStep: OnboardingStep = .username {
        didSet {
//            if previousOnboarding != onboardingStep {
//                print("LOG: onboardingStep")
//                print(onboardingStep)
//            }
            previousOnboarding = onboardingStep
        }
    }
    
    @Published var username: String = ""
    @Published var profileImage: UIImage? = nil
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        bindAuthManager()
    }
    
    private func bindAuthManager() {
        AuthManager.shared.$isUserLoggedIn
            .receive(on: DispatchQueue.main)
            .assign(to: &$isUserLoggedIn)
        
        AuthManager.shared.$isOnboardingComplete
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                self?.isOnboardingComplete = newValue  // This will trigger the didSet observer
            }
            .store(in: &cancellables)
        
        AuthManager.shared.$onboardingStep
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                self?.onboardingStep = newValue  // This will trigger the didSet observer
            }
            .store(in: &cancellables)
    }
}
