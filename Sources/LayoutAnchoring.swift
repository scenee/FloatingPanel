// Copyright 2018-Present Shin Yamamoto. All rights reserved. MIT license.

import UIKit

/// An interface for implementing custom layout anchor objects.
@objc public protocol FloatingPanelLayoutAnchoring {
    var referenceGuide: FloatingPanelLayoutReferenceGuide { get }
    func layoutConstraints(_ fpc: FloatingPanelController, for position: FloatingPanelPosition) -> [NSLayoutConstraint]
}

/// An object that defines how to settles a panel with insets from an edge of a reference rectangle.
@objc final public class FloatingPanelLayoutAnchor: NSObject, FloatingPanelLayoutAnchoring /*, NSCopying */ {

    /// Returns a layout anchor with the specified inset by an absolute value, edge and reference guide for a panel.
    ///
    /// The inset is an amount to inset a panel from an edge of the reference guide.  The edge refers to a panel
    /// positioning.
    ///
    /// - Parameters:
    ///     - absoluteOffset: An absolute offset to attach the panel from the edge.
    ///     - edge: Specify the edge of ``FloatingPanelController``'s view. This is the staring point of the offset.
    ///     - referenceGuide: The rectangular area to lay out the content. If it's set to `.safeArea`, the panel content lays out inside the safe area of its ``FloatingPanelController``'s view.
    @objc public init(absoluteInset: CGFloat, edge: FloatingPanelReferenceEdge, referenceGuide: FloatingPanelLayoutReferenceGuide) {
        self.inset = absoluteInset
        self.referenceGuide = referenceGuide
        self.referenceEdge = edge
        self.isAbsolute = true
    }

    /// Returns a layout anchor with the specified inset by a fractional value, edge and reference guide for a panel.
    ///
    /// The inset is an amount to inset a panel from the edge of the specified reference guide. The value is
    /// a floating-point number in the range 0.0 to 1.0, where 0.0 represents zero distance from the edge and
    /// 1.0 represents a distance to the opposite edge.
    ///
    /// - Parameters:
    ///     - fractionalOffset: A fractional value of the size of ``FloatingPanelController``'s view to attach the panel from the edge.
    ///     - edge: Specify the edge of ``FloatingPanelController``'s view. This is the staring point of the offset.
    ///     - referenceGuide: The rectangular area to lay out the content. If it's set to `.safeArea`, the panel content lays out inside the safe area of its ``FloatingPanelController``'s view.
    @objc public init(fractionalInset: CGFloat, edge: FloatingPanelReferenceEdge, referenceGuide: FloatingPanelLayoutReferenceGuide) {
        self.inset = fractionalInset
        self.referenceGuide = referenceGuide
        self.referenceEdge = edge
        self.isAbsolute = false
    }
    let inset: CGFloat
    let isAbsolute: Bool
    /// The reference rectangle area for the inset.
    @objc public let referenceGuide: FloatingPanelLayoutReferenceGuide
    @objc let referenceEdge: FloatingPanelReferenceEdge
}

public extension FloatingPanelLayoutAnchor {
    func layoutConstraints(_ vc: FloatingPanelController, for position: FloatingPanelPosition) -> [NSLayoutConstraint] {
        let layoutGuide = referenceGuide.layoutGuide(vc: vc)
        switch position {
        case .top:
            return layoutConstraints(layoutGuide, for: vc.surfaceView.bottomAnchor)
        case .left:
            return layoutConstraints(layoutGuide, for: vc.surfaceView.rightAnchor)
        case .bottom:
            return layoutConstraints(layoutGuide, for: vc.surfaceView.topAnchor)
        case .right:
            return layoutConstraints(layoutGuide, for: vc.surfaceView.leftAnchor)
        }
    }

    private func layoutConstraints(_ layoutGuide: LayoutGuideProvider, for edgeAnchor: NSLayoutYAxisAnchor) -> [NSLayoutConstraint] {
        switch referenceEdge {
        case .top:
            if isAbsolute {
                return [edgeAnchor.constraint(equalTo: layoutGuide.topAnchor, constant: inset)]
            }
            let offsetAnchor = layoutGuide.topAnchor.anchorWithOffset(to: edgeAnchor)
            return [offsetAnchor.constraint(equalTo:layoutGuide.heightAnchor, multiplier: inset)]
        case .bottom:
            if isAbsolute {
                return [layoutGuide.bottomAnchor.constraint(equalTo: edgeAnchor, constant: inset)]
            }
            let offsetAnchor = edgeAnchor.anchorWithOffset(to: layoutGuide.bottomAnchor)
            return [offsetAnchor.constraint(equalTo: layoutGuide.heightAnchor, multiplier: inset)]
        default:
            fatalError("Unsupported reference edges")
        }
    }

