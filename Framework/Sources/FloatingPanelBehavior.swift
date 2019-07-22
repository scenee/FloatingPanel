//
//  Created by Shin Yamamoto on 2018/10/03.
//  Copyright © 2018 Shin Yamamoto. All rights reserved.
//

import UIKit

public protocol FloatingPanelBehavior {
    /// Asks the behavior if the floating panel should project a momentum of a user interaction to move the proposed position.
    ///
    /// The default implementation of this method returns true. This method is called for a layout to support all positions(tip, half and full).
    /// Therefore, `proposedTargetPosition` can only be `FloatingPanelPosition.tip` or `FloatingPanelPosition.full`.
    func shouldProjectMomentum(_ fpc: FloatingPanelController, for proposedTargetPosition: FloatingPanelPosition) -> Bool

    /// Returns a deceleration rate to calculate a target position projected a dragging momentum.
    ///
    /// The default implementation of this method returns the normal deceleration rate of UIScrollView.
    func momentumProjectionRate(_ fpc: FloatingPanelController) -> CGFloat

    /// Returns the progress to redirect to the previous position.
    ///
    /// The progress is represented by a floating-point value between 0.0 and 1.0, inclusive, where 1.0 indicates the floating panel is impossible to move to the next position. The default value is 0.5. Values less than 0.0 and greater than 1.0 are pinned to those limits.
    func redirectionalProgress(_ fpc: FloatingPanelController, from: FloatingPanelPosition, to: FloatingPanelPosition) -> CGFloat

    /// Returns a UIViewPropertyAnimator object to project a floating panel to a position on finger up if the user dragged.
    ///
    /// - Attention:
    /// By default, it returns a non-interruptible animator to prevent a propagation of the animation to a content view.
    /// However returning an interruptible animator is working well depending on a content view and it can be better
    /// than using a non-interruptible one.
    func interactionAnimator(_ fpc: FloatingPanelController, to targetPosition: FloatingPanelPosition, with velocity: CGVector) -> UIViewPropertyAnimator

    /// Returns a UIViewPropertyAnimator object to add a floating panel to a position.
    ///
    /// Its animator instance will be used to animate the surface view in `FloatingPanelController.addPanel(toParent:belowView:animated:)`.
    /// Default is an animator with ease-in-out curve and 0.25 sec duration.
    func addAnimator(_ fpc: FloatingPanelController, to: FloatingPanelPosition) -> UIViewPropertyAnimator

    /// Returns a UIViewPropertyAnimator object to remove a floating panel from a position.
    ///
    /// Its animator instance will be used to animate the surface view in `FloatingPanelController.removePanelFromParent(animated:completion:)`.
    /// Default is an animator with ease-in-out curve and 0.25 sec duration.
    func removeAnimator(_ fpc: FloatingPanelController, from: FloatingPanelPosition) -> UIViewPropertyAnimator

    /// Returns a UIViewPropertyAnimator object to move a floating panel from a position to a position.
    ///
    /// Its animator instance will be used to animate the surface view in `FloatingPanelController.move(to:animated:completion:)`.
    /// Default is an animator with ease-in-out curve and 0.25 sec duration.
    func moveAnimator(_ fpc: FloatingPanelController, from: FloatingPanelPosition, to: FloatingPanelPosition) -> UIViewPropertyAnimator

    /// Returns a y-axis velocity to invoke a removal interaction at the bottom position.
    ///
    /// Default is 10.0. This method is called when FloatingPanelController.isRemovalInteractionEnabled is true.
    var removalVelocity: CGFloat { get }

    /// Returns the threshold of the transition to invoke a removal interaction at the bottom position.
    ///
    /// The progress is represented by a floating-point value between 0.0 and 1.0, inclusive, where 1.0 indicates the floating panel is impossible to invoke the removal interaction. The default value is 0.5. Values less than 0.0 and greater than 1.0 are pinned to those limits. This method is called when FloatingPanelController.isRemovalInteractionEnabled is true.
    var removalProgress: CGFloat { get }

