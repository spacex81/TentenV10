//import Foundation
//
//class UpdateCurrentSpeakerQueue {
//    private var tasks: [() -> Void] = [] {
//        didSet {
////            NSLog("LOG: Tasks count: \(tasks.count)")
//        }
//    }
//    private var isRunning = false
//
//    static let shared = UpdateCurrentSpeakerQueue()
//
//    private init() {}
//
//    func addTask(_ task: @escaping () -> Void) {
//        tasks.append(task)
//        runNext()
//    }
//
//    private func runNext() {
//        // Check again to ensure tasks is not empty before accessing it
//        guard !isRunning, !tasks.isEmpty else { return }
//
//        isRunning = true
//        // Safely access and remove the first task
//        if let task = tasks.first {
//            tasks.removeFirst()
//            task()
//        } else {
//            // If for any reason tasks is empty at this point, mark isRunning as false
//            isRunning = false
//        }
//    }
//
//    func taskCompleted() {
//        isRunning = false
//        runNext()
//    }
//}

import Foundation

class UpdateCurrentSpeakerQueue {
    private var tasks: [() -> Void] = []
    private var isRunning = false
    private let queue = DispatchQueue(label: "com.updateCurrentSpeaker.queue")

    static let shared = UpdateCurrentSpeakerQueue()

    private init() {}

    func addTask(_ task: @escaping () -> Void) {
        queue.async {
            self.tasks.append(task)
            self.runNext()
        }
    }

    private func runNext() {
        queue.async {
            // Check again to ensure tasks is not empty before accessing it
            guard !self.isRunning, !self.tasks.isEmpty else { return }

            self.isRunning = true
            let task = self.tasks.removeFirst()
            task()
        }
    }

    func taskCompleted() {
        queue.async {
            self.isRunning = false
            self.runNext()
        }
    }
}
