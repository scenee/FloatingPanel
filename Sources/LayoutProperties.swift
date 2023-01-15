// Copyright 2018-Present Shin Yamamoto. All rights reserved. MIT license.

import UIKit

/// Constants that specify the edge of the container of a panel.
@objc public enum FloatingPanelReferenceEdge: Int {
    case top
    case left
    case bottom
    case right
}

extension FloatingPanelReferenceEdge {
    func inset(of insets: UIEdgeInsets) -> CGFloat {
        switch self {
        case .top: return insets.top
        case .left: return insets.left
        case .bottom: return insets.bottom
        case .right: return insets.right
        }
    }
    func mainDimension(_ size: CGSize) -> CGFloat {
        switch self {
        case .top, .bottom: return size.height
        case .left, .right: return size.width
        }
    }
}

/// A representation to specify a rectangular area to lay out a panel.
@objc public enum FloatingPanelLayoutReferenceGuide: Int {
    case superview = 0
    case safeArea = 1
}

extension FloatingPanelLayoutReferenceGuide {
    func layoutGuide(vc: UIViewController) -> LayoutGuideProvider {
        switch self {
        case .safeArea:
            return vc.fp_safeAreaLayoutGuide
        case .superview:
            return vc.view
        }
    }
}

/// A representation to specify a bounding box which limit the content size of a panel.
@objc public enum FloatingPanelLayoutContentBoundingGuide: Int {
    case none = 0
    case superview = 1
    case safeArea = 2
}

extension FloatingPanelLayoutContentBoundingGuide {
    func layoutGuide(_ fpc: FloatingPanelController) -> LayoutGuideProvider? {
        switch self {
        case .superview:
            return fpc.view
        case .safeArea:
            return fpc.fp_safeAreaLayoutGuide
        case .none:
            return nil
        }
    }
    func maxBounds(_ fpc: FloatingPanelController) -> CGRect? {
        switch self {
        case .superview:
            return fpc.view.bounds
        case .safeArea:
            return fpc.view.bounds.inset(by: fpc.fp_safeAreaInsets)
        case .none:
            return nil
        }
    }

}
