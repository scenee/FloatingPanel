// Copyright 2018-Present Shin Yamamoto. All rights reserved. MIT license.

import UIKit

class ModalTransition: NSObject, UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ModalPresentTransition()
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ModalDismissTransition()
    }

    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return PresentationController(presentedViewController: presented, presenting: presenting)
    }
}

class PresentationController: UIPresentationController {
    override func presentationTransitionWillBegin() {
        // Must call here even if duplicating on in containerViewWillLayoutSubviews()
        // Because it let the panel present correctly with the presentation animation
        addFloatingPanel()
    }

    override func presentationTransitionDidEnd(_ completed: Bool) {
        // For non-animated presentation
        if let fpc = presentedViewController as? FloatingPanelController, fpc.state == .hidden {
            fpc.show(animated: false, completion: nil)
        }
    }

    override func dismissalTransitionDidEnd(_ completed: Bool) {
        if let fpc = presentedViewController as? FloatingPanelController {
            // For non-animated dismissal
            if fpc.state != .hidden {
                fpc.hide(animated: false, completion: nil)
            }
            fpc.view.removeFromSuperview()
        }
    }

    override func containerViewWillLayoutSubviews() {
        guard
            let fpc = presentedViewController as? FloatingPanelController,
            /**
             This condition fixes https://github.com/SCENEE/FloatingPanel/issues/369.
             The issue is that this method is called in presenting a
             UIImagePickerViewController and then a FloatingPanelController
             view is added unnecessarily.
             */
            fpc.presentedViewController == nil
            else { return }

        /*
         * Layout the views managed by `FloatingPanelController` here for the
         * sake of the presentation and dismissal modally from the controller.
         */
        addFloatingPanel()

        // Forward touch events to the presenting view controller
        (fpc.view as? PassthroughView)?.eventForwardingView = presentingViewController.view
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

class ModalPresentTransition: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        guard
            let fpc = transitionContext?.viewController(forKey: .to) as? FloatingPanelController
        else { fatalError()}

        let animator = fpc.animatorForPresenting(to: fpc.layout.initialState)
        return TimeInterval(animator.duration)
    }

    func interruptibleAnimator(using transitionContext: UIViewControllerContextTransitioning) -> UIViewImplicitlyAnimating {
        guard
            let fpc = transitionContext.viewController(forKey: .to) as? FloatingPanelController
        else { fatalError() }

        if let animator = fpc.transitionAnimator {
            return animator
        }

        fpc.suspendTransitionAnimator(true)
        fpc.show(animated: true) { [weak fpc] in
            fpc?.suspendTransitionAnimator(false)
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
        guard let transitionAnimator = fpc.transitionAnimator else {
            fatalError("The panel state must be `hidden` but it is `\(fpc.state)`")
        }
        return transitionAnimator
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        self.interruptibleAnimator(using: transitionContext).startAnimation()
    }
}

class ModalDismissTransition: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        guard
            let fpc = transitionContext?.viewController(forKey: .from) as? FloatingPanelController
        else { fatalError()}

        let animator = fpc.animatorForDismissing(with: .zero)
        return TimeInterval(animator.duration)
    }

    func interruptibleAnimator(using transitionContext: UIViewControllerContextTransitioning) -> UIViewImplicitlyAnimating {
        guard
            let fpc = transitionContext.viewController(forKey: .from) as? FloatingPanelController
        else { fatalError() }

        if let animator = fpc.transitionAnimator {
            return animator
        }

        fpc.suspendTransitionAnimator(true)
        fpc.hide(animated: true) { [weak fpc] in
            fpc?.suspendTransitionAnimator(false)
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
        return fpc.transitionAnimator!
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        self.interruptibleAnimator(using: transitionContext).startAnimation()
    }
}

