//
//  Created by Shin Yamamoto on 2018/10/03.
//  Copyright © 2018 Shin Yamamoto. All rights reserved.
//

import UIKit

public protocol FloatingPanelBehavior {
    /// Returns the progress to redirect to the previous position
    ///
    /// The progress is represented by a floating-point value between 0.0 and 1.0, inclusive, where 1.0 indicates the floating panel is impossible to move to the next posiiton. The default value is 0.5. Values less than 0.0 and greater than 1.0 are pinned to those limits.
    func redirectionalProgress(_ fpc: FloatingPanelController, from: FloatingPanelPosition, to: FloatingPanelPosition) -> CGFloat

    /// Returns a UIViewPropertyAnimator object to project a floating panel to a position on finger up if the user dragged.
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
}

public extension FloatingPanelBehavior {
    func redirectionalProgress(_ fpc: FloatingPanelController, from: FloatingPanelPosition, to: FloatingPanelPosition) -> CGFloat {
        return 0.5
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
}

class FloatingPanelDefaultBehavior: FloatingPanelBehavior {
    func interactionAnimator(_ fpc: FloatingPanelController, to targetPosition: FloatingPanelPosition, with velocity: CGVector) -> UIViewPropertyAnimator {
        let timing = timeingCurve(with: velocity)
        let animator = UIViewPropertyAnimator(duration: 0, timingParameters: timing)
        animator.isInterruptible = false
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
