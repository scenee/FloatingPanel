// Copyright 2018 the FloatingPanel authors. All rights reserved. MIT license.

import UIKit

extension Collection {
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension UIViewController {
    var isLandscape: Bool {
        if #available(iOS 13.0, *) {
            return view.window?.windowScene?.interfaceOrientation.isLandscape ?? false
        } else {
            return UIApplication.shared.statusBarOrientation.isLandscape
        }
    }
}
