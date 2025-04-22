// Copyright 2018-Present Shin Yamamoto. All rights reserved. MIT license.

import UIKit

enum UseCase: Int, CaseIterable {
    case trackingTableView
    case trackingTextView
    case trackingCollectionViewList
    case showDetail
    case showModal
    case showPanelModal
    case showPanelModal2
    case showMultiPanelModal
    case showPanelInSheetModal
    case showOnWindow
    case showTabBar
    case showPageView
    case showPageContentView
    case showNestedScrollView
    case showRemovablePanel
    case showIntrinsicView
    case showContentInset
    case showContainerMargins
    case showNavigationController
    case showTopPositionedPanel
    case showAdaptivePanel
    case showAdaptivePanelWithTableView
    case showAdaptivePanelWithCollectionView
    case showAdaptivePanelWithCompositionalCollectionView
    case showCustomStatePanel
    case showCustomBackdrop
}

extension UseCase {
    var name: String {
        switch self {
        case .trackingTableView: return "Scroll tracking(TableView)"
        case .trackingCollectionViewList: return "Scroll tracking(List CollectionView)"
        case .trackingTextView: return "Scroll tracking(TextView)"
        case .showDetail: return "Show Detail Panel"
        case .showModal: return "Show Modal"
        case .showPanelModal: return "Show Panel Modal"
        case .showPanelModal2: return "Show Panel Modal 2"
        case .showMultiPanelModal: return "Show Multi Panel Modal"
        case .showOnWindow: return "Show Panel over Window"
        case .showPanelInSheetModal: return "Show Panel in Sheet Modal"
        case .showTabBar: return "Show Tab Bar"
        case .showPageView: return "Show Page View"
        case .showPageContentView: return "Show Page Content View"
        case .showNestedScrollView: return "Show Nested ScrollView"
        case .showRemovablePanel: return "Show Removable Panel"
        case .showIntrinsicView: return "Show Intrinsic View"
        case .showContentInset: return "Show with ContentInset"
        case .showContainerMargins: return "Show with ContainerMargins"
        case .showNavigationController: return "Show Navigation Controller"
        case .showTopPositionedPanel: return "Show Top Positioned Panel"
        case .showAdaptivePanel: return "Show Adaptive Panel"
        case .showAdaptivePanelWithTableView: return "Show Adaptive Panel (TableView)"
        case .showAdaptivePanelWithCollectionView: return "Show Adaptive Panel (CollectionView)"
        case .showAdaptivePanelWithCompositionalCollectionView: return "Show Adaptive Panel (Compositional CollectionView)"
        case .showCustomStatePanel: return "Show Panel with Custom state"
        case .showCustomBackdrop: return "Show Panel with Custom Backdrop"
        }
    }
}

extension UseCase {
    private enum Content {
        case storyboard(String)
        case viewController(UIViewController)
    }

    private var content: Content {
        switch self {
        case .trackingTableView: return .viewController(DebugTableViewController())
        case .trackingCollectionViewList:
            if #available(iOS 14, *) {
                return .viewController(DebugListCollectionViewController())
            } else {
                let msg = "UICollectionLayoutListConfiguration is unavailable.\nBuild this app on iOS 14 and later."
                return makeUnavailableViewContent(message: msg)
            }
        case .trackingTextView: return .storyboard("ConsoleViewController") // Storyboard only
        case .showDetail: return .storyboard(String(describing: DetailViewController.self))
        case .showModal: return .storyboard(String(describing: ModalViewController.self))
        case .showPanelModal: return .viewController(DebugTableViewController())
        case .showPanelModal2: return .storyboard("ConsoleViewController")
        case .showMultiPanelModal: return .viewController(DebugTableViewController())
        case .showOnWindow: return .viewController(DebugTableViewController())
        case .showPanelInSheetModal: return .viewController(DebugTableViewController())
        case .showTabBar: return .storyboard(String(describing: TabBarViewController.self))
        case .showPageView: return .viewController(DebugTableViewController())
        case .showPageContentView: return .viewController(DebugTableViewController())
        case .showNestedScrollView: return .storyboard(String(describing: NestedScrollViewController.self))
        case .showRemovablePanel: return .storyboard(String(describing: DetailViewController.self))
        case .showIntrinsicView: return .storyboard("IntrinsicViewController") // Storyboard only
        case .showContentInset: return .viewController(DebugTableViewController())
        case .showContainerMargins: return .viewController(DebugTableViewController())
        case .showNavigationController: return .storyboard("RootNavigationController") // Storyboard only
        case .showTopPositionedPanel: return .viewController(DebugTableViewController())
        case .showAdaptivePanel: return .storyboard(String(describing: ImageViewController.self))
        case .showAdaptivePanelWithTableView: return .storyboard(String(describing: TableViewControllerForAdaptiveLayout.self))
        case .showAdaptivePanelWithCollectionView,
            .showAdaptivePanelWithCompositionalCollectionView:
            if #available(iOS 13, *) {
                let vc = CollectionViewControllerForAdaptiveLayout()
                vc.layoutType = self == .showAdaptivePanelWithCollectionView ? .flow : .compositional
                return .viewController(vc)
            } else {
                let msg = "Compositional layout is unavailable.\nBuild this app on iOS 13 and later."
                return makeUnavailableViewContent(message: msg)
            }
        case .showCustomStatePanel: return .viewController(DebugTableViewController())
        case .showCustomBackdrop: return .viewController(UIViewController())
        }
    }

    func makeContentViewController(with storyboard: UIStoryboard) -> UIViewController {
        switch content {
        case .storyboard(let id):
            return storyboard.instantiateViewController(withIdentifier: id)
        case .viewController(let vc):
            vc.loadViewIfNeeded()
            return vc
        }
    }

    private func makeUnavailableViewContent(message: String) -> Content {
        let vc = UnavailableViewController()
        vc.loadViewIfNeeded()
        vc.label.text = message
        return .viewController(vc)
    }
}
