import SwiftUI

struct DeferredLoadingIndicatorModifier: ViewModifier {
    var isLoading = false
    var maxDelayMS: Int

    @State private var loadingIndicatorVisible = false

    @State private var deferredTask: Task<Void, Never>?

    func body(content: Content) -> some View {
        content
            .opacity(loadingIndicatorVisible ? 0 : 1)
            .overlay {
                if loadingIndicatorVisible { ProgressView() }
            }
            .onChange(of: isLoading, initial: true) { oldValue, newValue in
                deferredTask?.cancel()

                guard newValue else {
                    loadingIndicatorVisible = false
                    return
                }

                deferredTask = Task {
                    try? await Task.sleep(for: .milliseconds(maxDelayMS))

                    guard !Task.isCancelled else { return }

                    if newValue {
                        loadingIndicatorVisible = true
                    }
                }
            }
            .animation(.easeInOut, value: loadingIndicatorVisible)
    }
}

extension View {
    func deferredLoadingIndicator(_ isLoading: Bool, maxDelayMS: Int = 300) -> some View {
        modifier(DeferredLoadingIndicatorModifier(isLoading: isLoading, maxDelayMS: maxDelayMS))
    }
}

#if DEBUG
struct DeferredLoadingIndicatorTest: View {
    @State private var isLoadingQuick = false
    @State private var isLoadingSlow = false

    @State private var quickDone = false
    @State private var slowDone = false

    var body: some View {
        VStack(spacing: 32) {
            Button {
                Task {
                    isLoadingQuick = true
                    try? await Task.sleep(for: .milliseconds(130))
                    isLoadingQuick = false
                    quickDone.toggle()
                }
            } label: {
                HStack {
                    Text("130ms")
                    if quickDone {
                        Text("✅")
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .deferredLoadingIndicator(isLoadingQuick)
            .animation(.bouncy, value: quickDone)

            Button {
                Task {
                    isLoadingSlow = true
                    try? await Task.sleep(for: .milliseconds(960))
                    isLoadingSlow = false
                    slowDone.toggle()
                }
            } label: {
                HStack {
                    Text("960ms")
                    if slowDone {
                        Text("✅")
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .deferredLoadingIndicator(isLoadingSlow)
            .animation(.bouncy, value: slowDone)
        }
        .font(.largeTitle)
    }
}

#Preview {
    DeferredLoadingIndicatorTest()
}
#endif
