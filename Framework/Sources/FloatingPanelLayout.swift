//
//  Created by Shin Yamamoto on 2018/09/27.
//  Copyright © 2018 Shin Yamamoto. All rights reserved.
//

import UIKit

/// FloatingPanelFullScreenLayout
///
/// Use the layout protocol if you want to configure a full inset from Superview.Top, not SafeArea.Top.
/// It can't be used with FloatingPanelIntrinsicLayout.
public protocol FloatingPanelFullScreenLayout: FloatingPanelLayout { }

/// FloatingPanelIntrinsicLayout
///
/// Use the layout protocol if you want to layout a panel using the intrinsic height.
/// It can't be used with FloatingPanelFullScreenLayout.
///
/// - Attention:
///     `insetFor(position:)` must return `nil` for the full position. Because
///     the inset is determined automatically by the intrinsic height.
///     You can customize insets only for the half, tip and hidden positions.
public protocol FloatingPanelIntrinsicLayout: FloatingPanelLayout { }

public extension FloatingPanelIntrinsicLayout {
    var initialPosition: FloatingPanelPosition {
        return .full
    }

    var supportedPositions: Set<FloatingPanelPosition> {
        return [.full]
    }

    func insetFor(position: FloatingPanelPosition) -> CGFloat? {
        return nil
    }
}

public protocol FloatingPanelLayout: class {
    /// Returns the initial position of a floating panel.
    var initialPosition: FloatingPanelPosition { get }

    /// Returns a set of FloatingPanelPosition objects to tell the applicable
    /// positions of the floating panel controller.
    ///
    /// By default, it returns all position except for `hidden` position. Because
    /// it's always supported by `FloatingPanelController` so you don't need to return it.
    var supportedPositions: Set<FloatingPanelPosition> { get }

    /// Return the interaction buffer to the top from the top position. Default is 6.0.
    var topInteractionBuffer: CGFloat { get }

    /// Return the interaction buffer to the bottom from the bottom position. Default is 6.0.
    var bottomInteractionBuffer: CGFloat { get }

    /// Returns a CGFloat value to determine a Y coordinate of a floating panel for each position(full, half, tip and hidden).
    ///
    /// Its returning value indicates a different inset for each position.
    /// For full position, a top inset from a safe area in `FloatingPanelController.view`.
    /// For half or tip position, a bottom inset from the safe area.
    /// For hidden position, a bottom inset from `FloatingPanelController.view`.
    /// If a position isn't supported or the default value is used, return nil.
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
        return Set([.full, .half, .tip])
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
    public var initialPosition: FloatingPanelPosition {
        return .half
    }

    public func insetFor(position: FloatingPanelPosition) -> CGFloat? {
        switch position {
        case .full: return 18.0
        case .half: return 262.0
        case .tip: return 69.0
        case .hidden: return nil
        }
    }
}

public class FloatingPanelDefaultLandscapeLayout: FloatingPanelLayout {
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
    weak var vc: UIViewController!
    private weak var surfaceView: FloatingPanelSurfaceView!
    private weak var backdropView: FloatingPanelBackdropView!

    var layout: FloatingPanelLayout {
        didSet {
            checkLayoutConsistance()
        }
    }

    var safeAreaInsets: UIEdgeInsets = .zero

    private var initialConst: CGFloat = 0.0

    private var fixedConstraints: [NSLayoutConstraint] = []
    private var fullConstraints: [NSLayoutConstraint] = []
    private var halfConstraints: [NSLayoutConstraint] = []
    private var tipConstraints: [NSLayoutConstraint] = []
    private var offConstraints: [NSLayoutConstraint] = []
    private var interactiveTopConstraint: NSLayoutConstraint?

    private var heightConstraint: NSLayoutConstraint?

    private var fullInset: CGFloat {
        if layout is FloatingPanelIntrinsicLayout {
            return intrinsicHeight
        } else {
            return layout.insetFor(position: .full) ?? 0.0
        }
    }
    private var halfInset: CGFloat {
        return layout.insetFor(position: .half) ?? 0.0
    }
    private var tipInset: CGFloat {
        return layout.insetFor(position: .tip) ?? 0.0
    }
    private var hiddenInset: CGFloat {
        return layout.insetFor(position: .hidden) ?? 0.0
    }

    var supportedPositions: Set<FloatingPanelPosition> {
        var supportedPositions = layout.supportedPositions
        supportedPositions.remove(.hidden)
        return supportedPositions
    }

    var topY: CGFloat {
        if supportedPositions.contains(.full) {
            switch layout {
            case is FloatingPanelIntrinsicLayout:
                return surfaceView.superview!.bounds.height - surfaceView.bounds.height
            case is FloatingPanelFullScreenLayout:
                return fullInset
            default:
                return (safeAreaInsets.top + fullInset)
            }
        } else {
            return middleY
        }
    }

    var middleY: CGFloat {
        return surfaceView.superview!.bounds.height - (safeAreaInsets.bottom + halfInset)
    }

