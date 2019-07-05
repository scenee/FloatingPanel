//
//  Created by Shin Yamamoto on 2019/06/27.
//  Copyright © 2019 scenee. All rights reserved.
//

import XCTest
@testable import FloatingPanel

class FloatingPanelLayoutTests: XCTestCase {
    var fpc: FloatingPanelController!
    override func setUp() {
        fpc = FloatingPanelController(delegate: nil)
        fpc.loadViewIfNeeded()
        fpc.view.frame = CGRect(x: 0, y: 0, width: 375, height: 667)
    }
    override func tearDown() {}

    func test_layoutAdapter_topAndBottomMostState() {
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

    func test_updateInteractiveTopConstraint() {
        fpc.showForTest()
        fpc.move(to: .full, animated: false)

        fpc.floatingPanel.layoutAdapter.startInteraction(at: fpc.position)
        fpc.floatingPanel.layoutAdapter.startInteraction(at: fpc.position) // Should be ignore

        let fullPos = fpc.originYOfSurface(for: .full)
        let tipPos = fpc.originYOfSurface(for: .tip)

        var pre: CGFloat
        var next: CGFloat
        pre = fpc.surfaceView.frame.minY
        fpc.floatingPanel.layoutAdapter.updateInteractiveTopConstraint(diff: -100.0, allowsTopBuffer: false, with: fpc.behavior)
        next = fpc.surfaceView.frame.minY
        XCTAssertEqual(next, pre)

        fpc.floatingPanel.layoutAdapter.updateInteractiveTopConstraint(diff: -100.0, allowsTopBuffer: true, with: fpc.behavior)
        next = fpc.surfaceView.frame.minY
        XCTAssertEqual(next, fullPos - fpc.layout.topInteractionBuffer)

        fpc.floatingPanel.layoutAdapter.updateInteractiveTopConstraint(diff: 100.0, allowsTopBuffer: true, with: fpc.behavior)
        next = fpc.surfaceView.frame.minY
        XCTAssertEqual(next, fullPos + 100.0)

        fpc.floatingPanel.layoutAdapter.updateInteractiveTopConstraint(diff: tipPos - fullPos, allowsTopBuffer: true, with: fpc.behavior)
        next = fpc.surfaceView.frame.minY
        XCTAssertEqual(next, tipPos)

        fpc.floatingPanel.layoutAdapter.updateInteractiveTopConstraint(diff: tipPos - fullPos + 100.0, allowsTopBuffer: true, with: fpc.behavior)
        next = fpc.surfaceView.frame.minY
        XCTAssertEqual(next, tipPos + fpc.layout.bottomInteractionBuffer)

        fpc.floatingPanel.layoutAdapter.endInteraction(at: fpc.position)
    }

    func test_updateInteractiveTopConstraintWithHidden() {
        class FloatingPanelLayout2Positions: FloatingPanelTestLayout {
            let initialPosition: FloatingPanelPosition = .hidden
            let supportedPositions: Set<FloatingPanelPosition> = [.hidden, .full]
        }
        let delegate = FloatingPanelTestDelegate()
        delegate.layout = FloatingPanelLayout2Positions()
        fpc.delegate = delegate
        fpc.showForTest()
        fpc.move(to: .full, animated: false)

        fpc.floatingPanel.layoutAdapter.startInteraction(at: fpc.position)

        let fullPos = fpc.originYOfSurface(for: .full)
        let hiddenPos = fpc.originYOfSurface(for: .hidden)

        var pre: CGFloat
        var next: CGFloat
        pre = fpc.surfaceView.frame.minY
        fpc.floatingPanel.layoutAdapter.updateInteractiveTopConstraint(diff: -100.0, allowsTopBuffer: false, with: fpc.behavior)
        next = fpc.surfaceView.frame.minY
        XCTAssertEqual(next, pre)

        fpc.floatingPanel.layoutAdapter.updateInteractiveTopConstraint(diff: -100.0, allowsTopBuffer: true, with: fpc.behavior)
        next = fpc.surfaceView.frame.minY
        XCTAssertEqual(next, fullPos - fpc.layout.topInteractionBuffer)

        fpc.floatingPanel.layoutAdapter.updateInteractiveTopConstraint(diff: hiddenPos - fullPos + 100.0, allowsTopBuffer: true, with: fpc.behavior)
        next = fpc.surfaceView.frame.minY
        XCTAssertEqual(next, hiddenPos + fpc.layout.bottomInteractionBuffer)

        fpc.floatingPanel.layoutAdapter.endInteraction(at: fpc.position)
    }
}
