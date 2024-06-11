// Copyright 2018-Present Shin Yamamoto. All rights reserved. MIT license.

import UIKit
import FloatingPanel

@available(iOS 13.0, *)
class CollectionViewControllerForAdaptiveLayout: UIViewController {
    class PanelLayout: FloatingPanelLayout {
        let position: FloatingPanelPosition = .bottom
        let initialState: FloatingPanelState = .full

        private unowned var targetGuide: UILayoutGuide

        init(targetGuide: UILayoutGuide) {
            self.targetGuide = targetGuide
        }

        var anchors: [FloatingPanelState : FloatingPanelLayoutAnchoring] {
            return [
                .full: FloatingPanelAdaptiveLayoutAnchor(
                    absoluteOffset: 0.0,
                    contentLayout: targetGuide,
                    referenceGuide: .superview,
                    contentBoundingGuide: .safeArea
                ),
                .half: FloatingPanelAdaptiveLayoutAnchor(
                    fractionalOffset: 0.5,
                    contentLayout: targetGuide,
                    referenceGuide: .superview,
                    contentBoundingGuide: .safeArea
                ),
            ]
        }
    }

    enum LayoutType {
        case flow
        case compositional
    }

    weak var collectionView: UICollectionView!
    var layoutType: LayoutType = .flow

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
    }

    private func setupCollectionView() {
        let collectionViewLayout = {
            switch layoutType {
            case .flow:
                CollectionViewLayoutFactory.flowLayout
            case .compositional:
                CollectionViewLayoutFactory.compositionalLayout
            }
        }()
        let collectionView = IntrinsicCollectionView(
            frame: .zero,
            collectionViewLayout: collectionViewLayout
        )

        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .yellow
        collectionView.register(Cell.self, forCellWithReuseIdentifier: Cell.reuseIdentifier)

        view.addSubview(collectionView)
        self.collectionView = collectionView

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
}

@available(iOS 13.0, *)
extension CollectionViewControllerForAdaptiveLayout: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 5  // Only three cells needed to fill the space
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Cell.reuseIdentifier, for: indexPath) as! Cell
        cell.configure(text: "Item \(indexPath.row)")
        return cell
    }


    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.width  
        return CGSize(width: width, height: 100)
    }
}

@available(iOS 13.0, *)
extension CollectionViewControllerForAdaptiveLayout {
    enum CollectionViewLayoutFactory {
        static var flowLayout: UICollectionViewLayout {
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .vertical
            layout.minimumLineSpacing = 8  // Vertical spacing between rows
            return layout
        }

        @available(iOS 13.0, *)
        static var compositionalLayout: UICollectionViewLayout {
            UICollectionViewCompositionalLayout { (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(100))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)

                let group = NSCollectionLayoutGroup.horizontal(layoutSize: itemSize, subitems: [item])

                let section = NSCollectionLayoutSection(group: group)
                section.interGroupSpacing = 8 // Spacing between each group/item
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)

                return section
            }
        }
    }


    private final class Cell: UICollectionViewCell {
        static let reuseIdentifier = "Cell"

        private let label: UILabel = {
            let label = UILabel()
            label.textAlignment = .center
            label.textColor = .white
            return label
        }()

        override init(frame: CGRect) {
            super.init(frame: frame)
            commonInit()
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            commonInit()
        }

        private func commonInit() {
            backgroundColor = .systemBlue
            addSubview(label)
            label.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: centerXAnchor),
                label.centerYAnchor.constraint(equalTo: centerYAnchor)
            ])
        }

        func configure(text: String) {
            label.text = text
        }
    }

    private final class IntrinsicCollectionView: UICollectionView {
        override public var contentSize: CGSize {
            didSet {
                invalidateIntrinsicContentSize()
            }
        }

        override public var intrinsicContentSize: CGSize {
            layoutIfNeeded()
            return CGSize(width: UIView.noIntrinsicMetric, height: contentSize.height)
        }
    }
}
