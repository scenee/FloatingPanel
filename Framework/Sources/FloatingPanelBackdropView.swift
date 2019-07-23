//
//  Created by Shin Yamamoto on 2018/09/26.
//  Copyright © 2018 Shin Yamamoto. All rights reserved.
//

import UIKit

/// A view that presents a backdrop interface behind a floating panel.
public class FloatingPanelBackdropView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUp()
    }

    private func setUp() {
        layer.backgroundColor = UIColor.black.cgColor
    }

    @objc dynamic public override var backgroundColor: UIColor? {
        get {
            guard let color = layer.backgroundColor else { return nil }
            return UIColor(cgColor: color)
        }
        set { layer.backgroundColor = newValue?.cgColor }
    }
}
