import SwiftUI

extension View {
    func placeholder(_ isPlaceholder: Bool = true) -> some View {
        modifier(PlaceholderHelperModifier(isPlaceholder: isPlaceholder))
    }
}

private struct PlaceholderHelperModifier: ViewModifier {
    var isPlaceholder: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        content
            .redacted(reason: isPlaceholder ? .placeholder : [])
            .disabled(isPlaceholder)
    }
}
