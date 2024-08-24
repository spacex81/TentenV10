import Foundation
import SwiftUI
import FirebaseAuth
import Combine

class HomeViewModel: ObservableObject {
    static let shared = HomeViewModel()
    
    private let authManager = AuthManager.shared
    private let repoManager = RepositoryManager.shared
    private let liveKitManager = LiveKitManager.shared
    private let audioSessionManager = AudioSessionManager.shared
    private let backgroundTaskManager = BackgroundTaskManager.shared
    
    @Published var currentUser: User?
    @Published var userRecord: UserRecord?
    @Published var selectedFriend: FriendRecord?
    
    @Published var isPressing: Bool = false {
        didSet {
//            handlePressingStateChange()
        }
    }
    @Published var isLocked: Bool = false
    @Published var progress: Float = 0.0
    
    @Published var detailedFriends: [FriendRecord] = []
    
    @Published var needUserFetch: Bool = true
    
    
    @Published var isConnected: Bool = false
    @Published var isPublished: Bool = false
    
    @Published var friendPin: String = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        bindRepositoryManager()
        bindLiveKitManager()
    }
    
    private func bindLiveKitManager() {
        liveKitManager.$isConnected
            .receive(on: DispatchQueue.main)
            .assign(to: &$isConnected)
        
        liveKitManager.$isPublished
            .receive(on: DispatchQueue.main)
            .assign(to: &$isPublished)
    }
    
    private func bindRepositoryManager() {
        repoManager.$userRecord
            .receive(on: DispatchQueue.main)
            .sink { userRecord in
                self.userRecord = userRecord
            }
            .store(in: &cancellables)
        
        repoManager.$selectedFriend
            .receive(on: DispatchQueue.main)
            .sink { selectedFriend in
                self.selectedFriend = selectedFriend
            }
            .store(in: &cancellables)
        
        repoManager.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { currentUser in
                self.currentUser = currentUser
                
                if self.repoManager.needUserFetch, let id = currentUser?.uid {
                    // when app launches with
                    // previously already authenticated
                    self.fetchUser(id: id)
                }
            }
            .store(in: &cancellables)
        
        repoManager.$detailedFriends
            .receive(on: DispatchQueue.main)
            .sink { detailedFriends in
                self.detailedFriends = detailedFriends
            }
            .store(in: &cancellables)
    }
    
    private func handlePressingStateChange() {
        Task {
            if isPressing {
                if !isConnected {
                    await connect()
                }
                publishAudio()
            } else {
                await unpublishAudio()
                disconnect()
            }
        }
    }
}

// MARK: LiveKit
extension HomeViewModel {
    func connect() async {
        guard let friendUid = selectedFriend?.id else {
            NSLog("LOG: Friend is not selected")
            return
        }
        
        guard let roomName = userRecord?.roomName else {
            NSLog("LOG: userRecord is not set when trying to connect to LiveKit")
            return
        }
        
        repoManager.updateCallStatusInFirebase(friendUid: friendUid, hasIncomingCallRequest: true, isBusy: true)
        await liveKitManager.connect(roomName: roomName)
    }
    
    func disconnect() {
        guard let friendUid = selectedFriend?.id else {
            NSLog("Friend is not selected")
            return
        }

        Task {
            await liveKitManager.disconnect()
            repoManager.updateCallStatusInFirebase(friendUid: friendUid, hasIncomingCallRequest: false, isBusy: false)
        }
    }
    
    func publishAudio() {
        Task {
            await liveKitManager.publishAudio()
        }
    }
    
    func unpublishAudio() async {
        await liveKitManager.unpublishAudio()
    }
}

extension HomeViewModel {
    func fetchUser(id: String) {
        Task {
            do {
                try await repoManager.fetchUser(id: id)
            } catch {
                NSLog("LOG: Failed to fetch user when onAppear: \(error.localizedDescription)")
            }
        }
    }
}

extension HomeViewModel {
    func selectFriend(friend: FriendRecord) {
        DispatchQueue.main.async {
            self.repoManager.selectedFriend = friend
        }
    }
    
    func addFriend() {
        Task {
            await repoManager.addFriend(friendPin: friendPin)
            DispatchQueue.main.async {
                self.friendPin = "" 
            }
        }
    }
}

extension HomeViewModel {
    func signOut() {
        NSLog("LOG: signOut")
        DispatchQueue.main.async {
            self.repoManager.userRecord = nil
            self.repoManager.detailedFriends = []
        }
        authManager.signOut()
    }
}

extension HomeViewModel {
    func handleScenePhaseChange(to newScenePhase: ScenePhase) {
        switch newScenePhase {

        case .active:
             NSLog("LOG: App is active and in the foreground")
            backgroundTaskManager.stopAudioTask()

        case .inactive:
            NSLog("LOG: App is inactive")

        case .background:
            NSLog("LOG: App is in the background")
            audioSessionManager.setupAudioPlayer()
            backgroundTaskManager.startAudioTask()

        @unknown default:
            break
        }
    }
}
