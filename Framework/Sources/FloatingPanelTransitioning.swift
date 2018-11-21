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
        guard
            let containerView = self.containerView,
            let fpc = presentedViewController as? FloatingPanelController,
            let toView = fpc.view
        else { fatalError() }

        fpc.view.frame = containerView.bounds

        containerView.addSubview(toView)
        toView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            toView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 0.0),
            toView.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 0.0),
            toView.rightAnchor.constraint(equalTo: containerView.rightAnchor, constant: 0.0),
            toView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 0.0),
            ])
    }
    override func presentationTransitionDidEnd(_ completed: Bool) {
        if let fpc = presentedViewController as? FloatingPanelController{
            // For non-animated presentation
            fpc.show(animated: false)
        }
    }
}

class FloatingPanelModalPresentTransition: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        guard
            let toVC = transitionContext?.viewController(forKey: .to) as? FloatingPanelController
        else { fatalError()}

        let animator = toVC.behavior.addAnimator(toVC, to: toVC.layout.initialPosition)
        return TimeInterval(animator.duration)
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard
            let toVC = transitionContext.viewController(forKey: .to) as? FloatingPanelController
        else { fatalError() }

        toVC.show(animated: true) {
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}

class FloatingPanelModalDismissTransition: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        guard
            let fromVC = transitionContext?.viewController(forKey: .from) as? FloatingPanelController
        else { fatalError()}

        let animator = fromVC.behavior.removeAnimator(fromVC, from: fromVC.position)
        return TimeInterval(animator.duration)
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard
            let fromVC = transitionContext.viewController(forKey: .from) as? FloatingPanelController
        else { fatalError() }

        fromVC.hide(animated: true) {
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}

