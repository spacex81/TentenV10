import Foundation

class ReceivedInvitationsTaskQueue {
    private var tasks: [() -> Void] = [] {
        didSet {
//            NSLog("LOG: Tasks count: \(tasks.count)")
        }
    }
    private var isRunning = false

    static let shared = ReceivedInvitationsTaskQueue()

    private init() {}

    func addTask(_ task: @escaping () -> Void) {
        tasks.append(task)
        runNext()
    }

    private func runNext() {
        guard !isRunning, !tasks.isEmpty else { return }

        isRunning = true
        let task = tasks.removeFirst()
        task()
    }

    func taskCompleted() {
        isRunning = false
        runNext()
    }
}
