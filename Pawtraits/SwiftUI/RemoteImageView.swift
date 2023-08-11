import SwiftUI

struct RemoteImageView<Content: View, Placeholder: View>: View {
    @Environment(PawtraitsAPIClient.self)
    private var api

    var url: URL?

    @ViewBuilder var content: (UIImage) -> Content
    @ViewBuilder var placeholder: () -> Placeholder

    @State private var image: UIImage?

    @State private var imageRevealed = true

    private var cachedImage: UIImage? { api.cachedImage(for: url) }

    @Environment(\.isEnabled)
    private var enabled

    var body: some View {
        ZStack {
            if enabled, let image = image ?? cachedImage {
                content(image)
                    .blur(radius: imageRevealed ? 0 : 24, opaque: true)
                    .task { imageRevealed = true }
            } else {
                placeholder()
                    .transition(.opacity)
            }
        }
        .task {
            guard let url, enabled else { return }

            /// If we already have a synchronously-loaded cached image, skip async call.
            guard cachedImage == nil else {
                /// We're not loading an image, ensure image revealed state is true to avoid blur animation.
                self.imageRevealed = true
                return
            }

            /// We're loading an image, set the revealed state to false to get the blur animation after loading.
            self.imageRevealed = false

            self.image = try? await api.loadImage(from: url)
        }
        .animation(.easeOut(duration: 0.3), value: image)
        .animation(.easeOut(duration: 0.3), value: imageRevealed)
        .id(url)
    }
}

#Preview {
    RemoteImageView(url: PawtraitsPost.preview.imageURL) { uiImage in
        Image(uiImage: uiImage)
            .resizable()
    } placeholder: {
        Rectangle()
            .foregroundStyle(.quaternary)
    }
    .aspectRatio(contentMode: .fit)
    .environment(PawtraitsAPIClient())
}
