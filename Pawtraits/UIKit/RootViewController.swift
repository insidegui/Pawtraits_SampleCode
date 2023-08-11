import UIKit
import SwiftUI

final class RootViewController: PawtraitsBaseViewController {

    private lazy var rootNavigation: DeferredNavigationController = {
        DeferredNavigationController(rootViewController: postsController)
    }()

    private lazy var postsController: PostListController = {
        PostListController(client: client)
    }()

    override func loadView() {
        super.loadView()

        addChild(rootNavigation)
        view.addSubview(rootNavigation.view)
        rootNavigation.didMove(toParent: self)

        rootNavigation.navigationBar.prefersLargeTitles = true
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        rootNavigation.view.frame = view.bounds
    }

}

struct PawtraitsUIKitRootView: UIViewControllerRepresentable {
    var client: PawtraitsAPIClient

    func makeUIViewController(context: Context) -> some UIViewController {
        RootViewController(client: client)
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {

    }
}
