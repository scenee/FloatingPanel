// Copyright 2018-Present Shin Yamamoto. All rights reserved. MIT license.

import UIKit

enum UseCase: Int, CaseIterable {
    case trackingTableView
    case trackingTextView
    case showDetail
    case showModal
    case showPanelModal
    case showMultiPanelModal
    case showPanelInSheetModal
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
    case showAdaptivePanelWithCustomGuide
    case showCustomStatePanel
}

extension UseCase {
    var name: String {
        switch self {
        case .trackingTableView: return "Scroll tracking(TableView)"
        case .trackingTextView: return "Scroll tracking(TextView)"
        case .showDetail: return "Show Detail Panel"
        case .showModal: return "Show Modal"
        case .showPanelModal: return "Show Panel Modal"
        case .showMultiPanelModal: return "Show Multi Panel Modal"
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
        case .showAdaptivePanelWithCustomGuide: return "Show Adaptive Panel (Custom Layout Guide)"
        case .showCustomStatePanel: return "Show Panel with Custom state"
        }
    }

    private enum Content {
        case storyboard(String)
        case viewController(UIViewController)
    }

    private var content: Content {
        switch self {
        case .trackingTableView: return .viewController(DebugTableViewController())
        case .trackingTextView: return .storyboard("ConsoleViewController") // Storyboard only
        case .showDetail: return .storyboard(String(describing: DetailViewController.self))
        case .showModal: return .storyboard(String(describing: ModalViewController.self))
        case .showMultiPanelModal: return .viewController(DebugTableViewController())
        case .showPanelInSheetModal: return .viewController(DebugTableViewController())
        case .showPanelModal: return .viewController(DebugTableViewController())
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
        case .showAdaptivePanelWithCustomGuide: return .storyboard(String(describing: ImageViewController.self))
        case .showCustomStatePanel: return .viewController(DebugTableViewController())
        }
    }

    func makeContentViewController(with storyboard: UIStoryboard) -> UIViewController {
        switch content {
        case .storyboard(let id):
            return storyboard.instantiateViewController(withIdentifier: id)
        case .viewController(let vc):
            return vc
        }
    }
}
