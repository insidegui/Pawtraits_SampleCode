import SwiftUI

struct PostDetailsScreen: View {
    @State var post: PawtraitsPost

    @Environment(PawtraitsAPIClient.self)
    private var api

    var body: some View {
        PostDetailsView(post: post, comments: post.comments ?? post.commentPlaceholders)
        .task(id: post.id) {
            guard post.comments == nil else { return }
            if let updatedPost = try? await api.fetchDetails(for: post) {
                self.post = updatedPost
            }
        }
        .navigationTitle(Text("\(post.author.name)’s Post"))
    }
}

struct PostDetailsView: View {
    var post: PawtraitsPost
    var comments: [PawtraitsComment]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 22) {
                PostView(post: post)
                PostCommentsView(post: post, comments: comments)
            }
        }
    }
}

struct PostCommentsView: View {
    var post: PawtraitsPost
    var comments: [PawtraitsComment]
    var avatarSize: CGFloat = 28

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 22) {
            ForEach(comments.indices, id: \.self) { i in
                let comment = comments[i]
                CommentView(comment: comment, avatarSize: avatarSize)
            }
        }
        .padding(.horizontal)
    }
}

struct CommentView: View {
    var comment: PawtraitsComment
    var avatarSize: CGFloat = 28

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Avatar(image: comment.avatar, size: avatarSize)
                .offset(y: 2)
            VStack(alignment: .leading, spacing: 2) {
                Text(comment.username)
                    .font(.caption.weight(.medium))
                    .textCase(.lowercase)
                Text(comment.text)
                    .font(.subheadline)
            }
        }
        .placeholder(comment.isPlaceholder)
    }
}

#Preview("PostDetailsScreen") {
    PostDetailsScreen(post: .preview)
        .environment(PawtraitsAPIClient())
}

#Preview("PostDetailsView") {
    PostDetailsView(post: .preview, comments: PawtraitsComment.previewComments)
        .environment(PawtraitsAPIClient())
}
