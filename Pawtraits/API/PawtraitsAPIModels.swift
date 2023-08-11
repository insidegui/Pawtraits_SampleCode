import SwiftUI

protocol UsernameHolder {
    var username: String { get }
    var avatar: Image { get }
}

struct PawtraitsProfile: Identifiable, Hashable, Codable, UsernameHolder {
    var id: String
    var name: String
    var username: String
}

struct PawtraitsPost: Identifiable, Hashable, Codable {
    var id: String
    var createdAt: Date
    var imageName: String
    var thumbnailName: String
    var description: String?
    var blurHash: String?
    var imageSize: CGSize
    var thumbnailSize: CGSize
    var author: PawtraitsProfile
    @DecodableDefault.Zero
    var numberOfComments: Int
    @DecodableDefault.False
    var isLiked = false
    var comments: [PawtraitsComment]? = nil
}

struct PawtraitsComment: Identifiable, Hashable, Codable, UsernameHolder {
    var id: String
    var username: String
    var text: String
}

struct PawtraitsPostsResponse: Codable {
    var posts: [PawtraitsPost]
}

struct PawtraitsPostDetailsResponse: Codable {
    var comments: [PawtraitsComment]
}

extension UsernameHolder {
    var avatar: Image {
        if let url = try? Bundle.main.contentURL("\(username).heic"),
           let image = UIImage(contentsOfFile: url.path)
        {
            return Image(uiImage: image)
        } else {
            return Image(systemName: "pawprint.fill")
        }
    }
}

extension PawtraitsPostsResponse {
    func updatePosts(_ closure: (inout PawtraitsPost) -> Void) -> Self {
        var mSelf = self
        mSelf.posts = posts.map { post in
            var mPost = post
            closure(&mPost)
            return mPost
        }
        return mSelf
    }
}

extension CGSize: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(width)
        hasher.combine(height)
    }
}

extension PawtraitsProfile {
    static let `default` = PawtraitsProfile(id: "yoshi", name: "Yoshi", username: "yoshi")
}

extension Identifiable where ID == String {
    private static var placeholderIDPrefix: String { "__PLACEHOLDER-" }

    static func placeholderID() -> String { Self.placeholderIDPrefix + UUID().uuidString }

    var isPlaceholder: Bool { id.hasPrefix(Self.placeholderIDPrefix) }
}

extension PawtraitsProfile {
    static func placeholder() -> Self {
        PawtraitsProfile(
            id: Self.placeholderID(),
            name: .random(4...12),
            username: .random(4...12)
        )
    }
}

extension PawtraitsComment {
    static func placeholder() -> Self {
        PawtraitsComment(
            id: Self.placeholderID(),
            username: .random(4...12),
            text: .random(8...120)
        )
    }

    static func placeholders(_ count: Int) -> [Self] {
        (0..<count).map { _ in Self.placeholder() }
    }
}

extension PawtraitsPost {
    static func placeholder() -> Self {
        PawtraitsPost(
            id: Self.placeholderID(),
            createdAt: .now,
            imageName: "placeholder",
            thumbnailName: "placeholder",
            description: .random(10...80),
            blurHash: nil,
            imageSize: CGSize(width: 640, height: 640),
            thumbnailSize: CGSize(width: 320, height: 320),
            author: .placeholder(),
            numberOfComments: .init(wrappedValue: Int.random(in: 0...500)),
            isLiked: false
        )
    }
    
    static let placeholders: [Self] = {
        (0..<10).map { _ in Self.placeholder() }
    }()
}

extension PawtraitsPost {
    var commentPlaceholders: [PawtraitsComment] {
        guard numberOfComments > 0 else { return [] }
        return PawtraitsComment.placeholders(numberOfComments)
    }
}

private extension String {
    static func random(_ range: ClosedRange<Int>) -> String {
        let length = Int.random(in: range)
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map { _ in letters.randomElement()! })
    }
}
