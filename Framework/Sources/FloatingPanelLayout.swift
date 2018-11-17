//
//  Created by Shin Yamamoto on 2018/09/27.
//  Copyright © 2018 Shin Yamamoto. All rights reserved.
//

import UIKit

public protocol FloatingPanelIntrinsicLayout: FloatingPanelLayout {
    /// Return the viewController that is being displaying the content
    var contentViewController: UIViewController? { get set }
}

public extension FloatingPanelIntrinsicLayout {
    var intrinsicHeight: CGFloat {
        assert(contentViewController != nil, "Cannot use this if this...")
        let fittingSize = UIView.layoutFittingCompressedSize
        return contentViewController!.view.systemLayoutSizeFitting(fittingSize).height
    }
}

public protocol FloatingPanelLayout: class {
    /// Returns the initial position of a floating panel.
    var initialPosition: FloatingPanelPosition { get }

    /// Returns a set of FloatingPanelPosition objects to tell the applicable positions of the floating panel controller. Default is all of them.
    var supportedPositions: Set<FloatingPanelPosition> { get }

    /// Return the interaction buffer to the top from the top position. Default is 6.0.
    var topInteractionBuffer: CGFloat { get }

    /// Return the interaction buffer to the bottom from the bottom position. Default is 6.0.
    var bottomInteractionBuffer: CGFloat { get }

    /// Returns a CGFloat value to determine a floating panel height for each position(full, half and tip).
    /// A value for full position indicates a top inset from a safe area.
    /// On the other hand, values for half and tip positions indicate bottom insets from a safe area.
    /// If a position doesn't contain the supported positions, return nil.
    func insetFor(position: FloatingPanelPosition) -> CGFloat?

    /// Returns X-axis and width layout constraints of the surface view of a floating panel.
    /// You must not include any Y-axis and height layout constraints of the surface view
    /// because their constraints will be configured by the floating panel controller.
    /// By default, the width of a surface view fits a safe area.
    func prepareLayout(surfaceView: UIView, in view: UIView) -> [NSLayoutConstraint]

    /// Returns a CGFloat value to determine the backdrop view's alpha for a position.
    ///
    /// Default is 0.3 at full position, otherwise 0.0.
    func backdropAlphaFor(position: FloatingPanelPosition) -> CGFloat
}

public extension FloatingPanelLayout {
    var topInteractionBuffer: CGFloat { return 6.0 }
    var bottomInteractionBuffer: CGFloat { return 6.0 }

    var supportedPositions: Set<FloatingPanelPosition> {
        return Set(FloatingPanelPosition.allCases)
    }
    
    func prepareLayout(surfaceView: UIView, in view: UIView) -> [NSLayoutConstraint] {
        return [
            surfaceView.leftAnchor.constraint(equalTo: view.sideLayoutGuide.leftAnchor, constant: 0.0),
            surfaceView.rightAnchor.constraint(equalTo: view.sideLayoutGuide.rightAnchor, constant: 0.0),
        ]
    }

    func backdropAlphaFor(position: FloatingPanelPosition) -> CGFloat {
        return position == .full ? 0.3 : 0.0
    }
}

public class FloatingPanelDefaultLayout: FloatingPanelLayout {
    public var contentViewController: UIViewController?
    
    public var initialPosition: FloatingPanelPosition {
        return .half
    }

    public func insetFor(position: FloatingPanelPosition) -> CGFloat? {
        switch position {
        case .full: return 18.0
        case .half: return 262.0
        case .tip: return 69.0
        }
    }
}

public class FloatingPanelDefaultLandscapeLayout: FloatingPanelLayout {
    public var contentViewController: UIViewController?
    
    public var initialPosition: FloatingPanelPosition {
        return .tip
    }
    public var supportedPositions: Set<FloatingPanelPosition> {
        return [.full, .tip]
    }

    public func insetFor(position: FloatingPanelPosition) -> CGFloat? {
        switch position {
        case .full: return 16.0
        case .tip: return 69.0
        default: return nil
        }
    }
}


class FloatingPanelLayoutAdapter {
    private weak var parent: UIViewController!
    private weak var surfaceView: FloatingPanelSurfaceView!
    private weak var backdropView: FloatingPanelBackdropView!

    var layout: FloatingPanelLayout {
        didSet {
            checkLayoutConsistance()
        }
    }

    var safeAreaInsets: UIEdgeInsets = .zero {
        didSet {
            updateHeight()
            checkLayoutConsistance()
        }
    }

    private var parentHeight: CGFloat = 0.0
    private var heightBuffer: CGFloat = 88.0 // For bounce
    private var fixedConstraints: [NSLayoutConstraint] = []
    private var fullConstraints: [NSLayoutConstraint] = []
    private var halfConstraints: [NSLayoutConstraint] = []
    private var tipConstraints: [NSLayoutConstraint] = []
    private var offConstraints: [NSLayoutConstraint] = []
    private var heightConstraints: [NSLayoutConstraint] = []

    private var fullInset: CGFloat {
        return layout.insetFor(position: .full) ?? 0.0
    }
    private var halfInset: CGFloat {
        return layout.insetFor(position: .half) ?? 0.0
    }
    private var tipInset: CGFloat {
        return layout.insetFor(position: .tip) ?? 0.0
    }

    var topY: CGFloat {
        if layout.supportedPositions.contains(.full) {
            return (safeAreaInsets.top + fullInset)
        } else {
            return middleY
        }
    }

    var middleY: CGFloat {
        return surfaceView.superview!.bounds.height - (safeAreaInsets.bottom + halfInset)
    }

    var bottomY: CGFloat {
        if layout.supportedPositions.contains(.tip) {
            return surfaceView.superview!.bounds.height - (safeAreaInsets.bottom + tipInset)
        } else {
            return middleY
        }
    }

