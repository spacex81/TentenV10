import Combine
import UIKit
import Foundation
import SwiftUI

class ContentViewModel: ObservableObject {
    static let shared = ContentViewModel()
    
    let authManager = AuthManager.shared
    
    // MARK: Authentication
    @Published var isUserLoggedIn = true
    //
    
    // MARK: Onboarding
    @Published var isOnboardingComplete = true
    @Published var onboardingStep: OnboardingStep = .username
    //

    @Published var username: String = ""
    @Published var profileImage: UIImage? = nil
    
    // MARK: Invitation
    @Published var showPopup: Bool = false
    @Published var invitations: [Invitation] = []
    @Published var previousInvitationCount: Int = 0
    //
    
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
    
    func generateInvitations() {
        let count = Int.random(in: 1...3)
        invitations = (0..<count).map { i in
            Invitation(name: "user\(i + 1)")
        }
        previousInvitationCount = invitations.count
    }
    
    func handleButtonPress() {
        if !invitations.isEmpty {
            previousInvitationCount = invitations.count
            invitations.removeLast()
        }
        if invitations.isEmpty {
            withAnimation {
                showPopup = false
            }
        }
    }
}

struct Invitation: Identifiable {
    let id = UUID()
    let name: String
}
