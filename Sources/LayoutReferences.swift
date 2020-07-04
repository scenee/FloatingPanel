// Copyright 2018 the FloatingPanel authors. All rights reserved. MIT license.

import Foundation

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
