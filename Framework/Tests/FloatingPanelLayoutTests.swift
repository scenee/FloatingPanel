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

    func test_layoutSegment_3position() {
        class FloatingPanelLayout3Positions: FloatingPanelTestLayout {
            let initialPosition: FloatingPanelPosition = .half
            let supportedPositions: Set<FloatingPanelPosition> = [.tip, .half, .full]
        }

        let delegate = FloatingPanelTestDelegate()
        delegate.layout = FloatingPanelLayout3Positions()
        fpc.delegate = delegate

        let fullPos = fpc.originYOfSurface(for: .full)
        let halfPos = fpc.originYOfSurface(for: .half)
        let tipPos = fpc.originYOfSurface(for: .tip)

        let minPos = CGFloat.leastNormalMagnitude
        let maxPos = CGFloat.greatestFiniteMagnitude

        assertLayoutSegment(fpc.floatingPanel, with: [
            (#line, pos: minPos, forwardY: true, lower: nil, upper: .full),
            (#line, pos: minPos, forwardY: false, lower: nil, upper: .full),
            (#line, pos: fullPos, forwardY: true, lower: .full, upper: .half),
            (#line, pos: fullPos, forwardY: false, lower: nil,  upper: .full),
            (#line, pos: halfPos, forwardY: true, lower: .half, upper: .tip),
            (#line, pos: halfPos, forwardY: false, lower: .full,  upper: .half),
            (#line, pos: tipPos, forwardY: true, lower: .tip, upper: nil),
            (#line, pos: tipPos, forwardY: false, lower: .half,  upper: .tip),
            (#line, pos: maxPos, forwardY: true, lower: .tip, upper: nil),
            (#line, pos: maxPos, forwardY: false, lower: .tip, upper: nil),
            ])
    }

    func test_layoutSegment_2positions() {
        class FloatingPanelLayout2Positions: FloatingPanelTestLayout {
            let initialPosition: FloatingPanelPosition = .half
            let supportedPositions: Set<FloatingPanelPosition> = [.half, .full]
        }

        let delegate = FloatingPanelTestDelegate()
        delegate.layout = FloatingPanelLayout2Positions()
        fpc.delegate = delegate

        let fullPos = fpc.originYOfSurface(for: .full)
        let halfPos = fpc.originYOfSurface(for: .half)

        let minPos = CGFloat.leastNormalMagnitude
        let maxPos = CGFloat.greatestFiniteMagnitude

        assertLayoutSegment(fpc.floatingPanel, with: [
            (#line, pos: minPos, forwardY: true, lower: nil, upper: .full),
            (#line, pos: minPos, forwardY: false, lower: nil, upper: .full),
            (#line, pos: fullPos, forwardY: true, lower: .full, upper: .half),
            (#line, pos: fullPos, forwardY: false, lower: nil,  upper: .full),
            (#line, pos: halfPos, forwardY: true, lower: .half, upper: nil),
            (#line, pos: halfPos, forwardY: false, lower: .full,  upper: .half),
            (#line, pos: maxPos, forwardY: true, lower: .half, upper: nil),
            (#line, pos: maxPos, forwardY: false, lower: .half, upper: nil),
            ])
    }

    func test_layoutSegment_1positions() {
        class FloatingPanelLayout1Positions: FloatingPanelTestLayout {
            let initialPosition: FloatingPanelPosition = .full
            let supportedPositions: Set<FloatingPanelPosition> = [.full]
        }

        let delegate = FloatingPanelTestDelegate()
        delegate.layout = FloatingPanelLayout1Positions()
        fpc.delegate = delegate

        let fullPos = fpc.originYOfSurface(for: .full)

        let minPos = CGFloat.leastNormalMagnitude
        let maxPos = CGFloat.greatestFiniteMagnitude

        assertLayoutSegment(fpc.floatingPanel, with: [
            (#line, pos: minPos, forwardY: true, lower: nil, upper: .full),
            (#line, pos: minPos, forwardY: false, lower: nil, upper: .full),
            (#line, pos: fullPos, forwardY: true, lower: .full, upper: nil),
            (#line, pos: fullPos, forwardY: false, lower: nil,  upper: .full),
            (#line, pos: maxPos, forwardY: true, lower: .full, upper: nil),
            (#line, pos: maxPos, forwardY: false, lower: .full, upper: nil),
            ])
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

    func test_positionReference() {
        fpc = CustomSafeAreaFloatingPanelController()
        fpc.loadViewIfNeeded()
        fpc.view.frame = CGRect(x: 0, y: 0, width: 375, height: 667)

        class MyFloatingPanelFullLayout: FloatingPanelTestLayout {
            var initialPosition: FloatingPanelPosition = .half
            var positionReference: FloatingPanelLayoutReference {
                return .fromSuperview
            }
        }
        class MyFloatingPanelSafeAreaLayout: FloatingPanelTestLayout {
            var initialPosition: FloatingPanelPosition = .half
            var positionReference: FloatingPanelLayoutReference {
                return .fromSafeArea
            }
        }
        let fullLayout = MyFloatingPanelFullLayout()
        let delegate = FloatingPanelTestDelegate()
        delegate.layout = fullLayout
        fpc.delegate = delegate
        fpc.showForTest()

        XCTAssertEqual(fpc.layout.positionReference, .fromSuperview)
        XCTAssertEqual(fpc.originYOfSurface(for: .full), fullLayout.insetFor(position: .full))
        XCTAssertEqual(fpc.originYOfSurface(for: .half), fpc.view!.frame.height - fullLayout.insetFor(position: .half)!)
        XCTAssertEqual(fpc.originYOfSurface(for: .tip), fpc.view!.frame.height - fullLayout.insetFor(position: .tip)!)

        let safeAreaLayout = MyFloatingPanelSafeAreaLayout()
        delegate.layout = safeAreaLayout
        fpc.delegate = delegate

        XCTAssertEqual(fpc.layout.positionReference, .fromSafeArea)
        XCTAssertEqual(fpc.originYOfSurface(for: .full),
                       fullLayout.insetFor(position: .full)! + fpc.layoutInsets.top)
        XCTAssertEqual(fpc.originYOfSurface(for: .half),
                       fpc.view!.frame.height - (fullLayout.insetFor(position: .half)! +  fpc.layoutInsets.bottom))
        XCTAssertEqual(fpc.originYOfSurface(for: .tip),
                       fpc.view!.frame.height - (fullLayout.insetFor(position: .tip)! +  fpc.layoutInsets.bottom))
    }
}

private typealias LayoutSegmentTestParameter = (UInt, pos: CGFloat, forwardY: Bool, lower: FloatingPanelPosition?, upper: FloatingPanelPosition?)
private func assertLayoutSegment(_ floatingPanel: FloatingPanelCore, with params: [LayoutSegmentTestParameter]) {
    params.forEach { (line, pos, forwardY, lowr, upper) in
        let segument = floatingPanel.layoutAdapter.segument(at: pos, forward: forwardY)
        XCTAssertEqual(segument.lower, lowr, line: line)
        XCTAssertEqual(segument.upper, upper, line: line)
    }
}

private class CustomSafeAreaFloatingPanelController: FloatingPanelController { }
extension CustomSafeAreaFloatingPanelController {
    override var layoutInsets: UIEdgeInsets {
        return UIEdgeInsets(top: 64.0, left: 0.0, bottom: 0.0, right: 34.0)
    }
}
