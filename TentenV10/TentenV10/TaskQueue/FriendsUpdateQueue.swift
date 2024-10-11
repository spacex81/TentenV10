import Foundation

class FriendsUpdateTaskQueue {
    private var tasks: [() -> Void] = [] {
        didSet {
//            NSLog("LOG: Tasks count: \(tasks.count)")
        }
    }
    private var isRunning = false

    static let shared = FriendsUpdateTaskQueue()

    private init() {}

    func addTask(_ task: @escaping () -> Void) {
        tasks.append(task)
        runNext()
    }

    private func runNext() {
        // Check again to ensure tasks is not empty before accessing it
        guard !isRunning, !tasks.isEmpty else { return }

        isRunning = true
        // Safely access and remove the first task
        if let task = tasks.first {
            tasks.removeFirst()
            task()
        } else {
            // If for any reason tasks is empty at this point, mark isRunning as false
            isRunning = false
        }
    }

    func taskCompleted() {
        isRunning = false
        runNext()
    }
}
