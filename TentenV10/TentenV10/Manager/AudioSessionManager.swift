import Foundation
import AVFoundation
import UIKit
import LiveKit
import WebRTC

// the name 'AudioManager' conflicts with 'LiveKit AudioManager'
class AudioSessionManager: ObservableObject {
    static let shared = AudioSessionManager()
    
    let repoManager = RepositoryManager.shared
    let liveKitManager = LiveKitManager.shared
    
    var isPlayingTestAudio: Bool = false {
        didSet {
//            NSLog("LOG: AudioSessionManager-isPlayingTestAudio: \(isPlayingTestAudio)")
        }
    }
    
    var audioPlayer: AVAudioPlayer?
    
    init() {
        AudioManager.shared.customConfigureAudioSessionFunc = customConfig
        setupAudioRouteChangeNotification()
    }
    
    private func setupAudioRouteChangeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleAudioRouteChange(_:)), name: AVAudioSession.routeChangeNotification, object: nil)
    }
}

// MARK: Configure Audio Session
extension AudioSessionManager {
    func customConfig(newState: AudioManager.State, oldState: AudioManager.State) {
        DispatchQueue.liveKit.async { [weak self] in
            guard let self else { return }
            
            let configuration = RTCAudioSessionConfiguration.webRTC()
            var setActive: Bool?
            
            if newState.trackState != .none, oldState.trackState == .none {
                setActive = true
            } else if newState.trackState == .none, oldState.trackState != .none {
                setActive = false
            }

            let session = RTCAudioSession.sharedInstance()
            session.lockForConfiguration()
            defer { session.unlockForConfiguration() }

            do {
                let optionsString = printAudioSessionOptions(options: configuration.categoryOptions)

//                NSLog("LOG: configuring audio session category: \(configuration.category), mode: \(configuration.mode), options: [\(optionsString)], setActive: \(String(describing: setActive))")
                if let setActive {
                    try session.setConfiguration(configuration, active: setActive)
//                    NSLog("LOG: Succeed to \(setActive ? "activate" : "deactivate") audio session")
                } else {
                    try session.setConfiguration(configuration)
//                    NSLog("LOG: Succeed to configure audio session")
                }
            } catch {
                NSLog("LOG: Failed to configure audio session on customConfig")
            }

        }
    }
    
    func getAudioSessionType() -> String {
        NSLog("LOG: AudioSessionManager-setupAudioSessionByCase")
        
        if repoManager.userRecord?.status == "foreground" {
            return "foreground"
        } else {
            if liveKitManager.isConnected {
                return "backgroundLiveKit"
            } else {
                return "backgroundIdle"
            }
        }
    }

    
    @objc private func handleAudioRouteChange(_ notification: Notification) {
        NSLog("LOG: AudioSessionManager-handleAudioRouteChange")
        
        let sessionType = getAudioSessionType()
        NSLog("LOG: sessionType: \(sessionType)")
        
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }

        switch reason {
        case .newDeviceAvailable, .oldDeviceUnavailable, .categoryChange:
//            NSLog("LOG: Route Change -  Category Change")
            
            let audioSession = AVAudioSession.sharedInstance()
//            NSLog("LOG: AudioSession mode: \(audioSession.mode.rawValue)")
            
            if audioSession.mode == .voiceChat {
//                NSLog("LOG: AudioSession mode is .voiceChat")
                do {
//                    if sessionType == "backgroundLiveKit" || sessionType == "foreground" {
//                        try audioSession.setMode(.videoChat)
//                        try audioSession.setCategory(audioSession.category, options: [.mixWithOthers])
//                    } else {
//                        // audioSession setup for background silent audio
//                    }
                    if sessionType == "backgroundLiveKit" || sessionType == "foreground" {
                        // Set the mode and category for LiveKit or real-time communication
                        try audioSession.setMode(.videoChat)
                        try audioSession.setCategory(audioSession.category, options: [.mixWithOthers, .allowBluetooth, .allowBluetoothA2DP, .defaultToSpeaker])
                    } else if sessionType == "backgroundIdle" {
                        // Set a more passive audio session for background silent audio
                        try audioSession.setMode(.default)
                        try audioSession.setCategory(.playback, options: [.mixWithOthers, .allowBluetoothA2DP, .allowBluetooth])
                    }
                    
                    audioSessionLog()
                } catch {
                    NSLog("LOG: Failed to change audio session from voiceChat to videoChat")
                }
            } else {
//                NSLog("LOG: Unhandled cases in route change - category change")
            }
//        case .routeConfigurationChange:
//            NSLog("LOG: Route Change - Configuration Change")
        default:
            break
        }
    }
}

