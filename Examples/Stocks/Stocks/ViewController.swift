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

        // Initialize FloatingPanelController and add the view
        fpc.surfaceView.backgroundColor = UIColor(displayP3Red: 30.0/255.0, green: 30.0/255.0, blue: 30.0/255.0, alpha: 1.0)
        fpc.surfaceView.cornerRadius = 24.0
        fpc.surfaceView.shadowHidden = true
        fpc.surfaceView.borderWidth = 1.0 / traitCollection.displayScale
        fpc.surfaceView.borderColor = UIColor.black.withAlphaComponent(0.2)

        newsVC = storyboard?.instantiateViewController(withIdentifier: "News") as? NewsViewController

        // Set a content view controller
        fpc.set(contentViewController: newsVC)
        fpc.track(scrollView: newsVC.scrollView)

        fpc.addPanel(toParent: self, belowView: bottomToolView, animated: false)

        topBannerView.frame = .zero
        topBannerView.alpha = 0.0
        view.addSubview(topBannerView)
        topBannerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topBannerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0.0),
            topBannerView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 0.0),
            ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    // MARK: FloatingPanelControllerDelegate

    func floatingPanel(_ vc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout? {
        return FloatingPanelStocksLayout()
    }

    func floatingPanel(_ vc: FloatingPanelController, behaviorFor newCollection: UITraitCollection) -> FloatingPanelBehavior? {
        return FloatingPanelStocksBehavior()
    }

    func floatingPanelWillBeginDragging(_ vc: FloatingPanelController) {
        if vc.position == .full {
            // Dimiss top bar with dissolve animation
            UIView.animate(withDuration: 0.25) {
                self.topBannerView.alpha = 0.0
                self.labelStackView.alpha = 1.0
                self.view.backgroundColor = self.initialColor
            }
        }
    }
    func floatingPanelDidEndDragging(_ vc: FloatingPanelController, withVelocity velocity: CGPoint, targetPosition: FloatingPanelPosition) {
        if targetPosition == .full {
            // Present top bar with dissolve animation
            UIView.animate(withDuration: 0.25) {
                self.topBannerView.alpha = 1.0
                self.labelStackView.alpha = 0.0
                self.view.backgroundColor = .black
            }
        }
    }
}

class NewsViewController: UIViewController {
    @IBOutlet weak var scrollView: UIScrollView!
}


// MARK: My custom layout

class FloatingPanelStocksLayout: FloatingPanelLayout {
    var initialPosition: FloatingPanelPosition {
        return .tip
    }

    var topInteractionBuffer: CGFloat { return 0.0 }
    var bottomInteractionBuffer: CGFloat { return 0.0 }

    func insetFor(position: FloatingPanelPosition) -> CGFloat? {
        switch position {
        case .full: return 56.0
        case .half: return 262.0
        case .tip: return 85.0 + 44.0 // Visible + ToolView
        default: return nil
        }
    }

    func backdropAlphaFor(position: FloatingPanelPosition) -> CGFloat {
        return 0.0
    }
}

// MARK: My custom behavior

class FloatingPanelStocksBehavior: FloatingPanelBehavior {
    var velocityThreshold: CGFloat {
        return 15.0
    }

    func interactionAnimator(_ fpc: FloatingPanelController, to targetPosition: FloatingPanelPosition, with velocity: CGVector) -> UIViewPropertyAnimator {
        let timing = timeingCurve(to: targetPosition, with: velocity)
        return UIViewPropertyAnimator(duration: 0, timingParameters: timing)
    }

    private func timeingCurve(to: FloatingPanelPosition, with velocity: CGVector) -> UITimingCurveProvider {
        let damping = self.damping(with: velocity)
        return UISpringTimingParameters(dampingRatio: damping,
                                        frequencyResponse: 0.4,
                                        initialVelocity: velocity)
    }

    private func damping(with velocity: CGVector) -> CGFloat {
        switch velocity.dy {
        case ...(-velocityThreshold):
            return 0.7
        case velocityThreshold...:
            return 0.7
        default:
            return 1.0
        }
    }
}