    var bottomY: CGFloat {
        if supportedPositions.contains(.tip) {
            return surfaceView.superview!.bounds.height - (safeAreaInsets.bottom + tipInset)
        } else {
            return middleY
        }
    }

    var hiddenY: CGFloat {
        return surfaceView.superview!.bounds.height
    }

    var safeAreaBottomY: CGFloat {
        return surfaceView.superview!.bounds.height - (safeAreaInsets.bottom + hiddenInset)
    }

    var topMaxY: CGFloat {
        return layout is FloatingPanelFullScreenLayout ? 0.0 : safeAreaInsets.top
    }
    var bottomMaxY: CGFloat { return safeAreaBottomY }

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
        case .hidden:
            return hiddenY
        }
    }

    var intrinsicHeight: CGFloat = 0.0

    init(surfaceView: FloatingPanelSurfaceView, backdropView: FloatingPanelBackdropView, layout: FloatingPanelLayout) {
        self.layout = layout
        self.surfaceView = surfaceView
        self.backdropView = backdropView
    }

    func updateIntrinsicHeight() {
        let fittingSize = UILayoutFittingCompressedSize
        var intrinsicHeight = surfaceView.contentView?.systemLayoutSizeFitting(fittingSize).height ?? 0.0
        var safeAreaBottom: CGFloat = 0.0
        if #available(iOS 11.0, *) {
            safeAreaBottom = surfaceView.contentView?.safeAreaInsets.bottom ?? 0.0
            if safeAreaBottom > 0 {
                intrinsicHeight -= safeAreaInsets.bottom
            }
        }
        self.intrinsicHeight = max(intrinsicHeight, 0.0)

        log.debug("Update intrinsic height =", intrinsicHeight,
                  ", surface(height) =", surfaceView.frame.height,
                  ", content(height) =", surfaceView.contentView?.frame.height ?? 0.0,
                  ", content safe area(bottom) =", safeAreaBottom)
    }

    func prepareLayout(in vc: UIViewController) {
        self.vc = vc

        NSLayoutConstraint.deactivate(fixedConstraints + fullConstraints + halfConstraints + tipConstraints + offConstraints)

        surfaceView.translatesAutoresizingMaskIntoConstraints = false
        backdropView.translatesAutoresizingMaskIntoConstraints = false

        // Fixed constraints of surface and backdrop views
        let surfaceConstraints = layout.prepareLayout(surfaceView: surfaceView, in: vc.view!)
        let backdropConstraints = [
            backdropView.topAnchor.constraint(equalTo: vc.view.topAnchor, constant: 0.0),
            backdropView.leftAnchor.constraint(equalTo: vc.view.leftAnchor,constant: 0.0),
            backdropView.rightAnchor.constraint(equalTo: vc.view.rightAnchor, constant: 0.0),
            backdropView.bottomAnchor.constraint(equalTo: vc.view.bottomAnchor, constant: 0.0),
            ]

        fixedConstraints = surfaceConstraints + backdropConstraints

        // Flexible surface constarints for full, half, tip and off
        switch layout {
        case is FloatingPanelIntrinsicLayout:
            // Set up on updateHeight()
            break
        case is FloatingPanelFullScreenLayout:
            fullConstraints = [
                surfaceView.topAnchor.constraint(equalTo: vc.view.topAnchor,
                                                 constant: fullInset),
            ]
        default:
            fullConstraints = [
                surfaceView.topAnchor.constraint(equalTo: vc.layoutGuide.topAnchor,
                                                 constant: fullInset),
            ]
        }

        halfConstraints = [
            surfaceView.topAnchor.constraint(equalTo: vc.layoutGuide.bottomAnchor,
                                             constant: -halfInset),
        ]
        tipConstraints = [
            surfaceView.topAnchor.constraint(equalTo: vc.layoutGuide.bottomAnchor,
                                             constant: -tipInset),
        ]
        offConstraints = [
            surfaceView.topAnchor.constraint(equalTo: vc.view.bottomAnchor,
                                             constant: -hiddenInset),
        ]
    }

    func startInteraction(at state: FloatingPanelPosition) {
        NSLayoutConstraint.deactivate(fullConstraints + halfConstraints + tipConstraints + offConstraints)

        let interactiveTopConstraint: NSLayoutConstraint
        switch layout {
        case is FloatingPanelIntrinsicLayout, is FloatingPanelFullScreenLayout:
            initialConst = surfaceView.frame.minY
            interactiveTopConstraint = surfaceView.topAnchor.constraint(equalTo: vc.view.topAnchor,
                                                                        constant: initialConst)
        default:
            initialConst = surfaceView.frame.minY - safeAreaInsets.top
            interactiveTopConstraint = surfaceView.topAnchor.constraint(equalTo: vc.layoutGuide.topAnchor,
                                                                        constant: initialConst)
        }
        NSLayoutConstraint.activate([interactiveTopConstraint])
        self.interactiveTopConstraint = interactiveTopConstraint
    }

    func endInteraction(at state: FloatingPanelPosition) {
        // Don't deacitvate `interactiveTopConstraint` here because it leads to
        // unsatisfiable constraints
    }

    // The method is separated from prepareLayout(to:) for the rotation support
    // It must be called in FloatingPanelController.traitCollectionDidChange(_:)
    func updateHeight() {
        guard let vc = vc else { return }

        if let const = self.heightConstraint {
            NSLayoutConstraint.deactivate([const])
        }

        let heightConstraint: NSLayoutConstraint

        switch layout {
        case is FloatingPanelIntrinsicLayout:
            updateIntrinsicHeight()
            heightConstraint = surfaceView.heightAnchor.constraint(equalToConstant: intrinsicHeight + safeAreaInsets.bottom)
        case is FloatingPanelFullScreenLayout:
            heightConstraint =  surfaceView.heightAnchor.constraint(equalTo: vc.view.heightAnchor,
                                                                    constant: -fullInset)
        default:
            heightConstraint = surfaceView.heightAnchor.constraint(equalTo: vc.view.heightAnchor,
                                                                   constant: -(safeAreaInsets.top + fullInset))
        }

        NSLayoutConstraint.activate([heightConstraint])
        self.heightConstraint = heightConstraint

        surfaceView.bottomOverflow = vc.view.bounds.height + layout.topInteractionBuffer

        if layout is FloatingPanelIntrinsicLayout {
            NSLayoutConstraint.deactivate(fullConstraints)
            fullConstraints = [
                surfaceView.topAnchor.constraint(equalTo: vc.layoutGuide.bottomAnchor,
                                                 constant: -fullInset),
            ]
        }
    }

    func updateInteractiveTopConstraint(diff: CGFloat) {
        defer {
            surfaceView.superview!.layoutIfNeeded()
        }
        let minY: CGFloat = {
            switch layout {
            case is FloatingPanelIntrinsicLayout:
                return topY - layout.topInteractionBuffer
            default:
                return fullInset - layout.topInteractionBuffer
            }
        }()
        let maxY: CGFloat = {
            switch layout {
            case is FloatingPanelIntrinsicLayout, is FloatingPanelFullScreenLayout:
                return bottomY + layout.bottomInteractionBuffer
            default:
                return bottomY - safeAreaInsets.top + layout.bottomInteractionBuffer
            }
        }()
        let const = initialConst + diff

        interactiveTopConstraint?.constant = max(minY, min(maxY, const))
    }

    func activateLayout(of state: FloatingPanelPosition) {
        defer {
            surfaceView.superview!.layoutIfNeeded()
        }

        var state = state

        setBackdropAlpha(of: state)

        // Must deactivate `interactiveTopConstraint` here
        if let interactiveTopConstraint = interactiveTopConstraint {
            NSLayoutConstraint.deactivate([interactiveTopConstraint])
            self.interactiveTopConstraint = nil
        }
        NSLayoutConstraint.activate(fixedConstraints)

        if supportedPositions.union([.hidden]).contains(state) == false {
            state = layout.initialPosition
        }

        NSLayoutConstraint.deactivate(fullConstraints + halfConstraints + tipConstraints + offConstraints)
        switch state {
        case .full:
            NSLayoutConstraint.activate(fullConstraints)
        case .half:
            NSLayoutConstraint.activate(halfConstraints)
        case .tip:
            NSLayoutConstraint.activate(tipConstraints)
        case .hidden:
            NSLayoutConstraint.activate(offConstraints)
        }
    }

    private func setBackdropAlpha(of target: FloatingPanelPosition) {
        if target == .hidden {
            self.backdropView.alpha = 0.0
        } else {
            self.backdropView.alpha = layout.backdropAlphaFor(position: target)
        }
    }

    private func checkLayoutConsistance() {
        // Verify layout configurations
        assert(supportedPositions.count > 0)
        assert(supportedPositions.contains(layout.initialPosition),
               "Does not include an initial potision(\(layout.initialPosition)) in supportedPositions(\(supportedPositions))")

        if layout is FloatingPanelIntrinsicLayout {
            assert(layout.insetFor(position: .full) == nil, "Return `nil` for full position on FloatingPanelIntrinsicLayout")
        }

        if halfInset > 0 {
            assert(halfInset > tipInset, "Invalid half and tip insets")
        }
        // The verification isn't working on orientation change(portrait -> landscape)
        // of a floating panel in tab bar. Because the `safeAreaInsets.bottom` is
        // updated in delay so that it can be 83.0(not 53.0) even after the surface
        // and the super view's frame is fit to landscape already.
        /*if fullInset > 0 {
            assert(middleY > topY, "Invalid insets { topY: \(topY), middleY: \(middleY) }")
            assert(bottomY > topY, "Invalid insets { topY: \(topY), bottomY: \(bottomY) }")
         }*/
    }
}
