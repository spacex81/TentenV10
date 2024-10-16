import Foundation
import AVFAudio
import UIKit

class BackgroundTaskManager: ObservableObject {
    static let shared = BackgroundTaskManager()
    
    private let audioSessionManager = AudioSessionManager.shared
    private let liveKitManager = LiveKitManager.shared

    var liveKitTaskId: UIBackgroundTaskIdentifier = .invalid
    var audioTaskId: UIBackgroundTaskIdentifier = .invalid
    
    var isBackgroundAudioTaskRunning = false
}

// MARK: test audio background task
extension BackgroundTaskManager {
    func startAudioTask() {
//        NSLog("LOG: Starting background audio task")
        NSLog("LOG: BackgroundTaskManager-startAudioTask")
        endAudioTask()
        
        audioTaskId = UIApplication.shared.beginBackgroundTask(withName: "AudioTask") {
            self.endAudioTask()
        }
        
        guard audioTaskId != .invalid else {
            NSLog("LOG: Failed to start audio background task")
            return
        }
        
        isBackgroundAudioTaskRunning = true
        DispatchQueue.global(qos: .background).async {
            self.handleAudioTask()
        }
    }
    
    func endAudioTask() {
        isBackgroundAudioTaskRunning = false
//        NSLog("LOG: Ending background audio task")
        if audioTaskId != .invalid {
            UIApplication.shared.endBackgroundTask(audioTaskId)
            audioTaskId = .invalid
        }
    }
    
    func stopAudioTask() {
        audioSessionManager.stopTestAudio()
        endAudioTask()
    }
    
    func handleAudioTask() {
//        NSLog("LOG: BackgroundTaskManager-handleAudioTask: start")
        
        audioSessionManager.playTestAudio()
        
//        for i in 1...30 {
        for i in 1...5 {
            if !isBackgroundAudioTaskRunning {
                break
            }
            if let player = audioSessionManager.audioPlayer, player.isPlaying {
                NSLog("LOG: Playing silent audio(\(i))...")
            }
            sleep(1)
        }

        audioSessionManager.stopTestAudio()
        
        if isBackgroundAudioTaskRunning {
            startAudioTask()
        }
//        NSLog("LOG: BackgroundTaskManager-handleAudioTask: end")
    }

}
