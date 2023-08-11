import SwiftUI

struct PostThumbnail: View {
    var post: PawtraitsPost

    var size: CGSize = .init(width: 32, height: 32) //

    var body: some View {
        RemoteImageView(url: post.thumbnailURL) { uiImage in
            Image(uiImage: uiImage)
                .resizable()
        } placeholder: {
            ZStack {
                if let blurHash = post.blurHash,
                   let uiImage = UIImage(blurHash: blurHash, size: size)
                {
                    Image(uiImage: uiImage)
                        .resizable()
                } else {
                    Rectangle()
                        .foregroundStyle(.quaternary)
                }
            }
        }
        .aspectRatio(contentMode: .fill)
        .frame(height: 400)
        .containerRelativeFrame(.horizontal, count: 1, spacing: 0)
        .clipped()
        .id(post.id)
    }
}

#Preview("PostThumbnail") {
    PostThumbnail(post: .preview)
        .frame(height: 400)
        .environment(PawtraitsAPIClient())
}
