// Copyright 2018-Present Shin Yamamoto. All rights reserved. MIT license.

import UIKit

/// Constants describing the position of a panel in a screen
@objc public enum FloatingPanelPosition: Int {
    case top
    case left
    case bottom
    case right
}

extension FloatingPanelPosition {
    func mainLocation(_ point: CGPoint) -> CGFloat {
        switch self {
        case .top, .bottom: return point.y
        case .left, .right: return point.x
        }
    }

    func mainDimension(_ size: CGSize) -> CGFloat {
        switch self {
        case .top, .bottom: return size.height
        case .left, .right: return size.width
        }
    }

    func mainDimensionAnchor(_ layoutGuide: LayoutGuideProvider) -> NSLayoutDimension {
        switch self {
        case .top, .bottom: return layoutGuide.heightAnchor
        case .left, .right: return layoutGuide.widthAnchor
        }
    }

    func crossDimension(_ size: CGSize) -> CGFloat {
        switch self {
        case .top, .bottom: return size.width
        case .left, .right: return size.height
        }
    }

    func inset(_ insets: UIEdgeInsets) -> CGFloat {
        switch self {
        case .top: return insets.top
        case .left: return insets.left
        case .bottom: return insets.bottom
        case .right: return insets.right
        }
    }
}
