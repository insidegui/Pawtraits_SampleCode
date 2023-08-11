import UIKit

class DeferredNavigationController: UINavigationController {
    private var timeoutTask: Task<Void, Never>?
    private var loadTask: Task<Void, Never>?

    func push<V>(value: V,
                 maxDelayMS: Int = 150,
                 load: @escaping (V) async throws -> V,
                 controller: @escaping (V) -> UIViewController) where V: Identifiable & Hashable
    {
        timeoutTask?.cancel()
        loadTask?.cancel()

        @MainActor
        func push(_ value: V) {
            timeoutTask?.cancel()

            guard !Task.isCancelled else { return }

            pushViewController(controller(value), animated: true)
        }

        timeoutTask = Task {
            try? await Task.sleep(for: .milliseconds(maxDelayMS))

            guard !Task.isCancelled else { return }

            push(value)
        }

        loadTask = Task {
            do {
                let updatedValue = try await load(value)

                push(updatedValue)
            } catch {
                guard !error.isDeferredNavigationCancellation else {
                    timeoutTask?.cancel()
                    return
                }

                push(value)
            }
        }
    }
}

extension UIViewController {
    var deferredNavigation: DeferredNavigationController? {
        navigationController as? DeferredNavigationController
    }
}
