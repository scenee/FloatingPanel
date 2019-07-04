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
        XCTAssertEqual(fpc.floatingPanel.layoutAdapter.bottomMostState, .hidden)

        delegate.layout = FloatingPanelLayout2Positions()
        fpc.delegate = delegate
        XCTAssertEqual(fpc.floatingPanel.layoutAdapter.topMostState, .half)
        XCTAssertEqual(fpc.floatingPanel.layoutAdapter.bottomMostState, .tip)
    }

    func test_positionSegment() {
        let fpc = FloatingPanelController(delegate: nil)
        fpc.loadViewIfNeeded()
        fpc.view.frame = CGRect(x: 0, y: 0, width: 375, height: 667)

        let fullPos = fpc.originYOfSurface(for: .full)
        let halfPos = fpc.originYOfSurface(for: .half)
        let tipPos = fpc.originYOfSurface(for: .tip)

        var segument: LayoutSegment

        segument = fpc.floatingPanel.layoutAdapter.segument(at: fullPos, forward: true)
        XCTAssertEqual(segument.lower, .full)
        XCTAssertEqual(segument.upper, .half)
        segument = fpc.floatingPanel.layoutAdapter.segument(at: fullPos, forward: false)
        XCTAssertEqual(segument.lower, nil)
        XCTAssertEqual(segument.upper, .full)
        segument = fpc.floatingPanel.layoutAdapter.segument(at: halfPos, forward: true)
        XCTAssertEqual(segument.lower, .half)
        XCTAssertEqual(segument.upper, .tip)
        segument = fpc.floatingPanel.layoutAdapter.segument(at: halfPos, forward: false)
        XCTAssertEqual(segument.lower, .full)
        XCTAssertEqual(segument.upper, .half)
        segument = fpc.floatingPanel.layoutAdapter.segument(at: tipPos, forward: true)
        XCTAssertEqual(segument.lower, .tip)
        XCTAssertEqual(segument.upper, nil)
        segument = fpc.floatingPanel.layoutAdapter.segument(at: tipPos, forward: false)
        XCTAssertEqual(segument.lower, .half)
        XCTAssertEqual(segument.upper, .tip)
    }
}