    /// Returns a UIViewPropertyAnimator object to remove a floating panel with a velocity interactively at the bottom position.
    ///
    /// Default is a spring animator with 1.0 damping ratio. This method is called when FloatingPanelController.isRemovalInteractionEnabled is true.
    func removalInteractionAnimator(_ fpc: FloatingPanelController, with velocity: CGVector) -> UIViewPropertyAnimator


    /// Asks the behavior whether the rubber band effect is enabled in moving over a given edge of the surface view.
    ///
    /// This method allows the behavior to activate the rubber band effect to a given edge of the surface view. By default, the effect is disabled.
    func allowsRubberBanding(for edge: UIRectEdge) -> Bool
}

public extension FloatingPanelBehavior {
    func shouldProjectMomentum(_ fpc: FloatingPanelController, for proposedTargetPosition: FloatingPanelPosition) -> Bool {
        return false
    }

    func momentumProjectionRate(_ fpc: FloatingPanelController) -> CGFloat {
        #if swift(>=4.2)
        return UIScrollView.DecelerationRate.normal.rawValue
        #else
        return UIScrollViewDecelerationRateNormal
        #endif
    }

    func redirectionalProgress(_ fpc: FloatingPanelController, from: FloatingPanelPosition, to: FloatingPanelPosition) -> CGFloat {
        return 0.5
    }

    func interactionAnimator(_ fpc: FloatingPanelController, to targetPosition: FloatingPanelPosition, with velocity: CGVector) -> UIViewPropertyAnimator {
        return defaultBehavior.interactionAnimator(fpc, to: targetPosition, with: velocity)
    }

    func addAnimator(_ fpc: FloatingPanelController, to: FloatingPanelPosition) -> UIViewPropertyAnimator {
        return UIViewPropertyAnimator(duration: 0.25, curve: .easeInOut)
    }

    func removeAnimator(_ fpc: FloatingPanelController, from: FloatingPanelPosition) -> UIViewPropertyAnimator {
        return UIViewPropertyAnimator(duration: 0.25, curve: .easeInOut)
    }

    func moveAnimator(_ fpc: FloatingPanelController, from: FloatingPanelPosition, to: FloatingPanelPosition) -> UIViewPropertyAnimator {
        return UIViewPropertyAnimator(duration: 0.25, curve: .easeInOut)
    }

    var removalVelocity: CGFloat {
        return 10.0
    }

    var removalProgress: CGFloat {
        return 0.5
    }

    func removalInteractionAnimator(_ fpc: FloatingPanelController, with velocity: CGVector) -> UIViewPropertyAnimator {
        log.debug("velocity", velocity)
        let timing = UISpringTimingParameters(dampingRatio: 1.0,
                                        frequencyResponse: 0.3,
                                        initialVelocity: velocity)
        return UIViewPropertyAnimator(duration: 0, timingParameters: timing)
    }

    func allowsRubberBanding(for edge: UIRectEdge) -> Bool {
        return false
    }
}

private let defaultBehavior = FloatingPanelDefaultBehavior()

public class FloatingPanelDefaultBehavior: FloatingPanelBehavior {
    public init() { }

    public func interactionAnimator(_ fpc: FloatingPanelController, to targetPosition: FloatingPanelPosition, with velocity: CGVector) -> UIViewPropertyAnimator {
        let timing = timeingCurve(with: velocity)
        let animator = UIViewPropertyAnimator(duration: 0, timingParameters: timing)
        animator.isInterruptible = false // Prevent a propagation of the animation(spring etc) to a content view
        return animator
    }

    private func timeingCurve(with velocity: CGVector) -> UITimingCurveProvider {
        log.debug("velocity", velocity)
        let damping = self.getDamping(with: velocity)
        return UISpringTimingParameters(dampingRatio: damping,
                                        frequencyResponse: 0.3,
                                        initialVelocity: velocity)
    }

    private let velocityThreshold: CGFloat = 8.0
    private func getDamping(with velocity: CGVector) -> CGFloat {
        let dy = abs(velocity.dy)
        if dy > velocityThreshold {
            return 0.7
        } else {
            return 1.0
        }
    }
}
