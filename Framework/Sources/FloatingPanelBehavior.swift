//
//  Created by Shin Yamamoto on 2018/10/03.
//  Copyright © 2018 Shin Yamamoto. All rights reserved.
//

import UIKit

public protocol FloatingPanelBehavior {
    // Returns a UIViewPropertyAnimator object in interacting a floating panel by a user pan gesture
    func interactionAnimator(to targetPosition: FloatingPanelPosition, with velocity: CGVector) -> UIViewPropertyAnimator

    // Returns a UIViewPropertyAnimator object to present a floating panel
    func presentAnimator(from: FloatingPanelPosition, to: FloatingPanelPosition) -> UIViewPropertyAnimator
    // Returns a UIViewPropertyAnimator object to dismiss a floating panel
    func dismissAnimator(from: FloatingPanelPosition) -> UIViewPropertyAnimator
}

public extension FloatingPanelBehavior {
    func presentAnimator(from: FloatingPanelPosition, to: FloatingPanelPosition) -> UIViewPropertyAnimator {
        return UIViewPropertyAnimator(duration: 0.25, curve: .easeInOut)
    }

    func dismissAnimator(from: FloatingPanelPosition) -> UIViewPropertyAnimator {
        return UIViewPropertyAnimator(duration: 0.25, curve: .easeInOut)
    }
}

class FloatingPanelDefaultBehavior: FloatingPanelBehavior {
    func interactionAnimator(to targetPosition: FloatingPanelPosition, with velocity: CGVector) -> UIViewPropertyAnimator {
        let timing = timeingCurve(to: targetPosition, with: velocity)
        let duration = getDuration(with: velocity)
        return UIViewPropertyAnimator(duration: duration, timingParameters: timing)
    }

    private let velocityThreshold: CGFloat = 8.0
    private func getDuration(with velocity: CGVector) -> TimeInterval {
        let dy = abs(velocity.dy)
        switch dy {
        case ..<1.0:
            return 0.6
        case 1.0..<velocityThreshold:
            let a = ((dy - 1.0) / (velocityThreshold - 1.0))
            return TimeInterval(0.6 - (0.2 * a))
        case velocityThreshold...:
            return 0.4
        default:
            fatalError()
        }
    }

    private func timeingCurve(to: FloatingPanelPosition, with velocity: CGVector) -> UITimingCurveProvider {
        log.debug("velocity", velocity)
        let damping = self.getDamping(with: velocity)
        let springTiming = UISpringTimingParameters(dampingRatio: damping,
                                                    initialVelocity: velocity)
        return springTiming
    }

    private func getDamping(with velocity: CGVector) -> CGFloat {
        let dy = abs(velocity.dy)
        if dy > velocityThreshold {
            return 0.7
        } else {
            return 1.0
        }
    }
}
