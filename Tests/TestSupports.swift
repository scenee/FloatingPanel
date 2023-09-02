// Copyright 2018 the FloatingPanel authors. All rights reserved. MIT license.

import Foundation
@testable import FloatingPanel

func waitRunLoop(secs: TimeInterval = 0) {
    RunLoop.main.run(until: Date(timeIntervalSinceNow: secs))
}

extension FloatingPanelController {
    func showForTest() {
        loadViewIfNeeded()
        view.frame = CGRect(x: 0, y: 0, width: 375, height: 667)
        show(animated: false, completion: nil)
    }
}

class FloatingPanelTestDelegate: FloatingPanelControllerDelegate {
    var position: FloatingPanelState = .hidden
    var didMoveCallback: ((FloatingPanelController) -> Void)?
    func floatingPanelDidChangeState(_ vc: FloatingPanelController) {
        position = vc.state
    }
    func floatingPanelDidMove(_ vc: FloatingPanelController) {
        didMoveCallback?(vc)
    }
}

class FloatingPanelTestLayout: FloatingPanelLayout {
    let fullInset: CGFloat = 20.0
    let halfInset: CGFloat = 250.0
    let tipInset: CGFloat = 60.0

    var initialState: FloatingPanelState {
        return .half
    }
    var position: FloatingPanelPosition {
        return .bottom
    }
    var referenceGuide: FloatingPanelLayoutReferenceGuide {
        return .superview
    }
    var anchors: [FloatingPanelState : FloatingPanelLayoutAnchoring] {
        return [
            .full: FloatingPanelLayoutAnchor(absoluteInset: fullInset, edge: .top, referenceGuide: referenceGuide),
            .half: FloatingPanelLayoutAnchor(absoluteInset: halfInset, edge: .bottom, referenceGuide: referenceGuide),
            .tip: FloatingPanelLayoutAnchor(absoluteInset: tipInset, edge: .bottom, referenceGuide: referenceGuide),
        ]
    }
}

class FloatingPanelTop2BottomTestLayout: FloatingPanelLayout {
    let fullInset: CGFloat = 0.0
    let halfInset: CGFloat = 250.0
    let tipInset: CGFloat = 60.0

    var initialState: FloatingPanelState {
        return .half
    }
    var position: FloatingPanelPosition {
        return .top
    }
    var referenceGuide: FloatingPanelLayoutReferenceGuide {
        return .superview
    }
    var anchors: [FloatingPanelState : FloatingPanelLayoutAnchoring] {
        return [
            .full: FloatingPanelLayoutAnchor(absoluteInset: fullInset, edge: .bottom, referenceGuide: referenceGuide),
            .half: FloatingPanelLayoutAnchor(absoluteInset: halfInset, edge: .top, referenceGuide: referenceGuide),
            .tip: FloatingPanelLayoutAnchor(absoluteInset: tipInset, edge: .top, referenceGuide: referenceGuide),
        ]
    }
}

class FloatingPanelTopPositionedLayout: FloatingPanelLayout {
    let position: FloatingPanelPosition = .top
    let initialState: FloatingPanelState = .full
    let anchors: [FloatingPanelState : FloatingPanelLayoutAnchoring] = [
        .full: FloatingPanelLayoutAnchor(absoluteInset: 88.0, edge: .bottom, referenceGuide: .safeArea),
        .half: FloatingPanelLayoutAnchor(absoluteInset: 216.0, edge: .top, referenceGuide: .safeArea),
        .tip: FloatingPanelLayoutAnchor(absoluteInset: 44.0, edge: .top, referenceGuide: .safeArea)
    ]
}

class FloatingPanelProjectableBehavior: FloatingPanelBehavior {
    func shouldProjectMomentum(_ fpc: FloatingPanelController, to proposedState: FloatingPanelState) -> Bool {
        return true
    }
}

class MockTransitionCoordinator: NSObject, UIViewControllerTransitionCoordinator {
    func animate(alongsideTransition animation: ((UIViewControllerTransitionCoordinatorContext) -> Void)?, completion: ((UIViewControllerTransitionCoordinatorContext) -> Void)? = nil) -> Bool { true }
    func animateAlongsideTransition(in view: UIView?, animation: ((UIViewControllerTransitionCoordinatorContext) -> Void)?, completion: ((UIViewControllerTransitionCoordinatorContext) -> Void)? = nil) -> Bool { true }
    func notifyWhenInteractionEnds(_ handler: @escaping (UIViewControllerTransitionCoordinatorContext) -> Void) {}
    func notifyWhenInteractionChanges(_ handler: @escaping (UIViewControllerTransitionCoordinatorContext) -> Void) {}
    var isAnimated: Bool = false
    var presentationStyle: UIModalPresentationStyle = .fullScreen
    var initiallyInteractive: Bool = false
    var isInterruptible: Bool = false
    var isInteractive: Bool = false
    var isCancelled: Bool = false
    var transitionDuration: TimeInterval = 0.25
    var percentComplete: CGFloat = 0
    var completionVelocity: CGFloat = 0
    var completionCurve: UIView.AnimationCurve = .easeInOut
    func viewController(forKey key: UITransitionContextViewControllerKey) -> UIViewController? { nil }
    func view(forKey key: UITransitionContextViewKey) -> UIView? { nil }
    var containerView: UIView { UIView() }
    var targetTransform: CGAffineTransform = .identity
}

