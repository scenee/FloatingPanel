//
//  Created by Shin Yamamoto on 2018/09/27.
//  Copyright © 2018 Shin Yamamoto. All rights reserved.
//

import UIKit

public protocol FloatingPanelLayout: class {
    /// Returns the initial position of a floating panel.
    var initialPosition: FloatingPanelPosition { get }
    
    /// Returns a set of FloatingPanelPosition objects to tell the applicable positions of the floating panel controller. Default is all of them.
    var supportedPositions: Set<FloatingPanelPosition> { get }
    
    /// Return the interaction buffer to the top from the top position. Default is 6.0.
    var topInteractionBuffer: CGFloat { get }
    
    /// Return the interaction buffer to the bottom from the bottom position. Default is 6.0.
    var bottomInteractionBuffer: CGFloat { get }
    
    var containedHeight: CGFloat? { get }
    
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
    var backdropAlpha: CGFloat { return 0.3 }
    var topInteractionBuffer: CGFloat { return 6.0 }
    var bottomInteractionBuffer: CGFloat { return 6.0 }
    var containedHeight: CGFloat? { return nil }
    
    public var supportedPositions: Set<FloatingPanelPosition> {
        return Set(FloatingPanelPosition.allCases)
    }
    
    func prepareLayout(surfaceView: UIView, in view: UIView) -> [NSLayoutConstraint] {
        return [surfaceView.leftAnchor.constraint(equalTo: view.sideLayoutGuide.leftAnchor, constant: 0.0),
                surfaceView.rightAnchor.constraint(equalTo: view.sideLayoutGuide.rightAnchor, constant: 0.0)]
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
    
    public func prepareLayout(surfaceView: UIView, in view: UIView) -> [NSLayoutConstraint] {
        return [surfaceView.leftAnchor.constraint(equalTo: view.sideLayoutGuide.leftAnchor, constant: 0.0),
                surfaceView.rightAnchor.constraint(equalTo: view.sideLayoutGuide.rightAnchor, constant: 0.0)]
    }
}

class FloatingPanelLayoutAdapter {
    private weak var parent: UIViewController!
    private weak var surfaceView: FloatingPanelSurfaceView!
    private weak var backdropView: FloatingPanelBackdropView!
    
    var layout: FloatingPanelLayout {
        didSet { checkLayoutConsistance() }
    }
    
    var safeAreaInsets: UIEdgeInsets = .zero {
        didSet {
            if safeAreaInsets != oldValue {
                updateHeight()
            }
        }
    }
    
    private var heightBuffer: CGFloat = 88.0 // For bounce
    private var fixedConstraints: [NSLayoutConstraint] = []
    private var fullConstraints: [NSLayoutConstraint] = []
    private var halfConstraints: [NSLayoutConstraint] = []
    private var tipConstraints: [NSLayoutConstraint] = []
    private var offConstraints: [NSLayoutConstraint] = []
    private var heightConstraints: NSLayoutConstraint?
    
    private var _previousFullInset: CGFloat?
    
    private var isHigherThanTopPadding: Bool {
        let topY = safeAreaInsets.top + (layout.insetFor(position: .full) ?? 0.0)
        let bottomY = safeAreaInsets.bottom
        return (surfaceView.superview!.bounds.height - topY) < (layout.containedHeight ?? 0.0) + bottomY
    }
    
    private var fullInset: CGFloat {
        guard let layoutInset = layout.insetFor(position: .full) else {
            if let previousFullInset = _previousFullInset, previousFullInset != 0 {
                _previousFullInset = 0
                updateConstraint(for: .full, with: 0)
            }
            return 0
        }
        
        var additionalInset: CGFloat = 0.0
        
        if let containedHeight = layout.containedHeight {
            let topY = safeAreaInsets.top + layoutInset
            let bottomY = safeAreaInsets.bottom
            additionalInset = surfaceView.superview!.bounds.height - topY - containedHeight - bottomY
        }
        
        // check if we need to update based on changed inset values
        let currentFullInset = isHigherThanTopPadding ? layoutInset : (additionalInset + layoutInset)
        
        let shouldUpdate = (_previousFullInset == nil) || (_previousFullInset! != currentFullInset)
        _previousFullInset = currentFullInset
        
        if shouldUpdate {
            updateConstraint(for: .full, with: currentFullInset)
        }
        
        if let containedHeight = layout.containedHeight {
            updateHeight(with: isHigherThanTopPadding ? layoutInset : UIScreen.main.bounds.height - (safeAreaInsets.top + containedHeight + safeAreaInsets.bottom))
        }
        
        return currentFullInset
    }
    
