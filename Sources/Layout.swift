// Copyright 2018-Present Shin Yamamoto. All rights reserved. MIT license.

import UIKit
import os.log

/// An interface for generating layout information for a panel.
@objc public protocol FloatingPanelLayout {
    /// Returns the position of a panel in a `FloatingPanelController` view .
    @objc var position: FloatingPanelPosition { get }

    /// Returns the initial state when a panel is presented.
    @objc var initialState: FloatingPanelState { get }

    /// Returns the layout anchors to specify the snapping locations for each state.
    @objc var anchors: [FloatingPanelState: FloatingPanelLayoutAnchoring] { get }

    /// Returns layout constraints to determine the cross dimension of a panel.
    @objc optional func prepareLayout(surfaceView: UIView, in view: UIView) -> [NSLayoutConstraint]

    /// Returns the alpha value of the backdrop of a panel for each state.
    @objc optional func backdropAlpha(for state: FloatingPanelState) -> CGFloat
}

/// A layout object that lays out a panel in bottom sheet style.
@objcMembers
open class FloatingPanelBottomLayout: NSObject, FloatingPanelLayout {
    public override init() {
        super.init()
    }
    open var initialState: FloatingPanelState {
        return .half
    }

    open var anchors: [FloatingPanelState: FloatingPanelLayoutAnchoring]  {
        return [
            .full: FloatingPanelLayoutAnchor(absoluteInset: 18.0, edge: .top, referenceGuide: .safeArea),
            .half: FloatingPanelLayoutAnchor(fractionalInset: 0.5, edge: .bottom, referenceGuide: .safeArea),
            .tip: FloatingPanelLayoutAnchor(absoluteInset: 69.0, edge: .bottom, referenceGuide: .safeArea),
        ]
    }

    open var position: FloatingPanelPosition {
        return .bottom
    }

    open func prepareLayout(surfaceView: UIView, in view: UIView) -> [NSLayoutConstraint] {
        return [
            surfaceView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 0.0),
            surfaceView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: 0.0),
        ]
    }

    open func backdropAlpha(for state: FloatingPanelState) -> CGFloat {
        return state == .full ? 0.3 : 0.0
    }
}

struct LayoutSegment {
    let lower: FloatingPanelState?
    let upper: FloatingPanelState?
}

class LayoutAdapter {
    private unowned var vc: FloatingPanelController
    private let defaultLayout = FloatingPanelBottomLayout()

    fileprivate var layout: FloatingPanelLayout {
        didSet {
            surfaceView.position = position
        }
    }

    private var surfaceView: SurfaceView {
        return vc.surfaceView
    }
    private var backdropView: BackdropView {
        return vc.backdropView
    }
    private var safeAreaInsets: UIEdgeInsets {
        return vc.fp_safeAreaInsets
    }

    private var initialConst: CGFloat = 0.0

    private var fixedConstraints: [NSLayoutConstraint] = []

    private var stateConstraints: [FloatingPanelState: [NSLayoutConstraint]] = [:]
    private var offConstraints: [NSLayoutConstraint] = []
    private var fitToBoundsConstraint: NSLayoutConstraint?

    private(set) var interactionConstraint: NSLayoutConstraint?
    private(set) var attractionConstraint: NSLayoutConstraint?

    private var staticConstraint: NSLayoutConstraint?

    /// A layout constraint to limit the content size in ``FloatingPanelAdaptiveLayoutAnchor``.
    private var contentBoundingConstraint: NSLayoutConstraint?

    private var anchorStates: Set<FloatingPanelState> {
        return Set(layout.anchors.keys)
    }

    private var sortedAnchorStates: [FloatingPanelState] {
        return anchorStates.sorted(by: {
            return $0.order < $1.order
        })
    }

    var initialState: FloatingPanelState {
        layout.initialState
    }

    var position: FloatingPanelPosition {
        layout.position
    }

    var validStates: Set<FloatingPanelState> {
        return anchorStates.union([.hidden])
    }

    var sortedAnchorStatesByCoordinate: [FloatingPanelState] {
        return anchorStates.sorted(by: {
            switch position {
            case .top, .left:
                return $0.order < $1.order
            case .bottom, .right:
                return $0.order > $1.order
            }
        })
    }

