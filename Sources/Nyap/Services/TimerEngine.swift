import Foundation

@MainActor
final class TimerEngine {
    private var task: Task<Void, Never>?

    func start(onTick: @escaping @MainActor () -> Void) {
        stop()
        task = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                onTick()
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
    }
}