    private func layoutConstraints(_ layoutGuide: LayoutGuideProvider, for edgeAnchor: NSLayoutXAxisAnchor) -> [NSLayoutConstraint] {
        switch referenceEdge {
        case .left:
            if isAbsolute {
                return [edgeAnchor.constraint(equalTo: layoutGuide.leftAnchor, constant: inset)]
            }
            let offsetAnchor = layoutGuide.leftAnchor.anchorWithOffset(to: edgeAnchor)
            return [offsetAnchor.constraint(equalTo: layoutGuide.widthAnchor, multiplier: inset)]
        case .right:
            if isAbsolute {
                return [layoutGuide.rightAnchor.constraint(equalTo: edgeAnchor, constant: inset)]
            }
            let offsetAnchor = edgeAnchor.anchorWithOffset(to: layoutGuide.rightAnchor)
            return [offsetAnchor.constraint(equalTo: layoutGuide.widthAnchor, multiplier: inset)]
        default:
            fatalError("Unsupported reference edges")
        }
    }
}

/// An object that defines how to settles a panel with the intrinsic size for a content.
@objc final public class FloatingPanelIntrinsicLayoutAnchor: NSObject, FloatingPanelLayoutAnchoring /*, NSCopying */ {

    /// Returns a layout anchor with the specified offset by an absolute value and reference guide for a panel.
    ///
    /// The offset is an amount to offset a position of panel that displays the entire content from an edge of
    /// the reference guide.  The edge refers to a panel positioning.
    ///
    /// - Parameters:
    ///     - absoluteOffset: An absolute offset from the content size in the main dimension(i.e. y axis for a bottom panel) to attach the panel.
    ///     - referenceGuide: The rectangular area to lay out the content. If it's set to `.safeArea`, the panel content lays out inside the safe area of its ``FloatingPanelController``'s view.
    @objc public init(absoluteOffset offset: CGFloat, referenceGuide: FloatingPanelLayoutReferenceGuide = .safeArea) {
        self.offset = offset
        self.referenceGuide = referenceGuide
        self.isAbsolute = true
    }

    /// Returns a layout anchor with the specified offset by a fractional value and reference guide for a panel.
    ///
    /// The offset value is a floating-point number in the range 0.0 to 1.0, where 0.0 represents the full content
    /// is displayed and 0.5 represents the half of content is displayed.
    ///
    /// - Parameters:
    ///     - fractionalOffset: A fractional offset of the content size in the main dimension(i.e. y axis for a bottom panel) to attach the panel.
    ///     - referenceGuide: The rectangular area to lay out the content. If it's set to `.safeArea`, the panel content lays out inside the safe area of its ``FloatingPanelController``'s view.
    @objc public init(fractionalOffset offset: CGFloat, referenceGuide: FloatingPanelLayoutReferenceGuide = .safeArea) {
        self.offset = offset
        self.referenceGuide = referenceGuide
        self.isAbsolute = false
    }
    let offset: CGFloat
    let isAbsolute: Bool

    /// The reference rectangle area for the offset
    @objc public let referenceGuide: FloatingPanelLayoutReferenceGuide
}

public extension FloatingPanelIntrinsicLayoutAnchor {
    func layoutConstraints(_ vc: FloatingPanelController, for position: FloatingPanelPosition) -> [NSLayoutConstraint] {
        let surfaceIntrinsicLength = position.mainDimension(vc.surfaceView.intrinsicContentSize)
        let constant = isAbsolute ? surfaceIntrinsicLength - offset : surfaceIntrinsicLength * (1 - offset)
        let layoutGuide = referenceGuide.layoutGuide(vc: vc)
        switch position {
        case .top:
            return [vc.surfaceView.bottomAnchor.constraint(equalTo: layoutGuide.topAnchor, constant: constant)]
        case .left:
            return [vc.surfaceView.rightAnchor.constraint(equalTo: layoutGuide.leftAnchor, constant: constant)]
        case .bottom:
            return [vc.surfaceView.topAnchor.constraint(equalTo: layoutGuide.bottomAnchor, constant: -constant)]
        case .right:
            return [vc.surfaceView.leftAnchor.constraint(equalTo: layoutGuide.rightAnchor, constant: -constant)]
        }
    }
}

/// An object that defines how to settles a panel with a layout guide of a content view.
@objc final public class FloatingPanelAdaptiveLayoutAnchor: NSObject, FloatingPanelLayoutAnchoring /*, NSCopying */ {