    private var leastCoordinateState: FloatingPanelState {
        return sortedAnchorStatesByCoordinate.first ?? .hidden
    }

    private var mostCoordinateState: FloatingPanelState {
        return sortedAnchorStatesByCoordinate.last ?? .hidden
    }

    var leastExpandedState: FloatingPanelState {
        if sortedAnchorStates.count == 1 {
            return .hidden
        }
        return sortedAnchorStates.first ?? .hidden
    }

    var mostExpandedState: FloatingPanelState {
        if sortedAnchorStates.count == 1 {
            return sortedAnchorStates[0]
        }
        return sortedAnchorStates.last ?? .hidden
    }

    var adjustedContentInsets: UIEdgeInsets {
        switch position {
        case .top:
            return UIEdgeInsets(top: safeAreaInsets.top,
                                left: 0.0,
                                bottom: 0.0,
                                right: 0.0)
        case .left:
            return UIEdgeInsets(top: 0.0,
                                left: safeAreaInsets.left,
                                bottom: 0.0,
                                right: 0.0)
        case .bottom:
            return UIEdgeInsets(top: 0.0,
                                left: 0.0,
                                bottom: safeAreaInsets.bottom,
                                right: 0.0)
        case .right:
            return UIEdgeInsets(top: 0.0,
                                left: 0.0,
                                bottom: 0.0,
                                right: safeAreaInsets.right)
        }
    }

    /*
    Returns a constraint based value in the interaction and animation.

    So that it doesn't need to call `surfaceView.layoutIfNeeded()`
    after every interaction and animation update. It has an effect on
    the smooth interaction because the content view doesn't need to update
    its layout frequently.
    */
    var surfaceLocation: CGPoint {
        get {
            var pos: CGFloat
            if let constraint = interactionConstraint {
                pos = constraint.constant
            } else if let animationConstraint = attractionConstraint, let anchor = layout.anchors[vc.state] {
                switch position {
                case .top, .bottom:
                    switch referenceEdge(of: anchor) {
                    case .top:
                        pos = animationConstraint.constant
                        if anchor.referenceGuide == .safeArea {
                            pos += safeAreaInsets.top
                        }
                    case .bottom:
                        pos = vc.view.bounds.height + animationConstraint.constant
                        if anchor.referenceGuide == .safeArea {
                            pos -= safeAreaInsets.bottom
                        }
                    default:
                        fatalError("Unsupported reference edges")
                    }
                case .left, .right:
                    switch referenceEdge(of: anchor) {
                    case .left:
                        pos = animationConstraint.constant
                        if anchor.referenceGuide == .safeArea {
                            pos += safeAreaInsets.left
                        }
                    case .right:
                        pos = vc.view.bounds.width + animationConstraint.constant
                        if anchor.referenceGuide == .safeArea {
                            pos -= safeAreaInsets.right
                        }
                    default:
                        fatalError("Unsupported reference edges")
                    }
                }
            } else {
                pos = edgePosition(surfaceView.frame).rounded(by: surfaceView.fp_displayScale)
            }
            switch position {
            case .top, .bottom:
                return CGPoint(x: 0.0, y: pos)
            case .left, .right:
                return CGPoint(x: pos, y: 0.0)
            }
        }
        set {
            let pos = position.mainLocation(newValue)
            if let constraint = interactionConstraint {
                constraint.constant = pos
            } else if let animationConstraint = attractionConstraint, let anchor = layout.anchors[vc.state] {
                let refEdge = referenceEdge(of: anchor)
                switch refEdge {
                case .top, .left:
                    animationConstraint.constant = pos
                    if anchor.referenceGuide == .safeArea {
                        animationConstraint.constant -= refEdge.inset(of: safeAreaInsets)
                    }
                case .bottom, .right:
                    animationConstraint.constant = pos - position.mainDimension(vc.view.bounds.size)
                    if anchor.referenceGuide == .safeArea {
                        animationConstraint.constant += refEdge.inset(of: safeAreaInsets)
                    }
                }
            } else {
                switch position {
                case .top:
                    return surfaceView.frame.origin.y = pos - surfaceView.bounds.height
                case .left:
                    return surfaceView.frame.origin.x = pos - surfaceView.bounds.width
                case .bottom:
                    return surfaceView.frame.origin.y = pos
                case .right:
                    return surfaceView.frame.origin.x = pos
                }
            }
        }
    }

