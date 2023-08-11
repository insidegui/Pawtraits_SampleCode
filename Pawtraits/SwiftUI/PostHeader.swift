import SwiftUI

struct PostHeader: View {
    var post: PawtraitsPost

    var body: some View {
        HStack {
            Avatar(
                image: post.author.avatar,
                size: 46
            )

            VStack(alignment: .leading, spacing: 0) {
                Text(post.author.name)
                    .font(.headline)
                Text("@" + post.author.username)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Menu {
                Button("Option 1") { }
                Button("Option 2") { }
            } label: {
                Image(systemName: "ellipsis")
                    .frame(height: 22)
            }
            .contentShape(Rectangle())
            .tint(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    PostHeader(post: .preview)
        .padding()
}
