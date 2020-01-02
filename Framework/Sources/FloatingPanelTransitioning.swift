//
//  Created by Shin Yamamoto on 2018/11/21.
//  Copyright © 2018 Shin Yamamoto. All rights reserved.
//

import UIKit

class FloatingPanelModalTransition: NSObject, UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FloatingPanelModalPresentTransition()
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FloatingPanelModalDismissTransition()
    }

    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return FloatingPanelPresentationController(presentedViewController: presented, presenting: presenting)
    }
}

class FloatingPanelPresentationController: UIPresentationController {
    override func presentationTransitionWillBegin() {
        // Must call here even if duplicating on in containerViewWillLayoutSubviews()
        // Because it let the floating panel present correctly with the presentation animation
        addFloatingPanel()
    }

    override func presentationTransitionDidEnd(_ completed: Bool) {
        // For non-animated presentation
        if let fpc = presentedViewController as? FloatingPanelController, fpc.position == .hidden {
            fpc.show(animated: false, completion: nil)
        }
    }

    override func dismissalTransitionDidEnd(_ completed: Bool) {
        if let fpc = presentedViewController as? FloatingPanelController {
            // For non-animated dismissal
            if fpc.position != .hidden {
                fpc.hide(animated: false, completion: nil)
            }
            fpc.view.removeFromSuperview()
        }
    }

    override func containerViewWillLayoutSubviews() {
        guard
            let fpc = presentedViewController as? FloatingPanelController
            else { fatalError() }

        /*
         * Layout the views managed by `FloatingPanelController` here for the
         * sake of the presentation and dismissal modally from the controller.
         */
        addFloatingPanel()

        // Forward touch events to the presenting view controller
        (fpc.view as? FloatingPanelPassThroughView)?.eventForwardingView = presentingViewController.view

        fpc.backdropView.dismissalTapGestureRecognizer.isEnabled = true
    }

    @objc func handleBackdrop(tapGesture: UITapGestureRecognizer) {
        presentedViewController.dismiss(animated: true, completion: nil)
    }

    private func addFloatingPanel() {
        guard
            let containerView = self.containerView,
            let fpc = presentedViewController as? FloatingPanelController
            else { fatalError() }

        containerView.addSubview(fpc.view)
        fpc.view.frame = containerView.bounds
        fpc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
}

class FloatingPanelModalPresentTransition: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        guard
            let fpc = transitionContext?.viewController(forKey: .to) as? FloatingPanelController
        else { fatalError()}

        let animator = fpc.behavior.addAnimator(fpc, to: fpc.layout.initialPosition)
        return TimeInterval(animator.duration)
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard
            let fpc = transitionContext.viewController(forKey: .to) as? FloatingPanelController
        else { fatalError() }

        fpc.show(animated: true) {
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}

class FloatingPanelModalDismissTransition: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        guard
            let fpc = transitionContext?.viewController(forKey: .from) as? FloatingPanelController
        else { fatalError()}

        let animator = fpc.behavior.removeAnimator(fpc, from: fpc.position)
        return TimeInterval(animator.duration)
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard
            let fpc = transitionContext.viewController(forKey: .from) as? FloatingPanelController
        else { fatalError() }

        fpc.hide(animated: true) {
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}