    var offsetFromMostExpandedAnchor: CGFloat {
        return offset(from: mostExpandedState)
    }

    /// The distance from the given state position to the current surface location.
    ///
    /// If the returned value is positive, it indicates that the surface is moving from
    /// the given state position to closer to the `hidden` state position. In other
    /// words, the surface is within the given state position. Otherwise, it indicates
    /// that the surface is outside this position and is moving away from the `hidden`
    /// state position.
    func offset(from state: FloatingPanelState) -> CGFloat {
        let offset: CGFloat
        switch position {
        case .top, .left:
            offset = position(for: state) - edgePosition(surfaceView.frame)
        case .bottom, .right:
            offset = edgePosition(surfaceView.frame) - position(for: state)
        }
        return offset.rounded(by: surfaceView.fp_displayScale)
    }

    private var hiddenAnchor: FloatingPanelLayoutAnchoring {
        switch position {
        case .top:
            return FloatingPanelLayoutAnchor(absoluteInset: -100, edge: .top, referenceGuide: .superview)
        case .left:
            return FloatingPanelLayoutAnchor(absoluteInset: -100, edge: .left, referenceGuide: .superview)
        case .bottom:
            return FloatingPanelLayoutAnchor(absoluteInset: -100, edge: .bottom, referenceGuide: .superview)
        case .right:
            return FloatingPanelLayoutAnchor(absoluteInset: -100, edge: .right, referenceGuide: .superview)
        }
    }

    init(vc: FloatingPanelController, layout: FloatingPanelLayout) {
        self.vc = vc
        self.layout = layout
    }

    func surfaceLocation(for state: FloatingPanelState) -> CGPoint {
        let pos = position(for: state).rounded(by: surfaceView.fp_displayScale)
        switch layout.position {
        case .top, .bottom:
            return CGPoint(x: 0.0, y: pos)
        case .left, .right:
            return CGPoint(x: pos, y: 0.0)
        }
    }

    func position(for state: FloatingPanelState) -> CGFloat {
        let bounds = vc.view.bounds
        let anchor = layout.anchors[state] ?? self.hiddenAnchor

        switch anchor {
        case let anchor as FloatingPanelIntrinsicLayoutAnchor:
            let intrinsicLength = position.mainDimension(surfaceView.intrinsicContentSize)
            let diff = anchor.isAbsolute ? anchor.offset : intrinsicLength * anchor.offset

            switch position {
            case .top, .left:
                var base: CGFloat = 0.0
                if anchor.referenceGuide == .safeArea {
                    base += position.inset(safeAreaInsets)
                }
                return base + intrinsicLength - diff
            case .bottom, .right:
                var base = position.mainDimension(bounds.size)
                if anchor.referenceGuide == .safeArea {
                    base -= position.inset(safeAreaInsets)
                }
                return base - intrinsicLength + diff
            }
        case let anchor as FloatingPanelAdaptiveLayoutAnchor:
            let dimension = layout.position.mainDimension(anchor.contentLayoutGuide.layoutFrame.size)
            let diff = anchor.distance(from: dimension)
            var referenceBoundsLength = layout.position.mainDimension(bounds.size)
            switch layout.position {
            case .top, .left:
                if anchor.referenceGuide == .safeArea {
                    referenceBoundsLength += position.inset(safeAreaInsets)
                }
                let maxPosition: CGFloat = {
                    if let maxBounds = anchor.contentBoundingGuide.maxBounds(vc) {
                        return layout.position.mainLocation(maxBounds.origin)
                            + layout.position.mainDimension(maxBounds.size)
                    } else {
                        return .infinity
                    }
                }()
                return min(dimension - diff, maxPosition)
            case .bottom, .right:
                if anchor.referenceGuide == .safeArea {
                    referenceBoundsLength -= position.inset(safeAreaInsets)
                }
                let minPosition: CGFloat = {
                    if let maxBounds = anchor.contentBoundingGuide.maxBounds(vc) {
                        return layout.position.mainLocation(maxBounds.origin)
                    } else {
                        return -(.infinity)
                    }
                }()
                return max(referenceBoundsLength - dimension + diff, minPosition)
            }
        case let anchor as FloatingPanelLayoutAnchor:
            let referenceBounds = anchor.referenceGuide == .safeArea ? bounds.inset(by: safeAreaInsets) : bounds
            let diff = anchor.isAbsolute ? anchor.inset : position.mainDimension(referenceBounds.size) * anchor.inset
            switch anchor.referenceEdge {
            case .top:
                return referenceBounds.minY + diff
            case .left:
                return referenceBounds.minX + diff
            case .bottom:
                return referenceBounds.maxY - diff
            case .right:
                return referenceBounds.maxX - diff
            }
        default:
            fatalError("Unsupported a FloatingPanelLayoutAnchoring object")
        }
    }

