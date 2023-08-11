import SwiftUI

struct PostView: View {
    var post: PawtraitsPost
    var showActions = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            PostHeader(post: post)
                .padding(.horizontal)
            PostThumbnail(post: post)
                .opacity(post.isPlaceholder ? 0.5 : 1)
            if showActions {
                PostActions(post: post)
                    .padding(.horizontal)
            }
            PostDescription(post: post)
                .padding(.horizontal)
        }
        .placeholder(post.isPlaceholder)
    }
}

struct PostDescription: View {
    var post: PawtraitsPost

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let description = post.description {
                Text(post.author.username).font(.body.weight(.medium)) +
                Text(" " + description)
                    .font(.body)
            }

            HStack(spacing: 6) {
                Text(post.createdAt, format: .relative(presentation: .named))

                Text("·")

                if post.numberOfComments > 0 {
                    Text("^[\(post.numberOfComments) comment](inflect: true)")
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }
}

struct PostActions: View {
    @Environment(PawtraitsAPIClient.self)
    private var api

    var post: PawtraitsPost
    @State private var isLoading = false
    @State private var isLiked = false

    private var fillHeart: Bool { isLiked || post.isLiked }

    var body: some View {
        HStack(spacing: 16) {
            Group {
                Button {
                    toggleLike()
                } label: {
                    Group {
                        if fillHeart {
                            Image(systemName: "heart.fill")
                        } else {
                            Image(systemName: "heart")
                        }
                    }
                    .transition(
                        .scale
                        .animation(.interpolatingSpring(bounce: isLiked ? 0.6 : 0.1))
                        .combined(
                            with: .opacity
                                  .animation(.spring(duration: 0.3, bounce: 0))
                        )
                    )
                    .deferredLoadingIndicator(isLoading, maxDelayMS: 1000)
                }

                Button {

                } label: {
                    Image(systemName: "bubble.right")
                        .resizable()
                }

                Button {

                } label: {
                    Image(systemName: "paperplane")
                        .resizable()
                }

                Spacer()

                Button {

                } label: {
                    Image(systemName: "bookmark")
                        .resizable()
                }
            }
            .aspectRatio(contentMode: .fit)
            .frame(height: 22) //
        }
        .font(.system(size: 24, design: .rounded))
        .tint(.primary)
        .buttonStyle(.plain)
    }

    @State private var likeTask: Task<Void, Never>?

    private static let haptics = UIImpactFeedbackGenerator(style: .medium)

    func toggleLike() {
        likeTask?.cancel()

        isLoading = true

        Self.haptics.impactOccurred(intensity: isLiked ? 1 : 0.4)

        isLiked = post.isLiked ? false : true

        likeTask = Task {
            if post.isLiked {
                try? await api.removeLike(for: post)
            } else {
                try? await api.addLike(for: post)
            }

            isLoading = false
        }
    }
}

#Preview("PostView") {
    PostView(post: PawtraitsAPIClient.previewPost(at: 0))
        .environment(PawtraitsAPIClient())
}

#Preview("Placeholder") {
    PostView(post: .placeholder())
        .environment(PawtraitsAPIClient())
}
