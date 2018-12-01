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
    override func presentationTransitionDidEnd(_ completed: Bool) {
        // For non-animated presentation
        if let fpc = presentedViewController as? FloatingPanelController, fpc.position == .hidden {
            fpc.show(animated: false, completion: nil)
        }
    }

    override func dismissalTransitionDidEnd(_ completed: Bool) {
        // For non-animated dismissal
        if let fpc = presentedViewController as? FloatingPanelController, fpc.position != .hidden {
            fpc.hide(animated: false, completion: nil)
        }
    }

    override func containerViewWillLayoutSubviews() {
        guard
            let containerView = self.containerView,
            let fpc = presentedViewController as? FloatingPanelController,
            let fpView = fpc.view
            else { fatalError() }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleBackdrop(tapGesture:)))
        fpc.backdropView.addGestureRecognizer(tapGesture)

        containerView.addSubview(fpView)
        fpView.frame = containerView.bounds //MUST
    }

    @objc func handleBackdrop(tapGesture: UITapGestureRecognizer) {
        presentedViewController.dismiss(animated: true, completion: nil)
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