    func isIntrinsicAnchor(state: FloatingPanelState) -> Bool {
        return layout.anchors[state] is FloatingPanelIntrinsicLayoutAnchor
    }

    private func edgePosition(_ frame: CGRect) -> CGFloat {
        switch position {
        case .top:
            return frame.maxY
        case .left:
            return frame.maxX
        case .bottom:
            return frame.minY
        case .right:
            return frame.minX
        }
    }

    private func referenceEdge(of anchor: FloatingPanelLayoutAnchoring) -> FloatingPanelReferenceEdge {
        switch anchor {
        case is FloatingPanelIntrinsicLayoutAnchor,
            is FloatingPanelAdaptiveLayoutAnchor:
            switch position {
            case .top: return .top
            case .left: return .left
            case .bottom: return .bottom
            case .right: return .right
            }
        case let anchor as FloatingPanelLayoutAnchor:
            return anchor.referenceEdge
        default:
            fatalError("Unsupported a FloatingPanelLayoutAnchoring object")
        }
    }

    func prepareLayout() {
        NSLayoutConstraint.deactivate(fixedConstraints)

        surfaceView.translatesAutoresizingMaskIntoConstraints = false
        backdropView.translatesAutoresizingMaskIntoConstraints = false

        // Fixed constraints of surface and backdrop views
        let surfaceConstraints: [NSLayoutConstraint]
        if let constraints = layout.prepareLayout?(surfaceView: surfaceView, in: vc.view) {
            surfaceConstraints = constraints
        } else {
            switch position {
            case .top, .bottom:
                surfaceConstraints = [
                    surfaceView.leftAnchor.constraint(equalTo: vc.view.safeAreaLayoutGuide.leftAnchor, constant: 0.0),
                    surfaceView.rightAnchor.constraint(equalTo: vc.view.safeAreaLayoutGuide.rightAnchor, constant: 0.0),
                ]
            case .left, .right:
                surfaceConstraints = [
                    surfaceView.topAnchor.constraint(equalTo: vc.view.safeAreaLayoutGuide.topAnchor, constant: 0.0),
                    surfaceView.bottomAnchor.constraint(equalTo: vc.view.safeAreaLayoutGuide.bottomAnchor, constant: 0.0),
                ]
            }
        }
        let backdropConstraints = [
            backdropView.topAnchor.constraint(equalTo: vc.view.topAnchor, constant: 0.0),
            backdropView.leftAnchor.constraint(equalTo: vc.view.leftAnchor,constant: 0.0),
            backdropView.rightAnchor.constraint(equalTo: vc.view.rightAnchor, constant: 0.0),
            backdropView.bottomAnchor.constraint(equalTo: vc.view.bottomAnchor, constant: 0.0),
            ]

        fixedConstraints = surfaceConstraints + backdropConstraints

        NSLayoutConstraint.deactivate(constraint: self.fitToBoundsConstraint)
        self.fitToBoundsConstraint = nil

        if vc.contentMode == .fitToBounds {
            switch position {
            case .top:
                fitToBoundsConstraint = surfaceView.topAnchor.constraint(equalTo: vc.view.topAnchor, constant: 0.0)
                fitToBoundsConstraint?.identifier = "FloatingPanel-fit-to-top"
            case .left:
                fitToBoundsConstraint = surfaceView.leftAnchor.constraint(equalTo: vc.view.leftAnchor, constant: 0.0)
                fitToBoundsConstraint?.identifier = "FloatingPanel-fit-to-left"
            case .bottom:
                fitToBoundsConstraint = surfaceView.bottomAnchor.constraint(equalTo: vc.view.bottomAnchor, constant: 0.0)
                fitToBoundsConstraint?.identifier = "FloatingPanel-fit-to-bottom"
            case .right:
                fitToBoundsConstraint = surfaceView.rightAnchor.constraint(equalTo: vc.view.rightAnchor, constant: 0.0)
                fitToBoundsConstraint?.identifier = "FloatingPanel-fit-to-right"
            }
            fitToBoundsConstraint?.priority = .defaultHigh
        }

        updateStateConstraints()
    }