    /// Returns a layout anchor with the specified offset by an absolute value to display a panel with its intrinsic content size.
    ///
    /// The offset is an amount to offset a position of panel that displays the entire content of the specified guide from an edge of
    /// the reference guide.  The edge refers to a panel positioning.
    ///
    ///  ``contentBoundingGuide`` restricts the content size which a panel displays. For example, given ``referenceGuide`` is `.superview` and ``contentBoundingGuide`` is `.safeArea` for a bottom positioned panel, the panel content is laid out inside the superview of the view of FloatingPanelController(not its safe area), but its content size is limited to its safe area size. Normally both of ``referenceGuide`` and ``contentBoundingGuide`` are specified with the same rectangle area.
    ///
    /// - Parameters:
    ///     - absoluteOffset: An absolute offset from the content size in the main dimension(i.e. y axis for a bottom panel) to attach the panel.
    ///     - contentLayout: The content layout guide to calculate the content size in the panel.
    ///     - referenceGuide: The rectangular area to lay out the content of a panel. If it's set to `.safeArea`, the panel content displays inside the safe area of its ``FloatingPanelController``'s view. This argument doesn't limit its content size.
    ///     - contentBoundingGuide: The rectangular area to restrict the content size of a panel in the main dimension(i.e. y axis is the main dimension for a bottom panel).
    ///
    /// - Warning: If ``contentBoundingGuide`` is set to none, the panel may expand out of the screen size, depending on the intrinsic size of its content.
    @objc public init(
        absoluteOffset offset: CGFloat,
        contentLayout: UILayoutGuide,
        referenceGuide: FloatingPanelLayoutReferenceGuide,
        contentBoundingGuide: FloatingPanelLayoutContentBoundingGuide = .none
    ) {
        self.offset = offset
        self.contentLayoutGuide = contentLayout
        self.referenceGuide = referenceGuide
        self.contentBoundingGuide = contentBoundingGuide
        self.isAbsolute = true
    }

    /// Returns a layout anchor with the specified offset by a fractional value to display a panel with its intrinsic content size.
    ///
    /// The offset value is a floating-point number in the range 0.0 to 1.0, where 0.0 represents the full content
    /// is displayed and 0.5 represents the half of content is displayed.
    ///
    ///  ``contentBoundingGuide`` restricts the content size which a panel displays. For example, given ``referenceGuide`` is `.superview` and ``contentBoundingGuide`` is `.safeArea` for a bottom positioned panel, the panel content is laid out inside the superview of the view of FloatingPanelController(not its safe area), but its content size is limited to its safe area size. Normally both of ``referenceGuide`` and ``contentBoundingGuide`` are specified with the same rectangle area.
    ///
    /// - Parameters:
    ///     - fractionalOffset: A fractional offset of the content size in the main dimension(i.e. y axis for a bottom panel) to attach the panel.
    ///     - contentLayout: The content layout guide to calculate the content size in the panel.
    ///     - referenceGuide: The rectangular area to lay out the content of a panel. If it's set to `.safeArea`, the panel content displays inside the safe area of its ``FloatingPanelController``'s view. This argument doesn't limit its content size.
    ///     - contentBoundingGuide: The rectangular area to restrict the content size of a panel in the main dimension(i.e. y axis is the main dimension for a bottom panel).
    ///
    /// - Warning: If ``contentBoundingGuide`` is set to none, the panel may expand out of the screen size, depending on the intrinsic size of its content.
    @objc public init(
        fractionalOffset offset: CGFloat,
        contentLayout: UILayoutGuide,
        referenceGuide: FloatingPanelLayoutReferenceGuide,
        contentBoundingGuide: FloatingPanelLayoutContentBoundingGuide = .none
    ) {
        self.offset = offset
        self.contentLayoutGuide = contentLayout
        self.referenceGuide = referenceGuide
        self.contentBoundingGuide = contentBoundingGuide
        self.isAbsolute = false
    }
    let offset: CGFloat
    let isAbsolute: Bool
    let contentLayoutGuide: UILayoutGuide
    @objc public let referenceGuide: FloatingPanelLayoutReferenceGuide
    @objc public let contentBoundingGuide: FloatingPanelLayoutContentBoundingGuide
}

public extension FloatingPanelAdaptiveLayoutAnchor {
    func layoutConstraints(_ vc: FloatingPanelController, for position: FloatingPanelPosition) -> [NSLayoutConstraint] {
        var constraints = [NSLayoutConstraint]()

        let layoutGuide = referenceGuide.layoutGuide(vc: vc)
        let offsetConstraint: NSLayoutConstraint
        let offsetAnchor: NSLayoutDimension
        switch position {
        case .top:
            offsetAnchor = layoutGuide.topAnchor.anchorWithOffset(to: vc.surfaceView.bottomAnchor)
        case .left:
            offsetAnchor = layoutGuide.leftAnchor.anchorWithOffset(to: vc.surfaceView.rightAnchor)
        case .bottom:
            offsetAnchor = vc.surfaceView.topAnchor.anchorWithOffset(to: layoutGuide.bottomAnchor)
        case .right:
            offsetAnchor = vc.surfaceView.leftAnchor.anchorWithOffset(to: layoutGuide.rightAnchor)
        }
        if isAbsolute {
            offsetConstraint = offsetAnchor.constraint(equalTo: position.mainDimensionAnchor(contentLayoutGuide), constant: -offset)
        } else {
            offsetConstraint = offsetAnchor.constraint(equalTo: position.mainDimensionAnchor(contentLayoutGuide), multiplier: (1 - offset))
        }
        constraints.append(offsetConstraint)

        return constraints
    }
}

extension FloatingPanelAdaptiveLayoutAnchor {
    func distance(from dimension: CGFloat) -> CGFloat {
        return isAbsolute ? offset : dimension * offset
    }
}
