//
//  Created by Shin Yamamoto on 2019/06/27.
//  Copyright © 2019 scenee. All rights reserved.
//

import XCTest
@testable import FloatingPanel

class FloatingPanelLayoutTests: XCTestCase {
    override func setUp() {}
    override func tearDown() {}

    func test_layoutAdapter_topAndBottomMostState() {
        let fpc = FloatingPanelController(delegate: nil)
        fpc.loadViewIfNeeded()
        fpc.view.frame = CGRect(x: 0, y: 0, width: 375, height: 667)
        XCTAssertEqual(fpc.floatingPanel.layoutAdapter.topMostState, .full)
        XCTAssertEqual(fpc.floatingPanel.layoutAdapter.bottomMostState, .tip)

        class FloatingPanelLayoutWithHidden: FloatingPanelLayout {
            func insetFor(position: FloatingPanelPosition) -> CGFloat? { return nil }
            let initialPosition: FloatingPanelPosition = .hidden
            let supportedPositions: Set<FloatingPanelPosition> = [.hidden, .half, .full]
        }
        class FloatingPanelLayout2Positions: FloatingPanelLayout {
            func insetFor(position: FloatingPanelPosition) -> CGFloat? { return nil }
            let initialPosition: FloatingPanelPosition = .tip
            let supportedPositions: Set<FloatingPanelPosition> = [.tip, .half]
        }
        let delegate = FloatingPanelTestDelegate()
        delegate.layout = FloatingPanelLayoutWithHidden()
        fpc.delegate = delegate
        XCTAssertEqual(fpc.floatingPanel.layoutAdapter.topMostState, .full)
        XCTAssertEqual(fpc.floatingPanel.layoutAdapter.bottomMostState, .half) // Will fixed on fix-hidden-position branch

        delegate.layout = FloatingPanelLayout2Positions()
        fpc.delegate = delegate
        XCTAssertEqual(fpc.floatingPanel.layoutAdapter.topMostState, .half)
        XCTAssertEqual(fpc.floatingPanel.layoutAdapter.bottomMostState, .tip)
    }
}