    private func updateStateConstraints() {
        let allStateConstraints = stateConstraints.flatMap { $1 }
        NSLayoutConstraint.deactivate(allStateConstraints + offConstraints)
        stateConstraints.removeAll()
        for state in layout.anchors.keys {
            stateConstraints[state] = layout.anchors[state]?
                .layoutConstraints(vc, for: position)
                .map{ $0.identifier = "FloatingPanel-\(state)-constraint"; return $0 }
        }
        let hiddenAnchor = layout.anchors[.hidden] ?? self.hiddenAnchor
        offConstraints = hiddenAnchor.layoutConstraints(vc, for: position)
        offConstraints.forEach {
            $0.identifier = "FloatingPanel-hidden-constraint"
        }
    }

    func startInteraction(at state: FloatingPanelState, offset: CGPoint = .zero) {
        if let constraint = interactionConstraint {
            initialConst = constraint.constant
            return
        }

        tearDownAttraction()

        NSLayoutConstraint.deactivate(stateConstraints.flatMap { $1 } + offConstraints)

        initialConst = edgePosition(surfaceView.frame) + offset.y

        let constraint: NSLayoutConstraint
        switch position {
        case .top:
            constraint = surfaceView.bottomAnchor.constraint(equalTo: vc.view.topAnchor, constant: initialConst)
        case .left:
            constraint = surfaceView.rightAnchor.constraint(equalTo: vc.view.leftAnchor, constant: initialConst)
        case .bottom:
            constraint = surfaceView.topAnchor.constraint(equalTo: vc.view.topAnchor, constant: initialConst)
        case .right:
            constraint = surfaceView.leftAnchor.constraint(equalTo: vc.view.leftAnchor, constant: initialConst)
        }

        constraint.priority = .required
        constraint.identifier = "FloatingPanel-interaction"

        NSLayoutConstraint.activate([constraint])
        self.interactionConstraint = constraint
    }

    func endInteraction(at state: FloatingPanelState) {
        // Don't deactivate `interactiveTopConstraint` here because it leads to
        // unsatisfiable constraints

        if self.interactionConstraint == nil {
            // Activate `interactiveTopConstraint` for `fitToBounds` mode.
            // It goes through this path when the pan gesture state jumps
            // from .begin to .end.
            startInteraction(at: state)
        }
    }

