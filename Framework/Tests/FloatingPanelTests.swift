//
//  Created by Shin Yamamoto on 2019/05/23.
//  Copyright © 2019 Shin Yamamoto. All rights reserved.
//

import XCTest
@testable import FloatingPanel

class FloatingPanelTests: XCTestCase {
    override func setUp() {}
    override func tearDown() {}

    func test_scrolllock() {
        let fpc = FloatingPanelController()

        let contentVC1 = UITableViewController(nibName: nil, bundle: nil)
        XCTAssertEqual(contentVC1.tableView.showsVerticalScrollIndicator, true)
        XCTAssertEqual(contentVC1.tableView.bounces, true)
        fpc.set(contentViewController: contentVC1)
        fpc.track(scrollView: contentVC1.tableView)
        fpc.showForTest()

        XCTAssertEqual(fpc.state, .half)
        XCTAssertEqual(contentVC1.tableView.showsVerticalScrollIndicator, false)
        XCTAssertEqual(contentVC1.tableView.bounces, false)

        fpc.move(to: .full, animated: false)
        XCTAssertEqual(contentVC1.tableView.showsVerticalScrollIndicator, true)
        XCTAssertEqual(contentVC1.tableView.bounces, true)

        fpc.move(to: .tip, animated: false)
        XCTAssertEqual(contentVC1.tableView.showsVerticalScrollIndicator, false)
        XCTAssertEqual(contentVC1.tableView.bounces, false)

        let exp1 = expectation(description: "move to full with animation")
        fpc.move(to: .full, animated: true) {
            XCTAssertEqual(contentVC1.tableView.showsVerticalScrollIndicator, true)
            XCTAssertEqual(contentVC1.tableView.bounces, true)
            exp1.fulfill()
        }
        wait(for: [exp1], timeout: 1.0)

        let exp2 = expectation(description: "move to tip with animation")
        fpc.move(to: .tip, animated: false) {
            XCTAssertEqual(contentVC1.tableView.showsVerticalScrollIndicator, false)
            XCTAssertEqual(contentVC1.tableView.bounces, false)
            exp2.fulfill()
        }
        wait(for: [exp2], timeout: 1.0)

        // Reset the content vc
        let contentVC2 = UITableViewController(nibName: nil, bundle: nil)
        XCTAssertEqual(contentVC2.tableView.showsVerticalScrollIndicator, true)
        XCTAssertEqual(contentVC2.tableView.bounces, true)
        fpc.set(contentViewController: contentVC2)
        fpc.track(scrollView: contentVC2.tableView)
        fpc.show(animated: false, completion: nil)
        XCTAssertEqual(fpc.state, .half)
        XCTAssertEqual(contentVC2.tableView.showsVerticalScrollIndicator, false)
        XCTAssertEqual(contentVC2.tableView.bounces, false)
    }

    func test_getBackdropAlpha_1positions() {
        class FloatingPanelLayout1Positions: FloatingPanelLayout {
            let initialState: FloatingPanelState = .full
            let anchorPosition: FloatingPanelPosition = .bottom
            var stateAnchors: [FloatingPanelState : FloatingPanelLayoutAnchoring] {
                return [.full: FloatingPanelLayoutAnchor(absoluteInset: 20.0, edge: .top, referenceGuide: .superview)]
            }
        }

        let delegate = FloatingPanelTestDelegate()
        let fpc = FloatingPanelController(delegate: delegate)
        fpc.layout = FloatingPanelLayout1Positions()

        fpc.showForTest()

        let fullPos = fpc.surfaceLocation(for: .full).y

        XCTAssertEqual(fpc.floatingPanel.getBackdropAlpha(at: fullPos - 100.0, with: -100.0), 0.3)
        XCTAssertEqual(fpc.floatingPanel.getBackdropAlpha(at: fullPos, with: 0), 0.3)
        XCTAssertEqual(fpc.floatingPanel.getBackdropAlpha(at: fullPos + 100.0, with: 100.0), 0.3) // ok??
    }

    func test_getBackdropAlpha_2positions() {
        class FloatingPanelLayout2Positions: FloatingPanelLayout {
            let initialState: FloatingPanelState = .half
            let anchorPosition: FloatingPanelPosition = .bottom
            var stateAnchors: [FloatingPanelState : FloatingPanelLayoutAnchoring] {
                return [
                    .full: FloatingPanelLayoutAnchor(absoluteInset: 20.0, edge: .top, referenceGuide: .superview),
                    .half: FloatingPanelLayoutAnchor(absoluteInset: 250.0, edge: .bottom, referenceGuide: .superview),
                ]
            }
        }

        let delegate = FloatingPanelTestDelegate()
        let fpc = FloatingPanelController(delegate: delegate)
        fpc.layout = FloatingPanelLayout2Positions()

        fpc.showForTest()

        let fullPos = fpc.surfaceLocation(for: .full).y
        let halfPos = fpc.surfaceLocation(for: .half).y
        let distance1 = abs(halfPos - fullPos)

        fpc.move(to: .full, animated: false)
        XCTAssertEqual(fpc.floatingPanel.getBackdropAlpha(at: fullPos, with: 0.0), 0.3)
        XCTAssertEqual(fpc.floatingPanel.getBackdropAlpha(at: fullPos + distance1 * 0.5, with: distance1), 0.3 * 0.5)
        XCTAssertEqual(fpc.floatingPanel.getBackdropAlpha(at: halfPos, with: distance1), 0.0)

        fpc.move(to: .half, animated: false)
        XCTAssertEqual(fpc.floatingPanel.getBackdropAlpha(at: halfPos, with: 0.0), 0.0)
        XCTAssertEqual(fpc.floatingPanel.getBackdropAlpha(at: fullPos + distance1 * 0.5, with: -0.5 * distance1), 0.3 * 0.5)
        XCTAssertEqual(fpc.floatingPanel.getBackdropAlpha(at: fullPos, with: -1 * distance1), 0.3)
    }

