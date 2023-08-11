import SwiftUI

/// Throw this error from the load function in a `DeferredNavigationLink` to cancel navigation.
/// Any other type of error will cause the deferred navigation to proceed with the input value.
struct DeferredNavigationCancellationError: Error { }

extension Error {
    var isDeferredNavigationCancellation: Bool { self is DeferredNavigationCancellationError }
}

/// A navigation link that attempts to load asynchronous content for the destination view
/// before the view is pushed onto the navigation stack, in order to prevent flickering loading
/// states when content loads in a very small window of time.
struct DeferredNavigationLink<Label: View, Value: Identifiable & Hashable>: View {
    /// The value for the destination view.
    var value: Value
    /// The navigation path associated with the `NavigationStack` where the updated content will be pushed.
    @Binding var path: NavigationPath
    /// The maximum delay in milliseconds the link will wait before pushing the initial value and cancelling the asynchronous load.
    var maxDelayMS: Int = 150
    /// An asynchronous function that takes the input value and performs whatever actions are needed in order to fetch
    /// the updated value for the destination view, returning the updated value when done.
    /// If the function throws, the navigation link will push the input value.
    var load: (Value) async throws -> Value
    /// The label for the navigation link.
    @ViewBuilder var label: Label

    @State private var timeoutTask: Task<Void, Never>?
    @State private var loadTask: Task<Void, Never>?

    var body: some View {
        Button {
            /// This task waits for the specified delay in milliseconds,
            /// then pushes the value onto the navigation stack no matter what.
            /// This way, if a post takes too long to load, it'll push the post details
            /// screen, which will show a loading state. If the post loads quickly,
            /// there will be a very short delay between tapping the post and the details
            /// screen being pushed, but it'll be pushed in its final state.
            timeoutTask = Task {
                try? await Task.sleep(for: .milliseconds(maxDelayMS))

                /// Make sure we haven't been cancelled, which will happen if loading
                /// succeeded before the timeout, or if the navigation was cancelled because
                /// the user navigated to another screen before loading completed.
                guard !Task.isCancelled else { return }

                path.append(value)
            }

            /// This task actually calls the `load` closure in order to fetch
            /// the updated value before pushing it onto the navigation stack.
            /// It will push the initial value if loading the updated value fails,
            /// or the updated value if it was able to load it in a reasonable amount of time.
            loadTask = Task {
                await performAction()
            }
        } label: {
            label
        }
        .buttonStyle(.plain)
        .onChange(of: path) {
            timeoutTask?.cancel()
            loadTask?.cancel()
        }
        .onDisappear {
            guard timeoutTask?.isCancelled == false || loadTask?.isCancelled == false else { return }

            timeoutTask?.cancel()
            loadTask?.cancel()

            timeoutTask = nil
            loadTask = nil
        }
    }

    private func performAction() async {
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

    private func push(_ updatedValue: Value) {
        /// Cancel the timeout task, since we were able to load the updated value
        /// before the timeout interval was reached.
        timeoutTask?.cancel()
        
        /// Make sure the task has not been cancelled, which will happen if
        /// the navigation path changed before we got a response.
        /// This is to avoid pushing the view onto the navigation stack
        /// twice, or on top of some other content the user has navigated to.
        guard !Task.isCancelled else { return }

        /// Actually push the updated value onto the navigation stack, triggering navigation.
        path.append(updatedValue)
    }
}

private struct DeferredNavigationLinkTest: View {

    @State private var navigationPath = NavigationPath()

    struct Model: Identifiable, Hashable {
        var id: String
        var delayMS: Int
        var loadedBeforePush = false
    }

    var items: [Model] = [
        .init(id: "400ms", delayMS: 400),
        .init(id: "300ms", delayMS: 300),
        .init(id: "200ms", delayMS: 200),
        .init(id: "100ms", delayMS: 100),
    ]

    var body: some View {
        NavigationStack(path: $navigationPath) {
            List(items) { item in
                DeferredNavigationLink(value: item, path: $navigationPath, maxDelayMS: 210, load: load) {
                    Text(item.id)
                }
            }
            .navigationTitle("Deferred Navigation")
            .navigationDestination(for: Model.self) { model in
                DetailView(model: model)
            }
        }
    }

    private func load(_ model: Model) async throws -> Model {
        try await Task.sleep(for: .milliseconds(model.delayMS))
        guard !Task.isCancelled else { return model }
        var updatedModel = model
        updatedModel.loadedBeforePush = true
        return updatedModel
    }

    private struct DetailView: View {
        var model: Model

        var body: some View {
            VStack {
                Text(model.id)
                Text("Loaded before push? \(model.loadedBeforePush ? "YES" : "NO")")
            }
                .navigationTitle(Text(model.id))
        }
    }

}

#Preview("Deferred Navigation") {
    DeferredNavigationLinkTest()
}
