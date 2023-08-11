import UIKit
import SwiftUI
import Combine

final class PostDetailViewController: PawtraitsBaseViewController, ObservableObject {

    @Published private(set) var post: PawtraitsPost

    init(client: PawtraitsAPIClient, post: PawtraitsPost) {
        self.post = post

        super.init(client: client)

        client
            .postsPublisher
            .compactMap
        {
            $0.first(where: { $0.id == post.id })
        }
        .assign(to: &$post)
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    private lazy var cancellables = Set<AnyCancellable>()

    private lazy var host: UIViewController = {
        UIHostingController(rootView: PostDetailViewControllerContent(controller: self)
            .environmentObject(self))
    }()

    override func loadView() {
        super.loadView()

        addChild(host)
        view.addSubview(host.view)

        title = "\(post.author.name)’s Post"
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        host.view.frame = view.bounds
    }

}

private struct PostDetailViewControllerContent: View {
    @ObservedObject var controller: PostDetailViewController

    var body: some View {
        PostDetailsScreen(post: controller.post)
            .id(controller.post)
            .environment(controller.client)
    }
}
