//
//  Created by Shin Yamamoto on 2018/11/21.
//  Copyright © 2018 Shin Yamamoto. All rights reserved.
//

import UIKit

class FloatingPanelPassThroughView: UIView {
    public weak var eventForwardingView: UIView?
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        switch hitView {
        case self:
            return eventForwardingView?.hitTest(self.convert(point, to: eventForwardingView), with: event)
        default:
            return hitView
        }
    }
}
