//
//  Created by Shin Yamamoto on 2018/11/21.
//  Copyright © 2018 Shin Yamamoto. All rights reserved.
//

import UIKit

class FloatingPanelPassThroughView: UIView {
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        switch view {
        case is FloatingPanelPassThroughView:
            return nil
        default:
            return view
        }
    }
}

class FloatingPanelSurfaceWrapperView: UIView {
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        switch view {
        case is FloatingPanelSurfaceWrapperView:
            return nil
        default:
            return view
        }
    }
}