// MARK: AVAudioSession Log
extension AudioSessionManager {
    func audioSessionLog() {
        let audioSession = AVAudioSession.sharedInstance()
        
        let optionsString = printAudioSessionOptions(options: audioSession.categoryOptions)

        NSLog("LOG: Audio session configuration")
        NSLog("LOG: Category: \(audioSession.category)")
        NSLog("LOG: Mode:     \(audioSession.mode)")
        NSLog("LOG: Options:  \(optionsString)")
    }
}

// MARK: Audio Player
extension AudioSessionManager {
    func setupAudioPlayer() {
        NSLog("LOG: Setting up audio player for silent audio")
        guard let audioPath = Bundle.main.path(forResource: "test", ofType: "wav") else {
            NSLog("Failed to find the audio file")
            return
        }
        let audioUrl = URL(fileURLWithPath: audioPath)
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioUrl)
            audioPlayer?.numberOfLoops = -1 // Loop indefinitely
        } catch {
            NSLog("Failed to initialize audio player: %{public}@")
        }
    }
    
    func playTestAudio() {
        NSLog("LOG: AudioSessionManager-playTestAudio()")
        if let player = audioPlayer, player.prepareToPlay() {
            NSLog("LOG: Start playing test audio")
            isPlayingTestAudio = true
            player.play()
        } else {
            NSLog("LOG: Failed to prepare audio player for playing")
        }
    }

    func stopTestAudio() {
//        NSLog("LOG: Stop playing test audio")
        isPlayingTestAudio = false
        audioPlayer?.stop()
    }
}

// MARK: Logging
extension AudioSessionManager {
    func logAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        
        NSLog("LOG: audio session category: \(audioSession.category.rawValue), mode: \(audioSession.mode.rawValue), options: \(audioSessionCategoryOptionsToString(audioSession.categoryOptions))")
    }
    
    func audioSessionCategoryOptionsToString(_ options: AVAudioSession.CategoryOptions) -> String {
        var optionsString = [String]()
        
        if options.contains(.mixWithOthers) {
            optionsString.append("Mix With Others")
        }
        if options.contains(.duckOthers) {
            optionsString.append("Duck Others")
        }
        if options.contains(.allowBluetooth) {
            optionsString.append("Allow Bluetooth")
        }
        if options.contains(.defaultToSpeaker) {
            optionsString.append("Default To Speaker")
        }
        if options.contains(.interruptSpokenAudioAndMixWithOthers) {
            optionsString.append("Interrupt Spoken Audio And Mix With Others")
        }
        if options.contains(.allowBluetoothA2DP) {
            optionsString.append("Allow Bluetooth A2DP")
        }
        if options.contains(.allowAirPlay) {
            optionsString.append("Allow AirPlay")
        }
        
        return optionsString.joined(separator: ", ")
    }
    
    private func printReasonDescription(for reason: AVAudioSession.RouteChangeReason) {
        let reasonDescription: String
        switch reason {
        case .newDeviceAvailable:
            reasonDescription = "New device available"
        case .oldDeviceUnavailable:
            reasonDescription = "Old device unavailable"
        case .categoryChange:
            reasonDescription = "Category change"
        case .override:
            reasonDescription = "Override"
        case .wakeFromSleep:
            reasonDescription = "Wake from sleep"
        case .noSuitableRouteForCategory:
            reasonDescription = "No suitable route for category"
        case .routeConfigurationChange:
            reasonDescription = "Route configuration change"
        case .unknown:
            reasonDescription = "Unknown reason"
        @unknown default:
            reasonDescription = "Unknown reason"
        }
        
        NSLog("LOG: Audio route change reason description: \(reasonDescription)")
    }

    private func printAudioSessionOptions(options: AVAudioSession.CategoryOptions) -> String {
        var optionsArray: [String] = []
        
        if options.contains(.mixWithOthers) {
            optionsArray.append("mixWithOthers")
        }
        if options.contains(.duckOthers) {
            optionsArray.append("duckOthers")
        }
        if options.contains(.allowBluetooth) {
            optionsArray.append("allowBluetooth")
        }
        if options.contains(.defaultToSpeaker) {
            optionsArray.append("defaultToSpeaker")
        }
        if options.contains(.interruptSpokenAudioAndMixWithOthers) {
            optionsArray.append("interruptSpokenAudioAndMixWithOthers")
        }
        if options.contains(.allowBluetoothA2DP) {
            optionsArray.append("allowBluetoothA2DP")
        }
        if options.contains(.allowAirPlay) {
            optionsArray.append("allowAirPlay")
        }
        
        let optionsString = optionsArray.joined(separator: ", ")
        return optionsString
    }
}

extension DispatchQueue {
    static let liveKit = DispatchQueue(label: "tech.komaki.liveKit")
}