    func test_getBackdropAlpha_2positionsWithHidden() {
        class FloatingPanelLayout2Positions: FloatingPanelTestLayout {
            let initialPosition: FloatingPanelState = .hidden
            let supportedPositions: Set<FloatingPanelState> = [.hidden, .full]
        }
        let delegate = FloatingPanelTestDelegate()
        let fpc = FloatingPanelController(delegate: delegate)
        fpc.layout = FloatingPanelLayout2Positions()

        fpc.showForTest()

        let fullPos = fpc.surfaceLocation(for: .full).y
        let hiddenPos = fpc.surfaceLocation(for: .hidden).y

        XCTAssertEqual(fpc.floatingPanel.getBackdropAlpha(at: fullPos - 100.0, with:  -100.0), 0.3)
        XCTAssertEqual(fpc.floatingPanel.getBackdropAlpha(at: fullPos, with: 0.0), 0.3)
        XCTAssertEqual(fpc.floatingPanel.getBackdropAlpha(at: hiddenPos, with: 100.0), 0.0)
    }

    func test_getBackdropAlpha_3positions() {
        let fpc = FloatingPanelController()
        fpc.showForTest()

        let fullPos = fpc.surfaceLocation(for: .full).y
        let halfPos = fpc.surfaceLocation(for: .half).y
        let tipPos = fpc.surfaceLocation(for: .tip).y
        let distance1 = abs(halfPos - fullPos)
        let distance2 = abs(tipPos - halfPos)

        fpc.move(to: .full, animated: false)
        XCTAssertEqual(fpc.floatingPanel.getBackdropAlpha(at: fullPos, with: 0.0), 0.3)
        XCTAssertEqual(fpc.floatingPanel.getBackdropAlpha(at: fullPos + distance1 * 0.5, with: distance1 * 0.5), 0.3 * 0.5)
        XCTAssertEqual(fpc.floatingPanel.getBackdropAlpha(at: halfPos, with: distance1), 0.0)

        fpc.move(to: .half, animated: false)
        XCTAssertEqual(fpc.floatingPanel.getBackdropAlpha(at: halfPos, with: 0.0), 0.0)
        XCTAssertEqual(fpc.floatingPanel.getBackdropAlpha(at: fullPos + distance1 * 0.5, with: -0.5 * distance1), 0.3 * 0.5)
        XCTAssertEqual(fpc.floatingPanel.getBackdropAlpha(at: fullPos, with: -1 * distance1), 0.3)

        fpc.move(to: .tip, animated: false)
        XCTAssertEqual(fpc.floatingPanel.getBackdropAlpha(at: tipPos, with: 0.0), 0.0)
        XCTAssertEqual(fpc.floatingPanel.getBackdropAlpha(at: halfPos + distance2 * 0.5, with: -0.5 * distance2), 0.0)
        XCTAssertEqual(fpc.floatingPanel.getBackdropAlpha(at: halfPos, with: -1 * distance2), 0.0)
    }

