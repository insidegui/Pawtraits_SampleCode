import UIKit
import SwiftUI
import Combine

final class PostListController: PawtraitsBaseViewController, UICollectionViewDelegate {

    private lazy var compositionalLayout: UICollectionViewCompositionalLayout = {
        let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(400)))
        let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(400))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: size, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        let c = UICollectionViewCompositionalLayoutConfiguration()
        c.scrollDirection = .vertical
        let l = UICollectionViewCompositionalLayout(section: section, configuration: c)
        return l
    }()

    private lazy var collectionView: UICollectionView = {
        let v = UICollectionView(frame: view.bounds, collectionViewLayout: compositionalLayout)
        v.backgroundColor = .systemBackground
        return v
    }()

    private lazy var dataSource: UICollectionViewDiffableDataSource<Int, PawtraitsPost> = {
        let registration = UICollectionView.CellRegistration<UICollectionViewCell, PawtraitsPost> { [unowned self] cell, indexPath, post in
            cell.contentConfiguration = UIHostingConfiguration {
                PostView(post: post)
                    .environment(self.client)
            }
        }

        return UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, post in
            let cell = collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: post)
            return cell
        }
    }()

    private lazy var cancellables = Set<AnyCancellable>()

    override func loadView() {
        super.loadView()

        title = "Pawtraits"

        view.addSubview(collectionView)
        collectionView.delegate = self
        collectionView.dataSource = dataSource

        update(with: PawtraitsPost.placeholders)

        collectionView.dataSource = dataSource

        client.postsPublisher.sink { [weak self] posts in
            guard let self = self else { return }
            self.update(with: posts)
        }
        .store(in: &cancellables)

        Task {
            try? await client.fetchPosts(page: 0)
        }
    }

    private func update(with posts: [PawtraitsPost]) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, PawtraitsPost>()
        snapshot.appendSections([0])
        snapshot.appendItems(posts)
        dataSource.apply(snapshot)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        collectionView.frame = view.bounds
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let post = client.loadedPosts[indexPath.item]

        deferredNavigation?.push(value: post, load: client.fetchDetails) { [unowned self] post in
            PostDetailViewController(client: self.client, post: post)
        }
    }

    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        collectionView.cellForItem(at: indexPath)?.alpha = 0.8
        return true
    }

    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        UIView.animate(withDuration: 0.7) {
            collectionView.cellForItem(at: indexPath)?.alpha = 1
        }
    }

}

