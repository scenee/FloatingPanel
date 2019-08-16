//
//  Created by Shin Yamamoto on 2019/06/27.
//  Copyright © 2019 scenee. All rights reserved.
//

import Foundation
@testable import FloatingPanel

func waitRunLoop(secs: TimeInterval = 0) {
    RunLoop.main.run(until: Date(timeIntervalSinceNow: secs))
}

extension FloatingPanelController {
    func showForTest() {
        loadViewIfNeeded()
        view.frame = CGRect(x: 0, y: 0, width: 375, height: 667)
        show(animated: false, completion: nil)
    }
}

class FloatingPanelTestDelegate: FloatingPanelControllerDelegate {
    var layout: FloatingPanelLayout?
    var behavior: FloatingPanelBehavior?
    var position: FloatingPanelPosition = .hidden
    func floatingPanel(_ vc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout? {
        return layout
    }
    func floatingPanel(_ vc: FloatingPanelController, behaviorFor newCollection: UITraitCollection) -> FloatingPanelBehavior? {
        return behavior
    }
    func floatingPanelDidChangePosition(_ vc: FloatingPanelController) {
        position = vc.position
    }
}

protocol FloatingPanelTestLayout: FloatingPanelFullScreenLayout {}
extension FloatingPanelTestLayout {
    func insetFor(position: FloatingPanelPosition) -> CGFloat? {
        switch position {
        case .full: return 20.0
        case .half: return 250.0
        case .tip: return 60.0
        default: return nil
        }
    }
}