    func test_targetPosition_1positions() {
        class FloatingPanelLayout1Positions: FloatingPanelLayout {
            let initialState: FloatingPanelState = .full
            let anchorPosition: FloatingPanelPosition = .bottom
            var stateAnchors: [FloatingPanelState : FloatingPanelLayoutAnchoring] {
                return [.full: FloatingPanelLayoutAnchor(absoluteInset: 20.0, edge: .top, referenceGuide: .superview)]
            }
        }

        let delegate = FloatingPanelTestDelegate()
        let fpc = FloatingPanelController(delegate: delegate)
        fpc.layout = FloatingPanelLayout1Positions()

        fpc.showForTest()

        let fullPos = fpc.surfaceLocation(for: .full).y

        fpc.move(to: .full, animated: false)
        assertTargetPosition(fpc.floatingPanel, with: [
            (#line, fullPos - 10.0, CGPoint(x: 0.0, y: 1000.0), .full), // redirect
            (#line, fullPos, CGPoint(x: 0.0, y: -1000.0), .full), // redirect
            (#line, fullPos, CGPoint(x: 0.0, y: -100.0), .full), // redirect
            (#line, fullPos, CGPoint(x: 0.0, y: 0.0), .full),
            (#line, fullPos, CGPoint(x: 0.0, y: 100.0), .full), // redirect
            (#line, fullPos, CGPoint(x: 0.0, y: 1000.0), .full), // redirect
            (#line, fullPos + 10.0, CGPoint(x: 0.0, y: 100.0), .full), // redirect
            ])
    }

    func test_targetPosition_2positions() {
        class FloatingPanelLayout2Positions: FloatingPanelLayout {
            let initialState: FloatingPanelState = .half
            let anchorPosition: FloatingPanelPosition = .bottom
            var stateAnchors: [FloatingPanelState : FloatingPanelLayoutAnchoring] {
                return [
                    .full: FloatingPanelLayoutAnchor(absoluteInset: 20.0, edge: .top, referenceGuide: .superview),
                    .half: FloatingPanelLayoutAnchor(absoluteInset: 250.0, edge: .bottom, referenceGuide: .superview),
                ]
            }
        }

        let delegate = FloatingPanelTestDelegate()
        let fpc = FloatingPanelController(delegate: delegate)
        fpc.layout = FloatingPanelLayout2Positions()

        fpc.showForTest()

        let fullPos = fpc.surfaceLocation(for: .full).y
        let halfPos = fpc.surfaceLocation(for: .half).y

        fpc.move(to: .full, animated: false)
        assertTargetPosition(fpc.floatingPanel, with: [
            (#line, fullPos - 10.0, CGPoint(x: 0.0, y: 1000.0), .half), // project to half
            (#line, fullPos, CGPoint(x: 0.0, y: -1000.0), .full), // redirect
            (#line, fullPos, CGPoint(x: 0.0, y: -100.0), .full),
            (#line, fullPos, CGPoint(x: 0.0, y: 0.0), .full),
            (#line, fullPos, CGPoint(x: 0.0, y: 100.0), .full),
            (#line, fullPos, CGPoint(x: 0.0, y: 1000.0), .half), // project to half
            (#line, fullPos + 10.0, CGPoint(x: 0.0, y: 100.0), .full), // redirect
            (#line, halfPos - 10.0, CGPoint(x: 0.0, y: -100.0), .half), // redirect
            (#line, halfPos, CGPoint(x: 0.0, y: -1000.0), .full),  // project to full
            (#line, halfPos, CGPoint(x: 0.0, y: -100.0), .half),
            (#line, halfPos, CGPoint(x: 0.0, y: 0.0), .half),
            (#line, halfPos, CGPoint(x: 0.0, y: 100.0), .half),
            (#line, halfPos, CGPoint(x: 0.0, y: 1000.0), .half), // redirect
            (#line, halfPos + 10.0, CGPoint(x: 0.0, y: -1000.0), .full), // project to full
            ])
        fpc.move(to: .half, animated: false)
        assertTargetPosition(fpc.floatingPanel, with: [
            (#line, fullPos - 10.0, CGPoint(x: 0.0, y: 1000.0), .half), // project to half
            (#line, fullPos, CGPoint(x: 0.0, y: -1000.0), .full), // redirect
            (#line, fullPos, CGPoint(x: 0.0, y: -100.0), .full),
            (#line, fullPos, CGPoint(x: 0.0, y: 0.0), .full),
            (#line, fullPos, CGPoint(x: 0.0, y: 100.0), .full),
            (#line, fullPos, CGPoint(x: 0.0, y: 1000.0), .half), // project to half
            (#line, fullPos + 10.0, CGPoint(x: 0.0, y: 100.0), .full), // redirect
            (#line, halfPos - 10.0, CGPoint(x: 0.0, y: -100.0), .half), // redirect
            (#line, halfPos, CGPoint(x: 0.0, y: -1000.0), .full),  // project to full
            (#line, halfPos, CGPoint(x: 0.0, y: -100.0), .half),
            (#line, halfPos, CGPoint(x: 0.0, y: 0.0), .half),
            (#line, halfPos, CGPoint(x: 0.0, y: 100.0), .half),
            (#line, halfPos, CGPoint(x: 0.0, y: 1000.0), .half), // redirect
            (#line, halfPos + 10.0, CGPoint(x: 0.0, y: -1000.0), .full), // project to full
            ])
    }

    func test_targetPosition_2positionsWithHidden() {
        class FloatingPanelLayout2Positions: FloatingPanelLayout {
            let initialState: FloatingPanelState = .hidden
            let anchorPosition: FloatingPanelPosition = .bottom
            var stateAnchors: [FloatingPanelState : FloatingPanelLayoutAnchoring] {
                return [
                    .full: FloatingPanelLayoutAnchor(absoluteInset: 20.0, edge: .top, referenceGuide: .superview),
                    .hidden: FloatingPanelLayoutAnchor(absoluteInset: 0, edge: .bottom, referenceGuide: .superview),
                ]
            }
        }

        let delegate = FloatingPanelTestDelegate()
        let fpc = FloatingPanelController(delegate: delegate)
        fpc.layout = FloatingPanelLayout2Positions()

        fpc.showForTest()

        let fullPos = fpc.surfaceLocation(for: .full).y
        let hiddenPos = fpc.surfaceLocation(for: .hidden).y

        fpc.move(to: .full, animated: false)
        assertTargetPosition(fpc.floatingPanel, with: [
            (#line, fullPos - 10.0, CGPoint(x: 0.0, y: 1000.0), .hidden), // project to hidden
            (#line, fullPos, CGPoint(x: 0.0, y: -1000.0), .full), // redirect
            (#line, fullPos, CGPoint(x: 0.0, y: -100.0), .full),
            (#line, fullPos, CGPoint(x: 0.0, y: 0.0), .full),
            (#line, fullPos, CGPoint(x: 0.0, y: 100.0), .full),
            (#line, fullPos, CGPoint(x: 0.0, y: 1000.0), .hidden), // project to hidden
            (#line, fullPos + 10.0, CGPoint(x: 0.0, y: 100.0), .full), // redirect
            (#line, hiddenPos - 10.0, CGPoint(x: 0.0, y: -100.0), .hidden), // redirect
            (#line, hiddenPos, CGPoint(x: 0.0, y: -1000.0), .full),  // project to full
            (#line, hiddenPos, CGPoint(x: 0.0, y: -100.0), .hidden),
            (#line, hiddenPos, CGPoint(x: 0.0, y: 0.0), .hidden),
            (#line, hiddenPos, CGPoint(x: 0.0, y: 100.0), .hidden),
            (#line, hiddenPos, CGPoint(x: 0.0, y: 1000.0), .hidden), // redirect
            (#line, hiddenPos + 10.0, CGPoint(x: 0.0, y: -1000.0), .full), // project to full
            ])
        fpc.move(to: .hidden, animated: false)
        assertTargetPosition(fpc.floatingPanel, with: [
            (#line, fullPos - 10.0, CGPoint(x: 0.0, y: 1000.0), .hidden), // project to hidden
            (#line, fullPos, CGPoint(x: 0.0, y: -1000.0), .full), // redirect
            (#line, fullPos, CGPoint(x: 0.0, y: -100.0), .full),
            (#line, fullPos, CGPoint(x: 0.0, y: 0.0), .full),
            (#line, fullPos, CGPoint(x: 0.0, y: 100.0), .full),
            (#line, fullPos, CGPoint(x: 0.0, y: 1000.0), .hidden), // project to hidden
            (#line, fullPos + 10.0, CGPoint(x: 0.0, y: 100.0), .full), // redirect
            (#line, hiddenPos - 10.0, CGPoint(x: 0.0, y: -100.0), .hidden), // redirect
            (#line, hiddenPos, CGPoint(x: 0.0, y: -1000.0), .full),  // project to full
            (#line, hiddenPos, CGPoint(x: 0.0, y: -100.0), .hidden),
            (#line, hiddenPos, CGPoint(x: 0.0, y: 0.0), .hidden),
            (#line, hiddenPos, CGPoint(x: 0.0, y: 100.0), .hidden),
            (#line, hiddenPos, CGPoint(x: 0.0, y: 1000.0), .hidden), // redirect
            (#line, hiddenPos + 10.0, CGPoint(x: 0.0, y: -1000.0), .full), // project to full
            ])
    }

    func test_targetPosition_3positionsFromFull() {
        let delegate = FloatingPanelTestDelegate()
        let fpc = FloatingPanelController(delegate: delegate)
        fpc.layout = FloatingPanelLayout3Positions()

        fpc.showForTest()

        let fullPos = fpc.surfaceLocation(for: .full).y
        let halfPos = fpc.surfaceLocation(for: .half).y
        let tipPos = fpc.surfaceLocation(for: .tip).y
        // From .full
        fpc.move(to: .full, animated: false)
        assertTargetPosition(fpc.floatingPanel, with: [
            (#line, fullPos - 500.0, CGPoint(x: 0.0, y: -100.0), .full), // far from topMostState
            (#line, fullPos - 500.0, CGPoint(x: 0.0, y: 0.0), .full), // far from topMostState
            (#line, fullPos - 500.0, CGPoint(x: 0.0, y: 100.0), .full), // far from topMostState
            (#line, fullPos - 10.0, CGPoint(x: 0.0, y: 3000.0), .half), // block projecting to tip at half
            (#line, fullPos, CGPoint(x: 0.0, y: -100.0), .full),
            (#line, fullPos, CGPoint(x: 0.0, y: 0.0), .full),
            (#line, fullPos, CGPoint(x: 0.0, y: 500.0), .half), // project to half
            (#line, fullPos, CGPoint(x: 0.0, y: 1000.0), .half), // block projecting to tip at half
            (#line, fullPos, CGPoint(x: 0.0, y: 3000.0), .half), // block projecting to tip at half
            (#line, fullPos + 10.0, CGPoint(x: 0.0, y: 100.0), .full), // redirect
            (#line, halfPos - 10.0, CGPoint(x: 0.0, y: -100.0), .half), // redirect
            (#line, halfPos, CGPoint(x: 0.0, y: -1000.0), .full), //project to full
            (#line, halfPos, CGPoint(x: 0.0, y: -100.0), .half),
            (#line, halfPos, CGPoint(x: 0.0, y: 0.0), .half),
            (#line, halfPos, CGPoint(x: 0.0, y: 100.0), .half),
            (#line, halfPos, CGPoint(x: 0.0, y: 1000.0), .tip), // project to tip
            (#line, halfPos + 10.0, CGPoint(x: 0.0, y: 100.0), .half), // redirect
            (#line, tipPos - 10.0, CGPoint(x: 0.0, y: -100.0), .tip), // redirect
            (#line, tipPos, CGPoint(x: 0.0, y: -3000.0), .half), // block projecting to full at half
            (#line, tipPos, CGPoint(x: 0.0, y: -1000.0), .half), // block projecting to full at half
            (#line, tipPos, CGPoint(x: 0.0, y: -500.0), .half), // project to half
            (#line, tipPos, CGPoint(x: 0.0, y: -100.0), .tip),
            (#line, tipPos, CGPoint(x: 0.0, y: 0.0), .tip),
            (#line, tipPos, CGPoint(x: 0.0, y: 100.0), .tip),
            (#line, tipPos + 10.0, CGPoint(x: 0.0, y: -3000.0), .half), // block projecting to full at half
            (#line, tipPos + 500.0, CGPoint(x: 0.0, y: -100.0), .tip), // far from bottomMostState
            (#line, tipPos + 500.0, CGPoint(x: 0.0, y: 0.0), .tip), // far from bottomMostState
            (#line, tipPos + 500.0, CGPoint(x: 0.0, y: 100.0), .tip), // far from bottomMostState
        ])
    }

    func test_targetPosition_3positionsFromFull_bottomEdge() {
        let delegate = FloatingPanelTestDelegate()
        let fpc = FloatingPanelController(delegate: delegate)
        fpc.layout = FloatingPanelLayout3PositionsBottomEdge()

        fpc.showForTest()

        let fullPos = fpc.surfaceLocation(for: .full).y
        let halfPos = fpc.surfaceLocation(for: .half).y
        let tipPos = fpc.surfaceLocation(for: .tip).y
        // From .full
        fpc.move(to: .full, animated: false)
        assertTargetPosition(fpc.floatingPanel, with: [
            (#line, tipPos - 500.0, CGPoint(x: 0.0, y: -100.0), .tip), // far from topMostState
            (#line, tipPos - 500.0, CGPoint(x: 0.0, y: 0.0), .tip), // far from topMostState
            (#line, tipPos - 500.0, CGPoint(x: 0.0, y: 100.0), .tip), // far from topMostState
            (#line, tipPos - 10.0, CGPoint(x: 0.0, y: 3000.0), .half), // block projecting to full at half
            (#line, tipPos, CGPoint(x: 0.0, y: -100.0), .tip),
            (#line, tipPos, CGPoint(x: 0.0, y: 0.0), .tip),
            (#line, tipPos, CGPoint(x: 0.0, y: 500.0), .half), // project to half
            (#line, tipPos, CGPoint(x: 0.0, y: 1000.0), .half), // block projecting to full at half
            (#line, tipPos, CGPoint(x: 0.0, y: 3000.0), .half), // block projecting to full at half
            (#line, tipPos + 10.0, CGPoint(x: 0.0, y: 100.0), .tip), // redirect
            (#line, halfPos - 10.0, CGPoint(x: 0.0, y: -100.0), .half), // redirect
            (#line, halfPos, CGPoint(x: 0.0, y: -1000.0), .tip), //project to tip
            (#line, halfPos, CGPoint(x: 0.0, y: -100.0), .half),
            (#line, halfPos, CGPoint(x: 0.0, y: 0.0), .half),
            (#line, halfPos, CGPoint(x: 0.0, y: 100.0), .half),
            (#line, halfPos, CGPoint(x: 0.0, y: 1000.0), .full), // project to full
            (#line, halfPos + 10.0, CGPoint(x: 0.0, y: 100.0), .half), // redirect
            (#line, fullPos - 10.0, CGPoint(x: 0.0, y: -100.0), .full), // redirect
            (#line, fullPos, CGPoint(x: 0.0, y: -3000.0), .half), // block projecting to tip at half
            (#line, fullPos, CGPoint(x: 0.0, y: -1000.0), .half), // block projecting to tip at half
            (#line, fullPos, CGPoint(x: 0.0, y: -500.0), .half), // project to half
            (#line, fullPos, CGPoint(x: 0.0, y: -100.0), .full),
            (#line, fullPos, CGPoint(x: 0.0, y: 0.0), .full),
            (#line, fullPos, CGPoint(x: 0.0, y: 100.0), .full),
            (#line, fullPos + 10.0, CGPoint(x: 0.0, y: -3000.0), .half), // block projecting to tip at half
            (#line, fullPos + 500.0, CGPoint(x: 0.0, y: -100.0), .full), // far from bottomMostState
            (#line, fullPos + 500.0, CGPoint(x: 0.0, y: 0.0), .full), // far from bottomMostState
            (#line, fullPos + 500.0, CGPoint(x: 0.0, y: 100.0), .full), // far from bottomMostState
        ])
    }

    func test_targetPosition_3positionsFromHalf() {
        let delegate = FloatingPanelTestDelegate()
        let fpc = FloatingPanelController(delegate: delegate)
        fpc.layout = FloatingPanelLayout3Positions()

        fpc.showForTest()

        let fullPos = fpc.surfaceLocation(for: .full).y
        let halfPos = fpc.surfaceLocation(for: .half).y
        let tipPos = fpc.surfaceLocation(for: .tip).y
        // From .half
        fpc.move(to: .half, animated: false)
        assertTargetPosition(fpc.floatingPanel, with: [
            (#line, fullPos - 500.0, CGPoint(x: 0.0, y: -100.0), .full), // far from topMostState
            (#line, fullPos - 500.0, CGPoint(x: 0.0, y: 0.0), .full), // far from topMostState
            (#line, fullPos - 500.0, CGPoint(x: 0.0, y: 100.0), .full), // far from topMostState
            (#line, fullPos, CGPoint(x: 0.0, y: -100.0), .full),
            (#line, fullPos, CGPoint(x: 0.0, y: 0.0), .full),
            (#line, fullPos, CGPoint(x: 0.0, y: 500.0), .half), // project to half
            (#line, fullPos, CGPoint(x: 0.0, y: 1000.0), .half), // block projecting to tip at half
            (#line, fullPos, CGPoint(x: 0.0, y: 3000.0), .half), // block projecting to tip at half
            (#line, fullPos + 10.0, CGPoint(x: 0.0, y: 100.0), .full), // redirect
            (#line, halfPos - 10.0, CGPoint(x: 0.0, y: -100.0), .half), // redirect
            (#line, halfPos, CGPoint(x: 0.0, y: -1000.0), .full),// project to full
            (#line, halfPos, CGPoint(x: 0.0, y: -100.0), .half),
            (#line, halfPos, CGPoint(x: 0.0, y: 0.0), .half),
            (#line, halfPos, CGPoint(x: 0.0, y: 100.0), .half),
            (#line, halfPos, CGPoint(x: 0.0, y: 1000.0), .tip), // project to tip
            (#line, halfPos + 10.0, CGPoint(x: 0.0, y: 100.0), .half), // redirect
            (#line, tipPos - 10.0, CGPoint(x: 0.0, y: -100.0), .tip), // redirect
            (#line, tipPos, CGPoint(x: 0.0, y: -3000.0), .half), // block projecting to full at half
            (#line, tipPos, CGPoint(x: 0.0, y: -1000.0), .half), // block projecting to full at half
            (#line, tipPos, CGPoint(x: 0.0, y: -500.0), .half), // project to half
            (#line, tipPos, CGPoint(x: 0.0, y: -100.0), .tip),
            (#line, tipPos, CGPoint(x: 0.0, y: 0.0), .tip),
            (#line, tipPos, CGPoint(x: 0.0, y: 100.0), .tip),
            (#line, tipPos + 500.0, CGPoint(x: 0.0, y: -100.0), .tip), // far from bottomMostState
            (#line, tipPos + 500.0, CGPoint(x: 0.0, y: 0.0), .tip), // far from bottomMostState
            (#line, tipPos + 500.0, CGPoint(x: 0.0, y: 100.0), .tip), // far from bottomMostState
        ])
    }

    func test_targetPosition_3positionsFromHalf_bottomEdge() {
        let delegate = FloatingPanelTestDelegate()
        let fpc = FloatingPanelController(delegate: delegate)
        fpc.layout = FloatingPanelLayout3PositionsBottomEdge()

            fpc.showForTest()

            let fullPos = fpc.surfaceLocation(for: .full).y
            let halfPos = fpc.surfaceLocation(for: .half).y
            let tipPos = fpc.surfaceLocation(for: .tip).y
            // From .half
            fpc.move(to: .half, animated: false)
            assertTargetPosition(fpc.floatingPanel, with: [
                (#line, tipPos - 500.0, CGPoint(x: 0.0, y: -100.0), .tip), // far from topMostState
                (#line, tipPos - 500.0, CGPoint(x: 0.0, y: 0.0), .tip), // far from topMostState
                (#line, tipPos - 500.0, CGPoint(x: 0.0, y: 100.0), .tip), // far from topMostState
                (#line, tipPos, CGPoint(x: 0.0, y: -100.0), .tip),
                (#line, tipPos, CGPoint(x: 0.0, y: 0.0), .tip),
                (#line, tipPos, CGPoint(x: 0.0, y: 500.0), .half), // project to half
                (#line, tipPos, CGPoint(x: 0.0, y: 1000.0), .half), // block projecting to full at half
                (#line, tipPos, CGPoint(x: 0.0, y: 3000.0), .half), // block projecting to full at half
                (#line, tipPos + 10.0, CGPoint(x: 0.0, y: 100.0), .tip), // redirect
                (#line, halfPos - 10.0, CGPoint(x: 0.0, y: -100.0), .half), // redirect
                (#line, halfPos, CGPoint(x: 0.0, y: -1000.0), .tip),// project to tip
                (#line, halfPos, CGPoint(x: 0.0, y: -100.0), .half),
                (#line, halfPos, CGPoint(x: 0.0, y: 0.0), .half),
                (#line, halfPos, CGPoint(x: 0.0, y: 100.0), .half),
                (#line, halfPos, CGPoint(x: 0.0, y: 1000.0), .full), // project to full
                (#line, halfPos + 10.0, CGPoint(x: 0.0, y: 100.0), .half), // redirect
                (#line, fullPos - 10.0, CGPoint(x: 0.0, y: -100.0), .full), // redirect
                (#line, fullPos, CGPoint(x: 0.0, y: -3000.0), .half), // block projecting to tip at half
                (#line, fullPos, CGPoint(x: 0.0, y: -1000.0), .half), // block projecting to tip at half
                (#line, fullPos, CGPoint(x: 0.0, y: -500.0), .half), // project to half
                (#line, fullPos, CGPoint(x: 0.0, y: -100.0), .full),
                (#line, fullPos, CGPoint(x: 0.0, y: 0.0), .full),
                (#line, fullPos, CGPoint(x: 0.0, y: 100.0), .full),
                (#line, fullPos + 500.0, CGPoint(x: 0.0, y: -100.0), .full), // far from bottomMostState
                (#line, fullPos + 500.0, CGPoint(x: 0.0, y: 0.0), .full), // far from bottomMostState
                (#line, fullPos + 500.0, CGPoint(x: 0.0, y: 100.0), .full), // far from bottomMostState
            ])
    }

    func test_targetPosition_3positionsFromTip() {
        let delegate = FloatingPanelTestDelegate()
        let fpc = FloatingPanelController(delegate: delegate)
        fpc.layout = FloatingPanelLayout3Positions()

        fpc.showForTest()

        let fullPos = fpc.surfaceLocation(for: .full).y
        let halfPos = fpc.surfaceLocation(for: .half).y
        let tipPos = fpc.surfaceLocation(for: .tip).y

        // From .tip
        fpc.move(to: .tip, animated: false)
        assertTargetPosition(fpc.floatingPanel, with: [
            (#line, fullPos - 500.0, CGPoint(x: 0.0, y: -100.0), .full), // far from topMostState
            (#line, fullPos - 500.0, CGPoint(x: 0.0, y: 0.0), .full), // far from topMostState
            (#line, fullPos - 500.0, CGPoint(x: 0.0, y: 100.0), .full), // far from topMostState
            (#line, fullPos, CGPoint(x: 0.0, y: -100.0), .full),
            (#line, fullPos, CGPoint(x: 0.0, y: 0.0), .full),
            (#line, fullPos, CGPoint(x: 0.0, y: 500.0), .half), // project to half
            (#line, fullPos, CGPoint(x: 0.0, y: 1000.0), .half), // block projecting to tip at half
            (#line, fullPos, CGPoint(x: 0.0, y: 3000.0), .half), // block projecting to tip at half
            (#line, fullPos + 10.0, CGPoint(x: 0.0, y: 100.0), .full), // redirect
            (#line, halfPos - 10.0, CGPoint(x: 0.0, y: -100.0), .half), // redirect
            (#line, halfPos, CGPoint(x: 0.0, y: -3000.0), .full), // project to full
            (#line, halfPos, CGPoint(x: 0.0, y: -100.0), .half),
            (#line, halfPos, CGPoint(x: 0.0, y: 0.0), .half),
            (#line, halfPos, CGPoint(x: 0.0, y: 100.0), .half),
            (#line, halfPos, CGPoint(x: 0.0, y: 1000.0), .tip), // project to tip
            (#line, halfPos + 10.0, CGPoint(x: 0.0, y: 100.0), .half), // redirect
            (#line, tipPos - 10.0, CGPoint(x: 0.0, y: -100.0), .tip), // redirect
            (#line, tipPos, CGPoint(x: 0.0, y: -3000.0), .half), // block projecting to full at half
            (#line, tipPos, CGPoint(x: 0.0, y: -1000.0), .half), // block projecting to full at half
            (#line, tipPos, CGPoint(x: 0.0, y: -500.0), .half), // project to half
            (#line, tipPos, CGPoint(x: 0.0, y: -100.0), .tip),
            (#line, tipPos, CGPoint(x: 0.0, y: 0.0), .tip),
            (#line, tipPos, CGPoint(x: 0.0, y: 100.0), .tip),
            (#line, tipPos + 500.0, CGPoint(x: 0.0, y: -100.0), .tip), // far from bottomMostState
            (#line, tipPos + 500.0, CGPoint(x: 0.0, y: 0.0), .tip), // far from bottomMostState
            (#line, tipPos + 500.0, CGPoint(x: 0.0, y: 100.0), .tip), // far from bottomMostState
        ])
    }

    func test_targetPosition_3positionsFromTip_bottomEdge() {
        let delegate = FloatingPanelTestDelegate()
        let fpc = FloatingPanelController(delegate: delegate)
        fpc.layout = FloatingPanelLayout3PositionsBottomEdge()

        fpc.showForTest()

            let fullPos = fpc.surfaceLocation(for: .full).y
            let halfPos = fpc.surfaceLocation(for: .half).y
            let tipPos = fpc.surfaceLocation(for: .tip).y

            // From .tip
            fpc.move(to: .tip, animated: false)
            assertTargetPosition(fpc.floatingPanel, with: [
                (#line, tipPos - 500.0, CGPoint(x: 0.0, y: -100.0), .tip), // far from topMostState
                (#line, tipPos - 500.0, CGPoint(x: 0.0, y: 0.0), .tip), // far from topMostState
                (#line, tipPos - 500.0, CGPoint(x: 0.0, y: 100.0), .tip), // far from topMostState
                (#line, tipPos, CGPoint(x: 0.0, y: -100.0), .tip),
                (#line, tipPos, CGPoint(x: 0.0, y: 0.0), .tip),
                (#line, tipPos, CGPoint(x: 0.0, y: 500.0), .half), // project to half
                (#line, tipPos, CGPoint(x: 0.0, y: 1000.0), .half), // block projecting to tip at half
                (#line, tipPos, CGPoint(x: 0.0, y: 3000.0), .half), // block projecting to tip at half
                (#line, tipPos + 10.0, CGPoint(x: 0.0, y: 100.0), .tip), // redirect
                (#line, halfPos - 10.0, CGPoint(x: 0.0, y: -100.0), .half), // redirect
                (#line, halfPos, CGPoint(x: 0.0, y: -3000.0), .tip), // project to full
                (#line, halfPos, CGPoint(x: 0.0, y: -100.0), .half),
                (#line, halfPos, CGPoint(x: 0.0, y: 0.0), .half),
                (#line, halfPos, CGPoint(x: 0.0, y: 100.0), .half),
                (#line, halfPos, CGPoint(x: 0.0, y: 1000.0), .full), // project to tip
                (#line, halfPos + 10.0, CGPoint(x: 0.0, y: 100.0), .half), // redirect
                (#line, fullPos - 10.0, CGPoint(x: 0.0, y: -100.0), .full), // redirect
                (#line, fullPos, CGPoint(x: 0.0, y: -3000.0), .half), // block projecting to full at half
                (#line, fullPos, CGPoint(x: 0.0, y: -1000.0), .half), // block projecting to full at half
                (#line, fullPos, CGPoint(x: 0.0, y: -500.0), .half), // project to half
                (#line, fullPos, CGPoint(x: 0.0, y: -100.0), .full),
                (#line, fullPos, CGPoint(x: 0.0, y: 0.0), .full),
                (#line, fullPos, CGPoint(x: 0.0, y: 100.0), .full),
                (#line, fullPos + 500.0, CGPoint(x: 0.0, y: -100.0), .full), // far from bottomMostState
                (#line, fullPos + 500.0, CGPoint(x: 0.0, y: 0.0), .full), // far from bottomMostState
                (#line, fullPos + 500.0, CGPoint(x: 0.0, y: 100.0), .full), // far from bottomMostState
            ])
    }

    func test_targetPosition_3positionsAllProjection() {
        let delegate = FloatingPanelTestDelegate()
        let fpc = FloatingPanelController(delegate: delegate)
        fpc.layout = FloatingPanelLayout3Positions()
        fpc.behavior = FloatingPanelProjectableBehavior()

        fpc.showForTest()

        let fullPos = fpc.surfaceLocation(for: .full).y
        let halfPos = fpc.surfaceLocation(for: .half).y
        let tipPos = fpc.surfaceLocation(for: .tip).y

        // From .full
        fpc.move(to: .full, animated: false)
        assertTargetPosition(fpc.floatingPanel, with: [
            (#line, fullPos - 10.0, CGPoint(x: 0.0, y: 3000.0), .tip),
            (#line, fullPos, CGPoint(x: 0.0, y: 1000.0), .tip),
            (#line, fullPos, CGPoint(x: 0.0, y: 3000.0), .tip),
            (#line, halfPos, CGPoint(x: 0.0, y: 1000.0), .tip),
            (#line, halfPos, CGPoint(x: 0.0, y: -1000.0), .full),
            (#line, tipPos, CGPoint(x: 0.0, y: -3000.0), .full),
            (#line, tipPos, CGPoint(x: 0.0, y: -1000.0), .full),
            (#line, tipPos + 10.0, CGPoint(x: 0.0, y: -3000.0), .full),
            ])

        // From .half
        fpc.move(to: .tip, animated: false)
        assertTargetPosition(fpc.floatingPanel, with: [
            (#line, fullPos, CGPoint(x: 0.0, y: 1000.0), .tip),
            (#line, fullPos, CGPoint(x: 0.0, y: 3000.0), .tip),
            (#line, tipPos, CGPoint(x: 0.0, y: -3000.0), .full),
            (#line, tipPos, CGPoint(x: 0.0, y: -1000.0), .full),
            ])

        // From .tip
        fpc.move(to: .tip, animated: false)
        assertTargetPosition(fpc.floatingPanel, with: [
            (#line, fullPos - 10.0, CGPoint(x: 0.0, y: 3000.0), .tip),
            (#line, fullPos, CGPoint(x: 0.0, y: 1000.0), .tip),
            (#line, fullPos, CGPoint(x: 0.0, y: 3000.0), .tip),
            (#line, halfPos, CGPoint(x: 0.0, y: 1000.0), .tip),
            (#line, halfPos, CGPoint(x: 0.0, y: -1000.0), .full),
            (#line, tipPos, CGPoint(x: 0.0, y: -3000.0), .full),
            (#line, tipPos, CGPoint(x: 0.0, y: -1000.0), .full),
            (#line, tipPos + 10.0, CGPoint(x: 0.0, y: -3000.0), .full),
            ])
    }

    func test_targetPosition_3positionsWithHidden() {
        class FloatingPanelLayout3PositionsWithHidden: FloatingPanelLayout {
            let initialState: FloatingPanelState = .hidden
            let anchorPosition: FloatingPanelPosition = .bottom
            var stateAnchors: [FloatingPanelState : FloatingPanelLayoutAnchoring] {
                return [
                    .full: FloatingPanelLayoutAnchor(absoluteInset: 20.0, edge: .top, referenceGuide: .superview),
                    .half: FloatingPanelLayoutAnchor(absoluteInset: 250.0, edge: .bottom, referenceGuide: .superview),
                    .hidden: FloatingPanelLayoutAnchor(absoluteInset: 0, edge: .bottom, referenceGuide: .superview),
                ]
            }
        }
        let delegate = FloatingPanelTestDelegate()
        let fpc = FloatingPanelController(delegate: delegate)
        fpc.layout = FloatingPanelLayout3PositionsWithHidden()

        fpc.showForTest()
        XCTAssertEqual(fpc.state, .hidden)

        fpc.move(to: .full, animated: false)
        assertTargetPosition(fpc.floatingPanel, with: [
            (#line, fpc.surfaceView.frame.minY, CGPoint(x: 0.0, y: 1000.0), .half),
            ])
        fpc.move(to: .half, animated: false)
        assertTargetPosition(fpc.floatingPanel, with: [
            (#line, fpc.surfaceView.frame.minY, CGPoint(x: 0.0, y: -100.0), .half),
            (#line, fpc.surfaceView.frame.minY, CGPoint(x: 0.0, y: -1000.0), .full),
            (#line, fpc.surfaceView.frame.minY, CGPoint(x: 0.0, y: 0.0), .half),
            (#line, fpc.surfaceView.frame.minY, CGPoint(x: 0.0, y: 1000.0), .hidden),
            ])
    }

    func test_targetPosition_3positionsWithHiddenWithoutFull() {
        class FloatingPanelLayout3Positions: FloatingPanelLayout {
            let initialState: FloatingPanelState = .hidden
            let anchorPosition: FloatingPanelPosition = .bottom
            var stateAnchors: [FloatingPanelState : FloatingPanelLayoutAnchoring] {
                return [
                    .half: FloatingPanelLayoutAnchor(absoluteInset: 250.0, edge: .bottom, referenceGuide: .superview),
                    .tip: FloatingPanelLayoutAnchor(absoluteInset: 60.0, edge: .bottom, referenceGuide: .superview),
                    .hidden: FloatingPanelLayoutAnchor(absoluteInset: 0, edge: .bottom, referenceGuide: .superview),
                ]
            }
        }

        let delegate = FloatingPanelTestDelegate()
        let fpc = FloatingPanelController(delegate: delegate)
        fpc.layout = FloatingPanelLayout3Positions()

        fpc.showForTest()
        fpc.behavior = FloatingPanelProjectableBehavior()
        XCTAssertEqual(fpc.state, .hidden)

        let halfPos = fpc.surfaceLocation(for: .half).y
        let tipPos = fpc.surfaceLocation(for: .tip).y
        //let hiddenPos = fpc.surfaceLocation(for: .hidden)

        fpc.move(to: .half, animated: false)
        assertTargetPosition(fpc.floatingPanel, with: [
            (#line, halfPos, CGPoint(x: 0.0, y: -100.0), .half),
            (#line, halfPos, CGPoint(x: 0.0, y: 0.0), .half),
            (#line, halfPos, CGPoint(x: 0.0, y: 385.0), .tip), // projection
            (#line, halfPos, CGPoint(x: 0.0, y: 1000.0), .hidden), // projection
            (#line, halfPos + 10.0, CGPoint(x: 0.0, y: 100.0), .half), // redirection
            (#line, tipPos - 10.0, CGPoint(x: 0.0, y: -100.0), .tip), // redirection
            (#line, tipPos, CGPoint(x: 0.0, y: -3000.0), .half), //projection
            (#line, tipPos, CGPoint(x: 0.0, y: -10.0), .tip),
            (#line, tipPos, CGPoint(x: 0.0, y: 0.0), .tip),
            (#line, tipPos, CGPoint(x: 0.0, y: 10.0), .tip),
            (#line, tipPos, CGPoint(x: 0.0, y: 1000.0), .hidden), //projection
            (#line, tipPos + 10.0, CGPoint(x: 0.0, y: 10.0), .tip), // redirection
            (#line, tipPos - 10.0, CGPoint(x: 0.0, y: 10.0), .tip), // redirection
            ])
        fpc.move(to: .tip, animated: false)
        assertTargetPosition(fpc.floatingPanel, with: [
            (#line, tipPos, CGPoint(x: 0.0, y: -100.0), .tip),
            (#line, tipPos, CGPoint(x: 0.0, y: -1000.0), .half),
            (#line, tipPos, CGPoint(x: 0.0, y: 0.0), .tip),
            (#line, tipPos, CGPoint(x: 0.0, y: 1000.0), .hidden),
            ])
    }
}

private class FloatingPanelLayout3Positions: FloatingPanelTestLayout {
    override var initialState: FloatingPanelState {
        return .tip
    }
}

private class FloatingPanelLayout3PositionsBottomEdge: FloatingPanelTop2BottomTestLayout {
    override var initialState: FloatingPanelState {
        return .tip
    }
}

private typealias TestParameter = (UInt, CGFloat,  CGPoint, FloatingPanelState)
private func assertTargetPosition(_ floatingPanel: FloatingPanelCore, with params: [TestParameter]) {
    params.forEach { (line, pos, velocity, result) in
        floatingPanel.surfaceView.frame.origin.y = pos
        XCTAssertEqual(floatingPanel.targetPosition(from: pos, with: velocity.y), result, line: line)
    }
}