    func setUpAttraction(to state: FloatingPanelState) -> (NSLayoutConstraint, CGFloat) {
        NSLayoutConstraint.deactivate(constraint: attractionConstraint)

        let anchor = layout.anchors[state] ?? self.hiddenAnchor

        NSLayoutConstraint.deactivate(stateConstraints.flatMap { $1 } + offConstraints)
        NSLayoutConstraint.deactivate(constraint: interactionConstraint)
        interactionConstraint = nil

        let layoutGuideProvider: LayoutGuideProvider
        switch anchor.referenceGuide {
        case .safeArea:
            layoutGuideProvider = vc.view.safeAreaLayoutGuide
        case .superview:
            layoutGuideProvider = vc.view
        }
        let currentY = position.mainLocation(surfaceLocation)
        let baseHeight = position.mainDimension(vc.view.bounds.size)

        let animationConstraint: NSLayoutConstraint
        var targetY = position(for: state)

        switch position {
        case .top:
            switch referenceEdge(of: anchor) {
            case .top:
                animationConstraint = surfaceView.bottomAnchor.constraint(equalTo: layoutGuideProvider.topAnchor,
                                                                          constant: currentY)
                if anchor.referenceGuide == .safeArea {
                    animationConstraint.constant -= safeAreaInsets.top
                    targetY -= safeAreaInsets.top
                }
            case .bottom:
                let baseHeight = vc.view.bounds.height
                targetY = -(baseHeight - targetY)
                animationConstraint = surfaceView.bottomAnchor.constraint(equalTo: layoutGuideProvider.bottomAnchor,
                                                                          constant: -(baseHeight - currentY))
                if anchor.referenceGuide == .safeArea {
                    animationConstraint.constant += safeAreaInsets.bottom
                    targetY += safeAreaInsets.bottom

                }
            default:
                fatalError("Unsupported reference edges")
            }
        case .left:
            switch referenceEdge(of: anchor) {
            case .left:
                animationConstraint = surfaceView.rightAnchor.constraint(equalTo: layoutGuideProvider.leftAnchor,
                                                                          constant: currentY)
                if anchor.referenceGuide == .safeArea {
                    animationConstraint.constant -= safeAreaInsets.right
                    targetY -= safeAreaInsets.right
                }
            case .right:
                targetY = -(baseHeight - targetY)
                animationConstraint = surfaceView.rightAnchor.constraint(equalTo: layoutGuideProvider.rightAnchor,
                                                                          constant: -(baseHeight - currentY))
                if anchor.referenceGuide == .safeArea {
                    animationConstraint.constant += safeAreaInsets.left
                    targetY += safeAreaInsets.left
                }
            default:
                fatalError("Unsupported reference edges")
            }
        case .bottom:
            switch referenceEdge(of: anchor) {
            case .top:
                animationConstraint = surfaceView.topAnchor.constraint(equalTo: layoutGuideProvider.topAnchor,
                                                                       constant: currentY)
                if anchor.referenceGuide == .safeArea {
                    animationConstraint.constant -= safeAreaInsets.top
                    targetY -= safeAreaInsets.top
                }
            case .bottom:
                targetY = -(baseHeight - targetY)
                animationConstraint = surfaceView.topAnchor.constraint(equalTo: layoutGuideProvider.bottomAnchor,
                                                                       constant: -(baseHeight - currentY))
                if anchor.referenceGuide == .safeArea {
                    animationConstraint.constant += safeAreaInsets.bottom
                    targetY += safeAreaInsets.bottom

                }
            default:
                fatalError("Unsupported reference edges")
            }
        case .right:
            switch referenceEdge(of: anchor) {
            case .left:
                animationConstraint = surfaceView.leftAnchor.constraint(equalTo: layoutGuideProvider.leftAnchor,
                                                                         constant: currentY)
                if anchor.referenceGuide == .safeArea {
                    animationConstraint.constant -= safeAreaInsets.left
                    targetY -= safeAreaInsets.left
                }
            case .right:
                targetY = -(baseHeight - targetY)
                animationConstraint = surfaceView.leftAnchor.constraint(equalTo: layoutGuideProvider.rightAnchor,
                                                                         constant: -(baseHeight - currentY))
                if anchor.referenceGuide == .safeArea {
                    animationConstraint.constant += safeAreaInsets.right
                    targetY += safeAreaInsets.right
                }
            default:
                fatalError("Unsupported reference edges")
            }
        }

        animationConstraint.priority = .defaultHigh
        animationConstraint.identifier = "FloatingPanel-attraction"

        NSLayoutConstraint.activate([animationConstraint])
        self.attractionConstraint = animationConstraint
        return (animationConstraint, targetY)
    }

    private func tearDownAttraction() {
        NSLayoutConstraint.deactivate(constraint: attractionConstraint)
        attractionConstraint = nil
    }

