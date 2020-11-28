// Copyright 2018-Present Shin Yamamoto. All rights reserved. MIT license.

import UIKit

/// An interface for generating behavior information to fine-tune the behavior of a panel.
@objc
public protocol FloatingPanelBehavior {
    /// A floating-point value that determines the rate of oscillation magnitude reduction after the user lifts their finger.
    ///
    /// The oscillation magnitude to attract a panel to an anchor can be adjusted this value between 0.979 and 1.0
    /// in increments of 0.001. When this value is around 0.979, the attraction uses a critically damped spring system.
    /// When this value is between 0.978 and 1.0, it uses a underdamped spring system with a damping ratio computed by
    /// this value. You shouldn't return less than 0.979 because the system is overdamped. If the pan gesture's velocity
    /// is less than 300, this value is ignored and a panel applies a critically damped system.
    @objc optional
    var springDecelerationRate: CGFloat { get }

    /// A floating-point value that determines the approximate time until a panel stops to an anchor after the user lifts their finger.
    @objc optional
    var springResponseTime: CGFloat { get }

    /// Returns a deceleration rate to calculate a target position projected a dragging momentum.
    ///
    /// The default implementation of this method returns the normal deceleration rate of UIScrollView.
    @objc optional
    var momentumProjectionRate: CGFloat { get }

    /// Asks the behavior if a panel should project a momentum of a user interaction to move the proposed position.
    ///
    /// The default implementation of this method returns true. This method is called for a layout to support all positions(tip, half and full).
    /// Therefore, `proposedTargetPosition` can only be `FloatingPanelState.tip` or `FloatingPanelState.full`.
    @objc optional
    func shouldProjectMomentum(_ fpc: FloatingPanelController, to proposedTargetPosition: FloatingPanelState) -> Bool

    /// Returns the progress to redirect to the previous position.
    ///
    /// The progress is represented by a floating-point value between 0.0 and 1.0, inclusive, where 1.0 indicates a panel is impossible to move to the next position. The default value is 0.5. Values less than 0.0 and greater than 1.0 are pinned to those limits.
    @objc optional
    func redirectionalProgress(_ fpc: FloatingPanelController, from: FloatingPanelState, to: FloatingPanelState) -> CGFloat

    /// Asks the behavior whether the rubber band effect is enabled in moving over a given edge of the surface view.
    ///
    /// This method allows a panel to activate the rubber band effect to a given edge of the surface view. By default, the effect is disabled.
    @objc optional
    func allowsRubberBanding(for edge: UIRectEdge) -> Bool
}

/// The default behavior object for a panel
///
/// This behavior object is fine-tuned to behave as a search panel(card) in Apple Maps on iPhone portrait orientation.
open class FloatingPanelDefaultBehavior: FloatingPanelBehavior {
    public init() {}

    open var springDecelerationRate: CGFloat {
        return UIScrollView.DecelerationRate.fast.rawValue + 0.001
    }

    open var springResponseTime: CGFloat {
        return 0.4
    }

    open var momentumProjectionRate: CGFloat {
        return UIScrollView.DecelerationRate.normal.rawValue
    }

    open func redirectionalProgress(_ fpc: FloatingPanelController, from: FloatingPanelState, to: FloatingPanelState) -> CGFloat {
        return 0.5
    }

    open func allowsRubberBanding(for edge: UIRectEdge) -> Bool {
        return false
    }
}

class BehaviorAdapter {
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
