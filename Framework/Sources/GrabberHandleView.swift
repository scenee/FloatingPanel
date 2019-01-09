//
//  Created by Shin Yamamoto on 2018/09/19.
//  Copyright © 2018 Shin Yamamoto. All rights reserved.
//

import UIKit

public class GrabberHandleView: UIView {
    public struct Default {
        public static let width: CGFloat = 36.0
        public static let height: CGFloat = 5.0
        public static let barColor = UIColor(displayP3Red: 0.76, green: 0.77, blue: 0.76, alpha: 1.0)
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        render()
    }

    init() {
        let size = CGSize(width: Default.width,
                          height: Default.height)
        super.init(frame: CGRect(origin: .zero, size: size))
        self.backgroundColor = Default.barColor
        render()
    }

    private func render() {
        self.layer.masksToBounds = true
        self.layer.cornerRadius = frame.size.height * 0.5
    }

    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        return view == self ? nil : view
    }
}
