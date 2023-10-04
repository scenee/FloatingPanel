// Copyright 2018-Present Shin Yamamoto. All rights reserved. MIT license.

import UIKit
import FloatingPanel
import WebKit

final class MultiPanelController: FloatingPanelController, FloatingPanelControllerDelegate {

    private final class FirstPanelContentViewController: UIViewController {

        lazy var webView: WKWebView = WKWebView()

        override func viewDidLoad() {
            super.viewDidLoad()
            view.addSubview(webView)
            webView.frame = view.bounds
            webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            webView.load(URLRequest(url: URL(string: "https://www.apple.com")!))

            let vc = MultiSecondPanelController()
            vc.setUpContent()
            vc.addPanel(toParent: self)
        }
    }

    private final class MultiSecondPanelController: FloatingPanelController {

        private final class SecondPanelContentViewController: DebugTableViewController {}

        func setUpContent() {
            contentInsetAdjustmentBehavior = .never
            let vc = SecondPanelContentViewController()
            vc.loadViewIfNeeded()
            vc.title = "Second Panel"
            vc.buttonStackView.isHidden = true
            let navigationController = UINavigationController(rootViewController: vc)
            navigationController.navigationBar.barTintColor = .white
            navigationController.navigationBar.titleTextAttributes = [
                .foregroundColor: UIColor.black
            ]
            set(contentViewController: navigationController)
            self.track(scrollView: vc.tableView)
            surfaceView.containerMargins = .init(top: 24.0, left: 0.0, bottom: layoutInsets.bottom, right: 0.0)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        layout = FirstViewLayout()
        isRemovalInteractionEnabled = true

        let vc = FirstPanelContentViewController()
        set(contentViewController: vc)
        track(scrollView: vc.webView.scrollView)
    }

    private final class FirstViewLayout: FloatingPanelLayout {
        let position: FloatingPanelPosition = .bottom
        let initialState: FloatingPanelState = .full
        let anchors: [FloatingPanelState : FloatingPanelLayoutAnchoring] = [
            .full: FloatingPanelLayoutAnchor(absoluteInset: 40.0, edge: .top, referenceGuide: .superview)
        ]
    }
}

