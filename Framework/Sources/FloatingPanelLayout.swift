//
//  Created by Shin Yamamoto on 2018/09/27.
//  Copyright © 2018 Shin Yamamoto. All rights reserved.
//

import UIKit

public protocol FloatingPanelLayout: class {
    /// Returns the initial position of a floating panel
    var initialPosition: FloatingPanelPosition { get }
    /// Returns an array of FloatingPanelPosition object to tell the applicable position the floating panel controller
    var supportedPositions: [FloatingPanelPosition] { get }

    /// Return the interaction buffer of full position. Default is 6.0.
    var topInteractionBuffer: CGFloat { get }
    /// Return the interaction buffer of full position. Default is 6.0.
    var bottomInteractionBuffer: CGFloat { get }

    /// Returns a CGFloat value for a floating panel position(full, half, tip).
    /// A value for full position indicates an inset from the safe area top.
    /// On the other hand, values fro half and tip positions indicate insets from the safe area bottom.
    /// If a position doesn't contain the supported positions, return nil.
    func insetFor(position: FloatingPanelPosition) -> CGFloat?
    /// Returns layout constraints for a surface view of a floaitng panel.
    /// The layout constraints must not include ones for topAnchor and bottomAnchor
    /// because constarints for them will be added by the floating panel controller.
    func prepareLayout(surfaceView: UIView, in view: UIView) -> [NSLayoutConstraint]

    /// Return the backdrop alpha of black color in full position. Default is 0.3.
    var backdropAlpha: CGFloat { get }
}

public extension FloatingPanelLayout {
    var backdropAlpha: CGFloat { return 0.3 }
    var topInteractionBuffer: CGFloat { return 6.0 }
    var bottomInteractionBuffer: CGFloat { return 6.0 }
}

public class FloatingPanelDefaultLayout: FloatingPanelLayout {
    public var supportedPositions: [FloatingPanelPosition] {
        return [.full, .half, .tip]
    }

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

    public func prepareLayout(surfaceView: UIView, in view: UIView) -> [NSLayoutConstraint] {
        return [
            surfaceView.leftAnchor.constraint(equalTo: view.sideLayoutGuide.leftAnchor, constant: 0.0),
            surfaceView.rightAnchor.constraint(equalTo: view.sideLayoutGuide.rightAnchor, constant: 0.0),
        ]
    }
}

public class FloatingPanelDefaultLandscapeLayout: FloatingPanelLayout {
    public var initialPosition: FloatingPanelPosition {
        return .tip
    }
    public var supportedPositions: [FloatingPanelPosition] {
        return [.full, .tip]
    }

    public func insetFor(position: FloatingPanelPosition) -> CGFloat? {
        switch position {
        case .full: return 16.0
        case .tip: return 69.0
        default: return nil
        }
    }

    public func prepareLayout(surfaceView: UIView, in view: UIView) -> [NSLayoutConstraint] {
        return [
            surfaceView.leftAnchor.constraint(equalTo: view.sideLayoutGuide.leftAnchor, constant: 8.0),
            surfaceView.widthAnchor.constraint(equalToConstant: 291),
            ]
    }
}


class FloatingPanelLayoutAdapter {
    private weak var surfaceView: FloatingPanelSurfaceView!
    private weak var backdropVIew: FloatingPanelBackdropView!

    var layout: FloatingPanelLayout

    var safeAreaInsets: UIEdgeInsets = .zero

    private var heightBuffer: CGFloat = 88.0 // For bounce
    private var fixedConstraints: [NSLayoutConstraint] = []
    private var fullConstraints: [NSLayoutConstraint] = []
    private var halfConstraints: [NSLayoutConstraint] = []
    private var tipConstraints: [NSLayoutConstraint] = []
    private var offConstraints: [NSLayoutConstraint] = []
    private var heightConstraints: NSLayoutConstraint? = nil

    var topInset: CGFloat {
        return layout.insetFor(position: .full) ?? 0.0
    }
    var halfInset: CGFloat {
        return layout.insetFor(position: .half) ?? 0.0
    }
    var tipInset: CGFloat {
        return layout.insetFor(position: .tip) ?? 0.0
    }

    var topY: CGFloat {
        return (safeAreaInsets.top + topInset)
    }

    var middleY: CGFloat {
        return surfaceView.superview!.bounds.height - (safeAreaInsets.bottom + halfInset)
    }

    var bottomY: CGFloat {
        return surfaceView.superview!.bounds.height - (safeAreaInsets.bottom + tipInset)
    }

    var adjustedContentInsets: UIEdgeInsets {
        return UIEdgeInsets(top: 0.0,
                            left: 0.0,
                            bottom: (safeAreaInsets.top + topInset) + (heightBuffer + safeAreaInsets.bottom),
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
        self.backdropVIew = backdropView

        // Verify layout configurations
        assert(layout.supportedPositions.count > 1)
        assert(layout.supportedPositions.contains(layout.initialPosition))
        if halfInset > 0 {
            assert(halfInset >= tipInset)
        }
    }

    func prepareLayout(toParent parent: UIViewController) {
        surfaceView.translatesAutoresizingMaskIntoConstraints = false
        backdropVIew.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.deactivate(fixedConstraints + fullConstraints + halfConstraints + tipConstraints + offConstraints)

        // Fixed constraints of surface and backdrop views
        let surfaceConstraints = layout.prepareLayout(surfaceView: surfaceView, in: parent.view!)
        let backdroptConstraints = [
            backdropVIew.topAnchor.constraint(equalTo: parent.view.topAnchor,
                                              constant: 0.0),
            backdropVIew.leftAnchor.constraint(equalTo: parent.view.leftAnchor,
                                               constant: 0.0),
            backdropVIew.rightAnchor.constraint(equalTo: parent.view.rightAnchor,
                                                constant: 0.0),
            backdropVIew.bottomAnchor.constraint(equalTo: parent.view.bottomAnchor,
                                                 constant: 0.0),
            ]
        fixedConstraints = surfaceConstraints + backdroptConstraints

        // Flexible surface constarints for full, half, tip and off
        fullConstraints = [
            surfaceView.topAnchor.constraint(equalTo: parent.layoutGuide.topAnchor,
                                             constant: topInset),
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
            surfaceView.topAnchor.constraint(equalTo: parent.layoutGuide.bottomAnchor, constant: 0.0),
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

        if let heightConstraints = self.heightConstraints {
            NSLayoutConstraint.deactivate([heightConstraints])
        }
        let heightConstraints = surfaceView.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.height + heightBuffer)
        NSLayoutConstraint.activate([heightConstraints])
        self.heightConstraints = heightConstraints
    }

    func activateLayout(of state: FloatingPanelPosition?) {
        defer {
            surfaceView.superview!.layoutIfNeeded()
        }

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
}
