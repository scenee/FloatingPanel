//
//  Created by Shin Yamamoto on 2018/10/08.
//  Copyright © 2018 Shin Yamamoto. All rights reserved.
//

import UIKit

protocol LayoutGuideProvider {
    var topAnchor: NSLayoutYAxisAnchor { get }
    var bottomAnchor: NSLayoutYAxisAnchor { get }
}
extension UILayoutGuide: LayoutGuideProvider {}

class CustomLayoutGuide: LayoutGuideProvider {
    let topAnchor: NSLayoutYAxisAnchor
    let bottomAnchor: NSLayoutYAxisAnchor
    init(topAnchor: NSLayoutYAxisAnchor, bottomAnchor: NSLayoutYAxisAnchor) {
        self.topAnchor = topAnchor
        self.bottomAnchor = bottomAnchor
    }
}

extension UIViewController {
    var layoutInsets: UIEdgeInsets {
        if #available(iOS 11.0, *) {
            return view.safeAreaInsets
        } else {
            return UIEdgeInsets(top: topLayoutGuide.length,
                                left: 0.0,
                                bottom: bottomLayoutGuide.length,
                                right: 0.0)
        }
    }

    var layoutGuide: LayoutGuideProvider {
        if #available(iOS 11.0, *) {
            return view!.safeAreaLayoutGuide
        } else {
            return CustomLayoutGuide(topAnchor: topLayoutGuide.bottomAnchor,
                                     bottomAnchor: bottomLayoutGuide.topAnchor)
        }
    }
}
