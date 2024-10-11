import Foundation

class ReceivedInvitationsTaskQueue {
    private var tasks: [() -> Void] = []
    private var isRunning = false
    private let queue = DispatchQueue(label: "com.receivedInvitationsTask.queue")

    static let shared = ReceivedInvitationsTaskQueue()

    private init() {}

    func addTask(_ task: @escaping () -> Void) {
        queue.async {
            self.tasks.append(task)
            self.runNext()
        }
    }

    private func runNext() {
        queue.async {
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
