//
//  Created by Shin Yamamoto on 2019/06/27.
//  Copyright © 2019 scenee. All rights reserved.
//

import Foundation
@testable import FloatingPanel

func waitRunLoop(secs: TimeInterval = 0) {
    RunLoop.main.run(until: Date(timeIntervalSinceNow: secs))
}

class FloatingPanelTestDelegate: FloatingPanelControllerDelegate {
    var layout: FloatingPanelLayout?
    func floatingPanel(_ vc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout? {
        return layout
    }
}
