import UIKit

class PawtraitsBaseViewController: UIViewController {
    var client: PawtraitsAPIClient

    init(client: PawtraitsAPIClient) {
        self.client = client

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func loadView() {
        view = UIView(frame: .zero)
        view.backgroundColor = .systemBackground
    }
}
