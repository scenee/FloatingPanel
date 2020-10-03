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

/// Constants that specify a layout guide to lay out a panel.
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
