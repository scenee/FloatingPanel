// Copyright 2018-Present Shin Yamamoto. All rights reserved. MIT license.

import UIKit

@objc(FloatingPanelPassthroughView)
class PassthroughView: UIView {
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
