// Copyright 2018 the FloatingPanel authors. All rights reserved. MIT license.

import UIKit

class UnavailableViewController: UIViewController {
    weak var label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let label = UILabel()
        label.text = "Unavailable content"
        label.numberOfLines = 0
        label.textAlignment = .center
        label.frame = view.bounds
        label.autoresizingMask = [
            .flexibleTopMargin,
            .flexibleLeftMargin,
            .flexibleBottomMargin,
            .flexibleRightMargin
        ]
        view.addSubview(label)
        self.label = label
    }
}
