// Copyright 2018 the FloatingPanel authors. All rights reserved. MIT license.

import UIKit

@objc
public protocol FloatingPanelBehavior {
    // TODO: doc comment
    // It's fine-tuned in units of 0.001
    @objc optional
    var springDecelerationRate: CGFloat { get }

    // TODO: doc comment
    @objc optional
    var springResponseTime: CGFloat { get }

    /// Returns a deceleration rate to calculate a target position projected a dragging momentum.
    ///
    /// The default implementation of this method returns the normal deceleration rate of UIScrollView.
    @objc optional
    var momentumProjectionRate: CGFloat { get }

    /// Asks the behavior if the floating panel should project a momentum of a user interaction to move the proposed position.
    ///
    /// The default implementation of this method returns true. This method is called for a layout to support all positions(tip, half and full).
    /// Therefore, `proposedTargetPosition` can only be `FloatingPanelState.tip` or `FloatingPanelState.full`.
    @objc optional
    func shouldProjectMomentum(_ fpc: FloatingPanelController, to proposedTargetPosition: FloatingPanelState) -> Bool

    /// Returns the progress to redirect to the previous position.
    ///
    /// The progress is represented by a floating-point value between 0.0 and 1.0, inclusive, where 1.0 indicates the floating panel is impossible to move to the next position. The default value is 0.5. Values less than 0.0 and greater than 1.0 are pinned to those limits.
    @objc optional
    func redirectionalProgress(_ fpc: FloatingPanelController, from: FloatingPanelState, to: FloatingPanelState) -> CGFloat

    /// Asks the behavior whether the rubber band effect is enabled in moving over a given edge of the surface view.
    ///
    /// This method allows the behavior to activate the rubber band effect to a given edge of the surface view. By default, the effect is disabled.
    @objc optional
    func allowsRubberBanding(for edge: UIRectEdge) -> Bool
}

class FloatingPanelDefaultBehavior: FloatingPanelBehavior {
    var springDecelerationRate: CGFloat {
        return UIScrollView.DecelerationRate.fast.rawValue + 0.001
    }

    var springResponseTime: CGFloat {
        return 0.4
    }

    var momentumProjectionRate: CGFloat {
        return UIScrollView.DecelerationRate.normal.rawValue
    }

    func redirectionalProgress(_ fpc: FloatingPanelController, from: FloatingPanelState, to: FloatingPanelState) -> CGFloat {
        return 0.5
    }

    func addPanelAnimator(_ fpc: FloatingPanelController, to: FloatingPanelState) -> UIViewPropertyAnimator {
        return UIViewPropertyAnimator(duration: 0.0,
                                      timingParameters: UISpringTimingParameters(decelerationRate: UIScrollView.DecelerationRate.fast.rawValue,
                                                                                 frequencyResponse: 0.25))
    }

    func removePanelAnimator(_ fpc: FloatingPanelController, from: FloatingPanelState, with velocity: CGVector) -> UIViewPropertyAnimator {
        return UIViewPropertyAnimator(duration: 0.0,
                                      timingParameters: UISpringTimingParameters(decelerationRate: UIScrollView.DecelerationRate.fast.rawValue,
                                                                                 frequencyResponse: 0.25,
                                                                                 initialVelocity: velocity))
    }

    func allowsRubberBanding(for edge: UIRectEdge) -> Bool {
        return false
    }
}

class FloatingPanelBehaviorAdapter {
    unowned let vc: FloatingPanelController
    fileprivate var behavior: FloatingPanelBehavior

    init(vc: FloatingPanelController, behavior: FloatingPanelBehavior) {
        self.vc = vc
        self.behavior = behavior
    }

    var springDecelerationRate: CGFloat {
        behavior.springDecelerationRate ?? FloatingPanelDefaultBehavior().springDecelerationRate
    }

    var springResponseTime: CGFloat {
        behavior.springResponseTime ?? FloatingPanelDefaultBehavior().springResponseTime
    }

    var momentumProjectionRate: CGFloat {
        behavior.momentumProjectionRate ?? FloatingPanelDefaultBehavior().momentumProjectionRate
    }

    func redirectionalProgress(from: FloatingPanelState, to: FloatingPanelState) -> CGFloat {
        behavior.redirectionalProgress?(vc, from: from, to: to) ?? FloatingPanelDefaultBehavior().redirectionalProgress(vc,from: from, to: to)
    }

    func shouldProjectMomentum(to: FloatingPanelState) -> Bool {
        behavior.shouldProjectMomentum?(vc, to: to) ?? false
    }

    func allowsRubberBanding(for edge: UIRectEdge) -> Bool {
        behavior.allowsRubberBanding?(for: edge) ?? false
    }
}

extension FloatingPanelController {
    var _behavior: FloatingPanelBehavior {
        get { floatingPanel.behaviorAdapter.behavior }
        set { floatingPanel.behaviorAdapter.behavior = newValue}
    }
}
