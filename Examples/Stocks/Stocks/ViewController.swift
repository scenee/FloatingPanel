//
//  ViewController.swift
//  Stocks
//
//  Created by Shin Yamamoto on 2018/10/12.
//  Copyright © 2018 Shin Yamamoto. All rights reserved.
//

import UIKit
import FloatingPanel

class ViewController: UIViewController, FloatingPanelControllerDelegate {
    @IBOutlet var topBannerView: UIImageView!
    @IBOutlet weak var labelStackView: UIStackView!
    @IBOutlet weak var bottomToolView: UIView!

    var fpc: FloatingPanelController!
    var newsVC: NewsViewController!

    var initialColor: UIColor = .black

    override func viewDidLoad() {
        super.viewDidLoad()
        initialColor = view.backgroundColor!
        // Initialize FloatingPanelController
        fpc = FloatingPanelController()
        fpc.delegate = self
        fpc.behavior = FloatingPanelStocksBehavior()

        // Initialize FloatingPanelController and add the view
        fpc.surfaceView.backgroundColor = UIColor(displayP3Red: 30.0/255.0, green: 30.0/255.0, blue: 30.0/255.0, alpha: 1.0)
        fpc.surfaceView.appearance.cornerRadius = 24.0
        fpc.surfaceView.appearance.shadows = []
        fpc.surfaceView.appearance.borderWidth = 1.0 / traitCollection.displayScale
        fpc.surfaceView.appearance.borderColor = UIColor.black.withAlphaComponent(0.2)

        newsVC = storyboard?.instantiateViewController(withIdentifier: "News") as? NewsViewController

        // Set a content view controller
        fpc.set(contentViewController: newsVC)
        fpc.track(scrollView: newsVC.scrollView)

        fpc.addPanel(toParent: self, at: view.subviews.firstIndex(of: bottomToolView) ?? -1 , animated: false)

        topBannerView.frame = .zero
        topBannerView.alpha = 0.0
        view.addSubview(topBannerView)
        topBannerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topBannerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0.0),
            topBannerView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 0.0),
            ])
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    // MARK: FloatingPanelControllerDelegate

    func floatingPanel(_ vc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout {
        return FloatingPanelStocksLayout()
    }

    func floatingPanelDidMove(_ vc: FloatingPanelController) {
        if vc.isDecelerating == false {
            let loc = vc.surfaceLocation
            let minY = vc.surfaceLocation(for: .full).y
            let maxY = vc.surfaceLocation(for: .tip).y
            vc.surfaceLocation = CGPoint(x: loc.x, y: min(max(loc.y, minY), maxY))
        }

        if vc.surfaceLocation.y <= vc.surfaceLocation(for: .full).y + 100 {
            showStockTickerBanner()
        } else {
            hideStockTickerBanner()
        }
    }

    private func showStockTickerBanner() {
        // Present top bar with dissolve animation
        UIView.animate(withDuration: 0.25) {
            self.topBannerView.alpha = 1.0
            self.labelStackView.alpha = 0.0
            self.view.backgroundColor = .black
        }
    }

    private func hideStockTickerBanner() {
        // Dimiss top bar with dissolve animation
        UIView.animate(withDuration: 0.25) {
            self.topBannerView.alpha = 0.0
            self.labelStackView.alpha = 1.0
            self.view.backgroundColor = .black
        }
    }
}

class NewsViewController: UIViewController {
    @IBOutlet weak var scrollView: UIScrollView!
}


// MARK: - FloatingPanelLayout

class FloatingPanelStocksLayout: FloatingPanelLayout {
    let position: FloatingPanelPosition = .bottom
    let initialState: FloatingPanelState = .tip

    var anchors: [FloatingPanelState: FloatingPanelLayoutAnchoring] {
        return [
            .full: FloatingPanelLayoutAnchor(absoluteInset: 56.0, edge: .top, referenceGuide: .safeArea),
            .half: FloatingPanelLayoutAnchor(absoluteInset: 262.0, edge: .bottom, referenceGuide: .safeArea),
             /* Visible + ToolView */
            .tip: FloatingPanelLayoutAnchor(absoluteInset: 85.0 + 44.0, edge: .bottom, referenceGuide: .safeArea),
        ]
    }

    func backdropAlpha(for state: FloatingPanelState) -> CGFloat {
        return 0.0
    }
}

// MARK: - FloatingPanelBehavior

class FloatingPanelStocksBehavior: FloatingPanelBehavior {
    let springDecelerationRate: CGFloat = UIScrollView.DecelerationRate.fast.rawValue
    let springResponseTime: CGFloat = 0.25
}
