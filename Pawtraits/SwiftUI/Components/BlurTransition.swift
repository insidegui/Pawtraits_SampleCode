import SwiftUI

public extension AnyTransition {
    static var blur: AnyTransition { blur(radius: 6) }

    static func blur(radius: CGFloat) -> AnyTransition {
        .modifier(active: BlurTransitionModifier(radius: radius), identity: BlurTransitionModifier(identity: true, radius: radius))
    }
}

private struct BlurTransitionModifier: ViewModifier {
    var identity: Bool = false
    var radius: CGFloat

    func body(content: Content) -> some View {
        content
            .blur(radius: identity ? 0 : radius)
            .opacity(identity ? 1 : 0)
    }
}