    // The method is separated from prepareLayout(to:) for the rotation support
    // It must be called in FloatingPanelController.traitCollectionDidChange(_:)
    func updateStaticConstraint() {
        NSLayoutConstraint.deactivate([staticConstraint, contentBoundingConstraint].compactMap{ $0 })
        staticConstraint = nil
        contentBoundingConstraint = nil

        if vc.contentMode == .fitToBounds {
            surfaceView.containerOverflow = 0
            return
        }

        let anchor = layout.anchors[self.mostExpandedState]!
        let surfaceAnchor = position.mainDimensionAnchor(surfaceView)
        switch anchor {
        case let anchor as FloatingPanelIntrinsicLayoutAnchor:
            var constant = position.mainDimension(surfaceView.intrinsicContentSize)
            if anchor.referenceGuide == .safeArea {
                constant += position.inset(safeAreaInsets)
            }
            staticConstraint = surfaceAnchor.constraint(equalToConstant: constant)
        case let anchor as FloatingPanelAdaptiveLayoutAnchor:
            let constant: CGFloat
            if anchor.referenceGuide == .safeArea {
                constant = position.inset(safeAreaInsets)
            } else {
                constant = 0.0
            }
            let baseAnchor = position.mainDimensionAnchor(anchor.contentLayoutGuide)
            if let boundingLayoutGuide = anchor.contentBoundingGuide.layoutGuide(vc) {
                if anchor.isAbsolute {
                    contentBoundingConstraint = baseAnchor.constraint(lessThanOrEqualTo: position.mainDimensionAnchor(boundingLayoutGuide),
                                                               constant: anchor.offset)
                } else {
                    contentBoundingConstraint = baseAnchor.constraint(lessThanOrEqualTo: position.mainDimensionAnchor(boundingLayoutGuide),
                                                               multiplier: anchor.offset)
                }
                staticConstraint = surfaceAnchor.constraint(lessThanOrEqualTo: baseAnchor, constant: constant)
            } else {
                staticConstraint = surfaceAnchor.constraint(equalTo: baseAnchor, constant: constant)
            }
        default:
            switch position {
            case .top, .left:
                staticConstraint = surfaceAnchor.constraint(equalToConstant: position(for: self.mostCoordinateState))
            case .bottom, .right:
                let rootViewAnchor = position.mainDimensionAnchor(vc.view)
                staticConstraint = rootViewAnchor.constraint(equalTo: surfaceAnchor,
                                                             constant: position(for: self.leastCoordinateState))
            }
        }

        switch position {
        case .top, .bottom:
            staticConstraint?.identifier = "FloatingPanel-static-height"
        case .left, .right:
            staticConstraint?.identifier = "FloatingPanel-static-width"
        }

        NSLayoutConstraint.activate([staticConstraint, contentBoundingConstraint].compactMap{ $0 })

        surfaceView.containerOverflow = position.mainDimension(vc.view.bounds.size)
    }

    func updateInteractiveEdgeConstraint(diff: CGFloat, scrollingContent: Bool, allowsRubberBanding: (UIRectEdge) -> Bool) {
        defer {
            os_log(msg, log: devLog, type: .debug, "update surface location = \(surfaceLocation)")
        }

        let minConst: CGFloat = position(for: leastCoordinateState)
        let maxConst: CGFloat = position(for: mostCoordinateState)

        var const = initialConst + diff

        let base = position.mainDimension(vc.view.bounds.size)
        // Rubber-banding top buffer
        if allowsRubberBanding(.top), const < minConst {
            let buffer = minConst - const
            const = minConst - rubberBandEffect(for: buffer, base: base)
        }

        // Rubber-banding bottom buffer
        if allowsRubberBanding(.bottom), const > maxConst {
            let buffer = const - maxConst
            const = maxConst + rubberBandEffect(for: buffer, base: base)
        }

        if scrollingContent {
            const = min(max(const, minConst), maxConst)
        }

        interactionConstraint?.constant = const
    }