    var safeAreaBottomY: CGFloat {
        return surfaceView.superview!.bounds.height - (safeAreaInsets.bottom)
    }

    var adjustedContentInsets: UIEdgeInsets {
        return UIEdgeInsets(top: 0.0,
                            left: 0.0,
                            bottom: safeAreaInsets.bottom,
                            right: 0.0)
    }

    func positionY(for pos: FloatingPanelPosition) -> CGFloat {
        switch pos {
        case .full:
            return topY
        case .half:
            return middleY
        case .tip:
            return bottomY
        }
    }

    init(surfaceView: FloatingPanelSurfaceView, backdropView: FloatingPanelBackdropView, layout: FloatingPanelLayout) {
        self.layout = layout
        self.surfaceView = surfaceView
        self.backdropView = backdropView
    }

    func prepareLayout(toParent parent: UIViewController) {
        self.parent = parent

        surfaceView.translatesAutoresizingMaskIntoConstraints = false
        backdropView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.deactivate(fixedConstraints + fullConstraints + halfConstraints + tipConstraints + offConstraints)

        // Fixed constraints of surface and backdrop views
        let surfaceConstraints = layout.prepareLayout(surfaceView: surfaceView, in: parent.view!)
        let backdropConstraints = [
            backdropView.topAnchor.constraint(equalTo: parent.view.topAnchor,
                                              constant: 0.0),
            backdropView.leftAnchor.constraint(equalTo: parent.view.leftAnchor,
                                               constant: 0.0),
            backdropView.rightAnchor.constraint(equalTo: parent.view.rightAnchor,
                                                constant: 0.0),
            backdropView.bottomAnchor.constraint(equalTo: parent.view.bottomAnchor,
                                                 constant: 0.0),
            ]
        fixedConstraints = surfaceConstraints + backdropConstraints

        // Flexible surface constarints for full, half, tip and off
        fullConstraints = [
            surfaceView.topAnchor.constraint(equalTo: parent.layoutGuide.topAnchor,
                                             constant: fullInset),
        ]
        halfConstraints = [
            surfaceView.topAnchor.constraint(equalTo: parent.layoutGuide.bottomAnchor,
                                             constant: -halfInset),
        ]
        tipConstraints = [
            surfaceView.topAnchor.constraint(equalTo: parent.layoutGuide.bottomAnchor,
                                             constant: -tipInset),
        ]
        offConstraints = [
            surfaceView.topAnchor.constraint(equalTo: parent.view.bottomAnchor, constant: 0.0),
        ]
    }

    // The method is separated from prepareLayout(to:) for the rotation support
    // It must be called in FloatingPanelController.traitCollectionDidChange(_:)
    func updateHeight() {
        defer {
            UIView.performWithoutAnimation {
                surfaceView.superview!.layoutIfNeeded()
            }
        }

        NSLayoutConstraint.deactivate(heightConstraints)
        // Must use the parent height, not the screen height because safe area insets
        // of the parent are relative values. For example, a view controller in
        // Navigation controller's safe area insets and frame can be changed whether
        // the navigation bar is translucent or not.
        let height = self.parent.view.bounds.height - (safeAreaInsets.top + fullInset)
        heightConstraints = [
            surfaceView.heightAnchor.constraint(equalToConstant: height)
        ]
        NSLayoutConstraint.activate(heightConstraints)
        surfaceView.set(bottomOverflow: heightBuffer)
    }

    func activateLayout(of state: FloatingPanelPosition?) {
        defer {
            surfaceView.superview!.layoutIfNeeded()
        }
        setBackdropAlpha(of: state)

        NSLayoutConstraint.activate(fixedConstraints)

        guard var state = state else {
            NSLayoutConstraint.deactivate(fullConstraints + halfConstraints + tipConstraints)
            NSLayoutConstraint.activate(offConstraints)
            return
        }

        if layout.supportedPositions.contains(state) == false {
            state = layout.initialPosition
        }

        NSLayoutConstraint.deactivate(fullConstraints + halfConstraints + tipConstraints + offConstraints)
        switch state {
        case .full:
            NSLayoutConstraint.deactivate(halfConstraints + tipConstraints + offConstraints)
            NSLayoutConstraint.activate(fullConstraints)
        case .half:
            NSLayoutConstraint.deactivate(fullConstraints + tipConstraints + offConstraints)
            NSLayoutConstraint.activate(halfConstraints)
        case .tip:
            NSLayoutConstraint.deactivate(fullConstraints + halfConstraints + offConstraints)
            NSLayoutConstraint.activate(tipConstraints)
        }
    }

    func setBackdropAlpha(of target: FloatingPanelPosition?) {
        if let target = target {
            self.backdropView.alpha = layout.backdropAlphaFor(position: target)
        } else {
            self.backdropView.alpha = 0.0
        }
    }

    func checkLayoutConsistance() {
        // Verify layout configurations
        let supportedPositions = layout.supportedPositions

        assert(supportedPositions.count > 0)
        assert(supportedPositions.contains(layout.initialPosition),
               "Does not include an initial potision(\(layout.initialPosition)) in supportedPositions(\(supportedPositions))")

        supportedPositions.forEach { pos in
            assert(layout.insetFor(position: pos) != nil,
                   "Undefined an inset for a pos(\(pos))")
        }
        guard !(layout is FloatingPanelIntrinsicLayout) else { return }
        if halfInset > 0 {
            assert(halfInset > tipInset, "Invalid half and tip insets")
        }
        if fullInset > 0 {
            assert(middleY > topY, "Invalid insets")
            assert(bottomY > topY, "Invalid insets")
        }
    }
}
