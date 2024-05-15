// Copyright 2018 the FloatingPanel authors. All rights reserved. MIT license.

import UIKit

@available(iOS 14, *)
class DebugListCollectionViewController: UIViewController {

    enum Section {
        case main
    }

    var dataSource: UICollectionViewDiffableDataSource<Section, Int>! = nil
    var collectionView: UICollectionView! = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "List"
        configureHierarchy()
        configureDataSource()
    }
}

@available(iOS 14, *)
extension DebugListCollectionViewController {
    /// - Tag: List
    private func createLayout() -> UICollectionViewLayout {
        var config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        config.trailingSwipeActionsConfigurationProvider =  { indexPath -> UISwipeActionsConfiguration? in
            return UISwipeActionsConfiguration(
                actions: [UIContextualAction(
                    style: .destructive,
                    title: "Delete",
                    handler: { _, _, completion in
                        // Do nothing now
                    }
                )]
            )
        }
        return UICollectionViewCompositionalLayout.list(using: config)
    }
}

@available(iOS 14, *)
extension DebugListCollectionViewController {
    private func configureHierarchy() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(collectionView)
        collectionView.delegate = self
    }
    private func configureDataSource() {

        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Int> { (cell, indexPath, item) in
            var content = cell.defaultContentConfiguration()
            content.text = "\(item)"
            cell.contentConfiguration = content
        }

        dataSource = UICollectionViewDiffableDataSource<Section, Int>(collectionView: collectionView) {
            (collectionView: UICollectionView, indexPath: IndexPath, identifier: Int) -> UICollectionViewCell? in

            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: identifier)
        }

        var snapshot = NSDiffableDataSourceSnapshot<Section, Int>()
        snapshot.appendSections([.main])
        snapshot.appendItems(Array(0..<94))
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}

@available(iOS 14, *)
extension DebugListCollectionViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}