    // According to @chpwn's tweet: https://twitter.com/chpwn/status/285540192096497664
    // x = distance from the edge
    // c = constant value, UIScrollView uses 0.55
    // d = dimension, either width or height
    private func rubberBandEffect(for buffer: CGFloat, base: CGFloat) -> CGFloat {
        return (1.0 - (1.0 / ((buffer * 0.55 / base) + 1.0))) * base
    }

    func activateLayout(for state: FloatingPanelState, forceLayout: Bool = false) {
        defer {
            if forceLayout {
                layoutSurfaceIfNeeded()
                os_log(msg, log: devLog, type: .debug, "activateLayout for \(state) -- surface.presentation = \(self.surfaceView.presentationFrame) surface.frame = \(self.surfaceView.frame)")
            } else {
                os_log(msg, log: devLog, type: .debug, "activateLayout for \(state)")
            }
        }

        // Must deactivate `interactiveTopConstraint` here
        NSLayoutConstraint.deactivate(constraint: self.interactionConstraint)
        self.interactionConstraint = nil

        tearDownAttraction()

        NSLayoutConstraint.activate(fixedConstraints)

        if vc.contentMode == .fitToBounds {
            NSLayoutConstraint.activate(constraint: self.fitToBoundsConstraint)
        }

        // Recalculate the intrinsic size of a content view. This is because
        // UIView.systemLayoutSizeFitting() returns a different size between an
        // on-screen and off-screen view which includes
        // UIStackView(i.e. Settings view in Samples.app)
        updateStateConstraints()

        switch state {
        case .hidden:
            NSLayoutConstraint.activate(offConstraints)
        default:
            if let constraints = stateConstraints[state] {
                NSLayoutConstraint.activate(constraints)
            } else {
                os_log(msg, log: sysLog, type: .fault, "Error: can not find any constraints for \(state)")
            }
        }
    }

    private func layoutSurfaceIfNeeded() {
        #if !TEST
        guard surfaceView.window != nil else { return }
        #endif
        surfaceView.superview?.layoutIfNeeded()
    }

    func backdropAlpha(for state: FloatingPanelState) -> CGFloat {
        return layout.backdropAlpha?(for: state) ?? defaultLayout.backdropAlpha(for: state)
    }

    fileprivate func checkLayout() {
        // Verify layout configurations
        assert(anchorStates.count > 0)
        assert(validStates.contains(layout.initialState),
               "Does not include an initial state (\(layout.initialState)) in (\(validStates))")
        /* This assertion does not work in a device rotating
         let statePosOrder = activeStates.sorted(by: { position(for: $0) < position(for: $1) })
         assert(sortedDirectionalStates == statePosOrder,
               "Check your layout anchors because the state order(\(statePosOrder)) must be (\(sortedDirectionalStates))).")
         */
    }
}

extension LayoutAdapter {
    func segment(at pos: CGFloat, forward: Bool) -> LayoutSegment {
        /// ----------------------->Y
        /// --> forward                <-- backward
        /// |-------|===o===|-------|  |-------|-------|===o===|
        /// |-------|-------x=======|  |-------|=======x-------|
        /// |-------|-------|===o===|  |-------|===o===|-------|
        /// pos: o/x, segment: =

        let sortedStates = sortedAnchorStatesByCoordinate

        let upperIndex: Int?
        if forward {
            upperIndex = sortedStates.firstIndex(where: { pos < position(for: $0) })
        } else {
            upperIndex = sortedStates.firstIndex(where: { pos <= position(for: $0) })
        }

        switch upperIndex {
        case 0:
            return LayoutSegment(lower: nil, upper: sortedStates.first)
        case let upperIndex?:
            return LayoutSegment(lower: sortedStates[upperIndex - 1], upper: sortedStates[upperIndex])
        default:
            return LayoutSegment(lower: sortedStates[sortedStates.endIndex - 1], upper: nil)
        }
    }
}

extension FloatingPanelController {
    var _layout: FloatingPanelLayout {
        get {
            floatingPanel.layoutAdapter.layout
        }
        set {
            floatingPanel.layoutAdapter.layout = newValue
            floatingPanel.layoutAdapter.checkLayout()
        }
    }
}
