import SwiftUI
import Observation
import Combine

@Observable
final class PawtraitsAPIClient {

    private let postsSubject = PassthroughSubject<[PawtraitsPost], Never>()

    var postsPublisher: AnyPublisher<[PawtraitsPost], Never> { postsSubject.eraseToAnyPublisher() }

    private(set) var loadedPosts = [PawtraitsPost]() {
        didSet {
            DispatchQueue.main.async {
                self.postsSubject.send(self.loadedPosts)
            }
        }
    }

    var disableDelaysInPreviews = false

    private var disableDelays: Bool {
        guard disableDelaysInPreviews else { return false }
        return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }

    private func delay(for duration: ContinuousClock.Instant.Duration) async {
        guard !disableDelays else { return }
        try? await Task.sleep(for: duration)
    }

    private func randomDelay(minMS: Int, maxMS: Int) async {
        let interval = Int.random(in: minMS...maxMS)
        await delay(for: .milliseconds(interval))
    }

    func fetchPosts(page: Int) async throws {
        await delay(for: .seconds(1))

        updateLocalPosts()
    }

    private var fetchDetailsCallCount = 0

    @discardableResult
    func fetchDetails(for post: PawtraitsPost) async throws -> PawtraitsPost {
        guard post.comments == nil else { return post }

        /// Reduce load time by 100ms for each call to fetchDetails
        let delayInterval = max(0, 450 - fetchDetailsCallCount * 100)
        await delay(for: .milliseconds(delayInterval))
        fetchDetailsCallCount += 1

        let fileName = "details-\(post.id).json"

        let response: PawtraitsPostDetailsResponse = try Bundle.main.decodeContent(named: fileName)

        /// Update post on local storage with loaded comments.
        self.allPostsResponse = allPostsResponse.updatePosts { localPost in
            guard localPost.id == post.id else { return }
            localPost.comments = response.comments
        }
        self.loadedPosts = allPostsResponse.posts

        var updatedPost = post
        updatedPost.comments = response.comments

        return updatedPost
    }

    @ObservationIgnored
    private lazy var imageCache = NSCache<NSString, UIImage>()

    func cachedImage(for url: URL?) -> UIImage? {
        guard let url else { return nil }
        let cacheKey = url.absoluteString as NSString
        return imageCache.object(forKey: cacheKey)
    }

    func loadImage(from url: URL) async throws -> UIImage {
        let cacheKey = url.absoluteString as NSString
        if let cachedImage = imageCache.object(forKey: cacheKey) { return cachedImage }

        /// Simulate longer delay when loading full-size images to better replicate network request behavior.
        let isThumbnail = url.lastPathComponent.contains("thumbnail")
        await randomDelay(minMS: isThumbnail ? 200 : 400, maxMS: isThumbnail ? 1100 : 1600)

        let localURL = try Bundle.main.contentURL(url.lastPathComponent)

        guard let image = UIImage(contentsOfFile: localURL.path) else {
            throw CocoaError(.coderReadCorrupt, userInfo: [NSLocalizedDescriptionKey: "Failed to load image at \(localURL.path)"])
        }

        imageCache.setObject(image, forKey: cacheKey)

        return image
    }

    // MARK: Storage

    private var allPostsResponse: PawtraitsPostsResponse = {
        try! Bundle.main.decodeContent(named: "posts.json")
    }()

    private func updateLocalPosts() {
        allPostsResponse = allPostsResponse.updatePosts { post in
            post.isLiked = likedPosts.contains(post.id)
        }
        self.loadedPosts = allPostsResponse.posts
    }

    private let defaults = UserDefaults.standard

    private var likedPosts: Set<PawtraitsPost.ID> {
        get { Set(defaults.stringArray(forKey: #function) ?? []) }
        set {
            defaults.setValue(Array(newValue), forKey: #function)
            defaults.synchronize()

            updateLocalPosts()
        }
    }

    func addLike(for post: PawtraitsPost) async throws {
        await randomDelay(minMS: 300, maxMS: 1600)

        guard !Task.isCancelled else { return }

        likedPosts.insert(post.id)
    }

    func removeLike(for post: PawtraitsPost) async throws {
        await randomDelay(minMS: 300, maxMS: 1600)

        guard !Task.isCancelled else { return }

        likedPosts.remove(post.id)
    }
}

// NOTE: The image URLs are fake, they're just used to simulate a real-world app requesting resources from a server.
extension PawtraitsPost {
    var imageURL: URL {
        URL(string: "https://cdn.pawtraits.io/images/\(imageName)")!
    }

    var thumbnailURL: URL {
        URL(string: "https://cdn.pawtraits.io/images/\(thumbnailName)")!
    }
}

extension Bundle {
    func contentURL(_ fileName: String) throws -> URL {
        guard let url = url(forResource: fileName, withExtension: nil, subdirectory: "Content") else {
            throw CocoaError(.fileNoSuchFile, userInfo: [NSLocalizedDescriptionKey: "404: Not Found"])
        }
        return url
    }

    private static let jsonDecoder = JSONDecoder()

    func decodeContent<T: Decodable>(named fileName: String) throws -> T {
        let url = try contentURL(fileName)
        let data = try Data(contentsOf: url)
        return try Self.jsonDecoder.decode(T.self, from: data)
    }
}

// MARK: - Preview Helpers

extension PawtraitsAPIClient {
    static func previewPost(at index: Int = 0) -> PawtraitsPost {
        PawtraitsAPIClient().allPostsResponse.posts[index]
    }

    static func randomPost() -> PawtraitsPost {
        PawtraitsAPIClient().allPostsResponse.posts.shuffled()[0]
    }
}

extension PawtraitsPost {
    static let preview = PawtraitsAPIClient.previewPost()
    static let random = PawtraitsAPIClient.randomPost()
}

extension PawtraitsComment {
    static let previewComments: [PawtraitsComment] = {
        let response: PawtraitsPostDetailsResponse = try! Bundle.main.decodeContent(named: "details-IMG_2826.json")
        return response.comments
    }()
    static let preview: PawtraitsComment = {
        PawtraitsComment.previewComments[0]
    }()
}
