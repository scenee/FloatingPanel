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
    var position: FloatingPanelState = .hidden
    var didMoveCallback: ((FloatingPanelController) -> Void)?
    func floatingPanelDidChangePosition(_ vc: FloatingPanelController) {
        position = vc.state
    }
    func floatingPanelDidMove(_ vc: FloatingPanelController) {
        didMoveCallback?(vc)
    }
}

class FloatingPanelTestLayout: FloatingPanelLayout {
    let fullInset: CGFloat = 20.0
    let halfInset: CGFloat = 250.0
    let tipInset: CGFloat = 60.0

    var initialState: FloatingPanelState {
        return .half
    }
    var anchorPosition: FloatingPanelPosition {
        return .bottom
    }
    var referenceGuide: FloatingPanelLayoutReferenceGuide {
        return .superview
    }
    var stateAnchors: [FloatingPanelState : FloatingPanelLayoutAnchoring] {
        return [
            .full: FloatingPanelLayoutAnchor(absoluteInset: fullInset, edge: .top, referenceGuide: referenceGuide),
            .half: FloatingPanelLayoutAnchor(absoluteInset: halfInset, edge: .bottom, referenceGuide: referenceGuide),
            .tip: FloatingPanelLayoutAnchor(absoluteInset: tipInset, edge: .bottom, referenceGuide: referenceGuide),
        ]
    }
}

class FloatingPanelTop2BottomTestLayout: FloatingPanelLayout {
    let fullInset: CGFloat = 0.0
    let halfInset: CGFloat = 250.0
    let tipInset: CGFloat = 60.0

    var initialState: FloatingPanelState {
        return .half
    }
    var anchorPosition: FloatingPanelPosition {
        return .top
    }
    var referenceGuide: FloatingPanelLayoutReferenceGuide {
        return .superview
    }
    var stateAnchors: [FloatingPanelState : FloatingPanelLayoutAnchoring] {
        return [
            .full: FloatingPanelLayoutAnchor(absoluteInset: fullInset, edge: .bottom, referenceGuide: referenceGuide),
            .half: FloatingPanelLayoutAnchor(absoluteInset: halfInset, edge: .top, referenceGuide: referenceGuide),
            .tip: FloatingPanelLayoutAnchor(absoluteInset: tipInset, edge: .top, referenceGuide: referenceGuide),
        ]
    }
}

class FloatingPanelProjectableBehavior: FloatingPanelBehavior {
    func shouldProjectMomentum(_ fpc: FloatingPanelController, to proposedTargetPosition: FloatingPanelState) -> Bool {
        return true
    }
}
