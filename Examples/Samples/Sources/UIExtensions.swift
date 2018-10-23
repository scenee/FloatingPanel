//
//  Created by Shin Yamamoto on 2018/10/08.
//  Copyright © 2018 Shin Yamamoto. All rights reserved.
//

import UIKit

extension UIView {
    var layoutInsets: UIEdgeInsets {
        if #available(iOS 11.0, *) {
            return safeAreaInsets
        } else {
            return layoutMargins
        }
    }

    var layoutGuide: UILayoutGuide {
        if #available(iOS 11.0, *) {
            return safeAreaLayoutGuide
        } else {
            return layoutMarginsGuide
        }
    }
}

