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
    
    weak var collectionViewController: CustomCollectionViewController?

    
    // MARK: Used to manage LiveKit connect/disconnect whis isPressing value changes
    private var connectTask: Task<Void, Never>?
    
    @Published var currentUser: User?
    @Published var userRecord: UserRecord? {
        didSet {
            guard let userRecord = userRecord else {
                return
            }
            
            
            if userRecord.username == "default" || userRecord.profileImageData == nil || userRecord.friends.isEmpty {
                authManager.isOnboardingComplete = false
            }
        }
    }

    // MARK: Onboarding
    // When username and profile image is set in onboarding phase, set that value is userRecord
    @Published var username: String = "" {
        didSet {
            userRecord?.username = username
        }
    }
    @Published var profileImageData: Data? 
    {
        didSet {
            NSLog("LOG: profileImageData-didSet")
            userRecord?.profileImageData = profileImageData
        }
    }
    @Published var imageOffset: Float = 0.0 
    {
        didSet {
            // print("HomeViewModel-imageOffset-didSet: \(imageOffset)")
            userRecord?.imageOffset = Float(imageOffset)
        }
    }
    //
    
    @Published var selectedFriendIsBusy: Bool = false {
        didSet {
//            NSLog("LOG: HomeViewModel-selectedFriendIsBusy: \(selectedFriendIsBusy)")
        }
    }
    @Published var currentState: UserState = .idle
    
    @Published var isPressing: Bool = false {
        didSet {
            handlePressingStateChange()
        }
    }
    
    @Published var selectedFriend: FriendRecord? {
        didSet {
//            NSLog("LOG: HomeViewModel-selectedFriend: ")
//            if let selectedFriend = selectedFriend {
//                print(selectedFriend)
//            }
            
            updateSelectedFriendIsBusy()
        }
    }
    @Published var detailedFriends: [FriendRecord] = [] {
        didSet {
//            NSLog("LOG: HomeViewModel-detailedFriends: ")
//            print(detailedFriends)
            
//            updateSelectedFriendIsBusy()
        }
    }
    

    @Published var needUserFetch: Bool = true
    
    
    @Published var isConnected: Bool = false
    @Published var isPublished: Bool = false
    @Published var isLocked: Bool = false {
        didSet {
//            NSLog("LOG: HomeViewModel-isLocked: \(isLocked)")
        }
    }
    @Published var progress: Float = 0.0
    
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
        
        liveKitManager.$isLocked
            .receive(on: DispatchQueue.main)
            .assign(to: &$isLocked)
        
        liveKitManager.$isPressing
            .receive(on: DispatchQueue.main)
            .assign(to: &$isPressing)
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
        
        repoManager.$currentState
            .receive(on: DispatchQueue.main)
            .sink {  currentState in
                self.currentState = currentState
            }
            .store(in: &cancellables)
    }
    
    private func updateSelectedFriendIsBusy() {
//        NSLog("LOG: updateSelectedFriendIsBusy")
        // Check if there's a selected friend
        guard let selectedFriend = selectedFriend else {
            selectedFriendIsBusy = false
            return
        }
        
//        NSLog("LOG: currentSpeakerId: \(repoManager.currentSpeakerId ?? "nil")")
//        NSLog("LOG: selectedFriendId: \(selectedFriend.id)")
//        NSLog("LOG: selectedFriendIsBusy: \(selectedFriend.isBusy)")
        
        let currentSpeakerIsSelected = repoManager.currentSpeakerId == selectedFriend.id
        // currentSpeakerIsMe
        
        if selectedFriend.isBusy && !currentSpeakerIsSelected {
            selectedFriendIsBusy = true
        } else {
            selectedFriendIsBusy = false
        }
    }
}

// MARK: Handle isPressing state change
extension HomeViewModel {
    private func handlePressingStateChange() {
        if isPressing {
            startConnection()
        } else {
            if !isLocked {
                stopConnection()
            }
        }
    }
    
    private func startConnection() {
        // Cancel any existing connection attempt before starting a new one
        connectTask?.cancel()
        connectTask = Task {
            if !isConnected {
                await connect()
            }
            await liveKitManager.publishAudio()
        }
    }
    
    private func stopConnection() {
        // Cancel any ongoing connection task
        connectTask?.cancel()
        connectTask = nil
        
        Task {
            await liveKitManager.unpublishAudio()
            disconnect()
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

// MARK: Friend
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
    
    func inviteFriend() {
        Task {
            await repoManager.inviteFriend(friendPin: friendPin)
            DispatchQueue.main.async {
                self.friendPin = ""
            }
        }
    }
}

// MARK: Onboarding
extension HomeViewModel {
    func addUsername() {
        
    }
    
    func addProfileImage() {
        
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
//             NSLog("LOG: App is active and in the foreground")
            backgroundTaskManager.stopAudioTask()

        case .inactive:
            NSLog("LOG: App is inactive")

        case .background:
//            NSLog("LOG: App is in the background")
            audioSessionManager.setupAudioPlayer()
            backgroundTaskManager.startAudioTask()

        @unknown default:
            break
        }
    }
}