    private var _previousHalfInset: CGFloat?
    private var halfInset: CGFloat {
        let currentHalfInset = layout.insetFor(position: .half) ?? 0.0
        
        let shouldUpdate = (_previousHalfInset == nil) || (_previousHalfInset! != currentHalfInset)
        _previousHalfInset = currentHalfInset
        
        if shouldUpdate {
            updateConstraint(for: .half, with: currentHalfInset)
            updateHeight()
        }
        
        return currentHalfInset
    }
    
    private var _previousTipInset: CGFloat?
    private var tipInset: CGFloat {
        let currentTipInset = layout.insetFor(position: .tip) ?? 0.0
        
        let shouldUpdate = (_previousTipInset == nil) || (_previousTipInset! != currentTipInset)
        _previousTipInset = currentTipInset
        
        if shouldUpdate {
            updateConstraint(for: .tip, with: currentTipInset)
        }
        
        return currentTipInset
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
    
    func prepareLayout(toParent parent: UIViewController, in containerView: UIView? = nil) {
        self.parent = parent
        
        surfaceView.translatesAutoresizingMaskIntoConstraints = false
        backdropView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.deactivate(fixedConstraints + fullConstraints + halfConstraints + tipConstraints + offConstraints)
        
        let mainView = containerView ?? parent.view!
        
        // Fixed constraints of surface and backdrop views
        let surfaceConstraints = layout.prepareLayout(surfaceView: surfaceView, in: mainView)
        let backdroptConstraints = [backdropView.topAnchor.constraint(equalTo: mainView.topAnchor,
                                                                      constant: 0.0),
                                    backdropView.leftAnchor.constraint(equalTo: mainView.leftAnchor,
                                                                       constant: 0.0),
                                    backdropView.rightAnchor.constraint(equalTo: mainView.rightAnchor,
                                                                        constant: 0.0),
                                    backdropView.bottomAnchor.constraint(equalTo: mainView.bottomAnchor,
                                                                         constant: 0.0)]
        fixedConstraints = surfaceConstraints + backdroptConstraints
        
        // Flexible surface constarints for full, half, tip and off
        fullConstraints = [surfaceView.topAnchor.constraint(equalTo: parent.layoutGuide.topAnchor,
                                                            constant: fullInset)]
        halfConstraints = [surfaceView.topAnchor.constraint(equalTo: parent.layoutGuide.bottomAnchor,
                                                            constant: -halfInset)]
        tipConstraints = [surfaceView.topAnchor.constraint(equalTo: parent.view.bottomAnchor,
                                                           constant: -tipInset)]
        offConstraints = [surfaceView.topAnchor.constraint(equalTo: parent.layoutGuide.bottomAnchor, constant: 0.0)]
    }
    
    private func updateConstraint(for position: FloatingPanelPosition, with constant: CGFloat) {
        switch position {
        case .full: fullConstraints.first?.constant = constant
        case .half: halfConstraints.first?.constant = -constant // Check
        case .tip: tipConstraints.first?.constant = -constant // Check
        }
        
        updateHeight()
    }
    
    // The method is separated from prepareLayout(to:) for the rotation support
    // It must be called in FloatingPanelController.traitCollectionDidChange(_:)
    func updateHeight(with fullInset: CGFloat? = nil) {
        defer {
            UIView.performWithoutAnimation {
                surfaceView.superview?.layoutIfNeeded()
            }
        }
        
        let height = (self.parent?.view.bounds.height ?? UIScreen.main.bounds.height) - (safeAreaInsets.top + (fullInset ?? self.fullInset))

        if let consts = self.heightConstraints {
            // dont know if internally guards against same value update
            if consts.constant != height {
                consts.constant = height
            }
            
        } else {
            let consts = surfaceView.heightAnchor.constraint(equalToConstant: height)
            consts.priority = UILayoutPriority(rawValue: 750)
            
            NSLayoutConstraint.activate([consts])
            heightConstraints = consts
            surfaceView.set(bottomOverflow: heightBuffer)
        }
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
        
        if halfInset > 0 {
            assert(halfInset > tipInset, "Invalid half and tip insets")
        }
        if fullInset > 0 {
            assert(middleY > topY, "Invalid insets")
            assert(bottomY > topY, "Invalid insets")
        }
    }
}
