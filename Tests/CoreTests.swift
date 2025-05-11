// Copyright 2018 the FloatingPanel authors. All rights reserved. MIT license.

import XCTest
@testable import FloatingPanel

class CoreTests: XCTestCase {
    override func setUp() {}
    override func tearDown() {}

    func test_scrollLock() {
        let timeout = 5.0
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
        wait(for: [exp1], timeout: timeout)

        let exp2 = expectation(description: "move to tip with animation")
        fpc.move(to: .tip, animated: false) {
            XCTAssertEqual(contentVC1.tableView.showsVerticalScrollIndicator, false)
            XCTAssertEqual(contentVC1.tableView.bounces, false)
            exp2.fulfill()
        }
        wait(for: [exp2], timeout: timeout)

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
            let position: FloatingPanelPosition = .bottom
            let anchors: [FloatingPanelState : FloatingPanelLayoutAnchoring] =
                [.full: FloatingPanelLayoutAnchor(absoluteInset: 20.0, edge: .top, referenceGuide: .superview)]
        }

        let delegate = FloatingPanelTestDelegate()
        let fpc = FloatingPanelController(delegate: delegate)
        fpc.layout = FloatingPanelLayout1Positions()

        fpc.showForTest()

        let fullPos = fpc.surfaceLocation(for: .full).y

        XCTAssertEqual(fpc.floatingPanel.getBackdropAlpha(at: fullPos - 100.0, with: -100.0), 0.3)
        XCTAssertEqual(fpc.floatingPanel.getBackdropAlpha(at: fullPos, with: 0), 0.3)
        XCTAssertLessThan(fpc.floatingPanel.getBackdropAlpha(at: fullPos + 100.0, with: 100.0), 0.3)
    }

    func test_getBackdropAlpha_1positionsWithInitialHidden() {
        class FloatingPanelLayout2Positions: FloatingPanelTestLayout {
            override var initialState: FloatingPanelState { .hidden }
            override var anchors: [FloatingPanelState : FloatingPanelLayoutAnchoring] {
                return [
                    .full: FloatingPanelLayoutAnchor(absoluteInset: fullInset, edge: .top, referenceGuide: referenceGuide),
                ]
            }
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

    func test_getBackdropAlpha_2positions() {
        class FloatingPanelLayout2Positions: FloatingPanelLayout {
            let initialState: FloatingPanelState = .half
            let position: FloatingPanelPosition = .bottom
            let anchors: [FloatingPanelState : FloatingPanelLayoutAnchoring] = [
                .full: FloatingPanelLayoutAnchor(absoluteInset: 20.0, edge: .top, referenceGuide: .superview),
                .half: FloatingPanelLayoutAnchor(absoluteInset: 250.0, edge: .bottom, referenceGuide: .superview),
            ]
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
            override var initialState: FloatingPanelState { .hidden }
            override var anchors: [FloatingPanelState : FloatingPanelLayoutAnchoring] {
                return [
                    .full: FloatingPanelLayoutAnchor(absoluteInset: fullInset, edge: .top, referenceGuide: referenceGuide),
                    .hidden: FloatingPanelLayoutAnchor(absoluteInset: 0.0, edge: .bottom, referenceGuide: referenceGuide),
                ]
            }
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


    func test_updateBackdropAlpha() {
        class BackdropTestLayout: FloatingPanelTestLayout {
            override var initialState: FloatingPanelState { .hidden }
            func backdropAlpha(for state: FloatingPanelState) -> CGFloat {
                switch state {
                case .full: return 0.3
                case .half: return 0.0
                case .tip: return 0.3
                default: return 0.0
                }
            }
        }
        class BackdropTestLayout2: FloatingPanelTestLayout {
            func backdropAlpha(for state: FloatingPanelState) -> CGFloat {
                return 0.0
            }
        }
        class TestDelegate: FloatingPanelControllerDelegate {
            var layout: FloatingPanelLayout = BackdropTestLayout2()
            func floatingPanel(_ fpc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout { layout }
            func floatingPanel(_ fpc: FloatingPanelController, layoutFor size: CGSize) -> FloatingPanelLayout { layout }
        }
        func round(_ alpha: CGFloat) -> CGFloat {
            return (fpc.backdropView.alpha * 1e+06).rounded() / 1e+06
        }

        let timeout = 5.0

        let delegate = TestDelegate()
        let fpc = FloatingPanelController(delegate: delegate)
        fpc.layout = BackdropTestLayout()

        fpc.showForTest()

        fpc.move(to: .full, animated: false)
        XCTAssertEqual(round(fpc.backdropView.alpha), 0.3)

        fpc.move(to: .half, animated: false)
        XCTAssertEqual(fpc.backdropView.alpha, 0.0)

        fpc.move(to: .tip, animated: false)
        XCTAssertEqual(round(fpc.backdropView.alpha), 0.3)

        let exp1 = expectation(description: "move to full with animation")
        fpc.move(to: .full, animated: true) {
            exp1.fulfill()
        }
        wait(for: [exp1], timeout: timeout)
        XCTAssertEqual(round(fpc.backdropView.alpha), 0.3)

        let exp2 = expectation(description: "move to half with animation")
        fpc.move(to: .half, animated: true) {
            exp2.fulfill()
        }
        wait(for: [exp2], timeout: timeout)
        XCTAssertEqual(fpc.backdropView.alpha, 0.0)

        // Test a content mode change of FloatingPanelController

        let exp3 = expectation(description: "move to tip with animation")
        fpc.move(to: .tip, animated: true) {
            exp3.fulfill()
        }
        fpc.contentMode = .fitToBounds
        XCTAssertEqual(fpc.backdropView.alpha, 0.0)  // Must not affect the backdrop alpha by changing the content mode
        wait(for: [exp3], timeout: timeout)
        XCTAssertEqual(round(fpc.backdropView.alpha), 0.3)

        // Test a size class change of FloatingPanelController.view

        fpc.move(to: .full, animated: false)
        XCTAssertEqual(round(fpc.backdropView.alpha), 0.3)
        fpc.willTransition(to: UITraitCollection(horizontalSizeClass: .regular), with: MockTransitionCoordinator())
        XCTAssertEqual(fpc.backdropView.alpha, 0.0) // Must update the alpha by BackdropTestLayout2 in TestDelegate.

        // Test a view size change of FloatingPanelController.view

        fpc.move(to: .full, animated: false)
        delegate.layout = BackdropTestLayout()
        fpc.invalidateLayout()
        XCTAssertEqual(round(fpc.backdropView.alpha), 0.3)

        delegate.layout = BackdropTestLayout2()
        fpc.viewWillTransition(to: CGSize.zero, with: MockTransitionCoordinator())
        XCTAssertEqual(fpc.backdropView.alpha, 0.0) // Must update the alpha by BackdropTestLayout2 in TestDelegate.
    }

    func test_initial_surface_position() {
        class FloatingPanelTestDelegate: FloatingPanelControllerDelegate {
            class Layout: FloatingPanelLayout {
                let initialState: FloatingPanelState = .full
                let position: FloatingPanelPosition = .top
                let anchors: [FloatingPanelState : FloatingPanelLayoutAnchoring]
                    = [.full: FloatingPanelLayoutAnchor(absoluteInset: 20.0, edge: .bottom, referenceGuide: .superview)]
            }
            func floatingPanel(_ fpc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout {
                Layout()
            }
        }
        do {
            let delegate = FloatingPanelTestDelegate()
            let fpc = FloatingPanelController(delegate: delegate)
            XCTAssertEqual(fpc.surfaceView.position, .top)
        }
        do {
            let fpc = FloatingPanelController()
            fpc.layout = FloatingPanelTestDelegate.Layout()
            XCTAssertEqual(fpc.surfaceView.position, .top)
        }
    }

    func test_targetState_1positions() {
        class FloatingPanelLayout1Positions: FloatingPanelLayout {
            let initialState: FloatingPanelState = .full
            let position: FloatingPanelPosition = .bottom
            let anchors: [FloatingPanelState : FloatingPanelLayoutAnchoring]
                = [.full: FloatingPanelLayoutAnchor(absoluteInset: 20.0, edge: .top, referenceGuide: .superview)]
        }

        let delegate = FloatingPanelTestDelegate()
        let fpc = FloatingPanelController(delegate: delegate)
        fpc.layout = FloatingPanelLayout1Positions()

        fpc.showForTest()

        let fullPos = fpc.surfaceLocation(for: .full).y

        fpc.move(to: .full, animated: false)
        assertTargetState(fpc.floatingPanel, with: [
            (#line, fullPos - 10.0, CGPoint(x: 0.0, y: 1000.0), .full), // redirect
            (#line, fullPos, CGPoint(x: 0.0, y: -1000.0), .full), // redirect
            (#line, fullPos, CGPoint(x: 0.0, y: -100.0), .full), // redirect
            (#line, fullPos, CGPoint(x: 0.0, y: 0.0), .full),
            (#line, fullPos, CGPoint(x: 0.0, y: 100.0), .full), // redirect
            (#line, fullPos, CGPoint(x: 0.0, y: 1000.0), .full), // redirect
            (#line, fullPos + 10.0, CGPoint(x: 0.0, y: 100.0), .full), // redirect
            ])
    }

    func test_targetState_2positions() {
        class FloatingPanelLayout2Positions: FloatingPanelLayout {
            let initialState: FloatingPanelState = .half
            let position: FloatingPanelPosition = .bottom
            let anchors: [FloatingPanelState : FloatingPanelLayoutAnchoring] = [
                .full: FloatingPanelLayoutAnchor(absoluteInset: 20.0, edge: .top, referenceGuide: .superview),
                .half: FloatingPanelLayoutAnchor(absoluteInset: 250.0, edge: .bottom, referenceGuide: .superview),
            ]
        }

        let delegate = FloatingPanelTestDelegate()
        let fpc = FloatingPanelController(delegate: delegate)
        fpc.layout = FloatingPanelLayout2Positions()

        fpc.showForTest()

        let fullPos = fpc.surfaceLocation(for: .full).y
        let halfPos = fpc.surfaceLocation(for: .half).y

        fpc.move(to: .full, animated: false)
        assertTargetState(fpc.floatingPanel, with: [
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
        assertTargetState(fpc.floatingPanel, with: [
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

    func test_targetState_2positionsWithHidden() {
        class FloatingPanelLayout2Positions: FloatingPanelLayout {
            let initialState: FloatingPanelState = .hidden
            let position: FloatingPanelPosition = .bottom
            let anchors: [FloatingPanelState : FloatingPanelLayoutAnchoring] = [
                .full: FloatingPanelLayoutAnchor(absoluteInset: 20.0, edge: .top, referenceGuide: .superview),
                .hidden: FloatingPanelLayoutAnchor(absoluteInset: 0, edge: .bottom, referenceGuide: .superview),
            ]
        }

        let delegate = FloatingPanelTestDelegate()
        let fpc = FloatingPanelController(delegate: delegate)
        fpc.layout = FloatingPanelLayout2Positions()

        fpc.showForTest()

        let fullPos = fpc.surfaceLocation(for: .full).y
        let hiddenPos = fpc.surfaceLocation(for: .hidden).y

        fpc.move(to: .full, animated: false)
        assertTargetState(fpc.floatingPanel, with: [
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
        assertTargetState(fpc.floatingPanel, with: [
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

    func test_targetState_3positionsFromFull() {
        let delegate = FloatingPanelTestDelegate()
        let fpc = FloatingPanelController(delegate: delegate)
        fpc.layout = FloatingPanelLayout3Positions()

        fpc.showForTest()

        let fullPos = fpc.surfaceLocation(for: .full).y
        let halfPos = fpc.surfaceLocation(for: .half).y
        let tipPos = fpc.surfaceLocation(for: .tip).y
        // From .full
        fpc.move(to: .full, animated: false)
        assertTargetState(fpc.floatingPanel, with: [
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

    func test_targetState_3positionsFromFull_bottomEdge() {
        let delegate = FloatingPanelTestDelegate()
        let fpc = FloatingPanelController(delegate: delegate)
        fpc.layout = FloatingPanelLayout3PositionsBottomEdge()

        fpc.showForTest()

        let fullPos = fpc.surfaceLocation(for: .full).y
        let halfPos = fpc.surfaceLocation(for: .half).y
        let tipPos = fpc.surfaceLocation(for: .tip).y
        // From .full
        fpc.move(to: .full, animated: false)
        assertTargetState(fpc.floatingPanel, with: [
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

    func test_targetState_3positionsFromHalf() {
        let delegate = FloatingPanelTestDelegate()
        let fpc = FloatingPanelController(delegate: delegate)
        fpc.layout = FloatingPanelLayout3Positions()

        fpc.showForTest()

        let fullPos = fpc.surfaceLocation(for: .full).y
        let halfPos = fpc.surfaceLocation(for: .half).y
        let tipPos = fpc.surfaceLocation(for: .tip).y
        // From .half
        fpc.move(to: .half, animated: false)
        assertTargetState(fpc.floatingPanel, with: [
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

    func test_targetState_3positionsFromHalf_bottomEdge() {
        let delegate = FloatingPanelTestDelegate()
        let fpc = FloatingPanelController(delegate: delegate)
        fpc.layout = FloatingPanelLayout3PositionsBottomEdge()

            fpc.showForTest()

            let fullPos = fpc.surfaceLocation(for: .full).y
            let halfPos = fpc.surfaceLocation(for: .half).y
            let tipPos = fpc.surfaceLocation(for: .tip).y
            // From .half
            fpc.move(to: .half, animated: false)
            assertTargetState(fpc.floatingPanel, with: [
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

    func test_targetState_3positionsFromTip() {
        let delegate = FloatingPanelTestDelegate()
        let fpc = FloatingPanelController(delegate: delegate)
        fpc.layout = FloatingPanelLayout3Positions()

        fpc.showForTest()

        let fullPos = fpc.surfaceLocation(for: .full).y
        let halfPos = fpc.surfaceLocation(for: .half).y
        let tipPos = fpc.surfaceLocation(for: .tip).y

        // From .tip
        fpc.move(to: .tip, animated: false)
        assertTargetState(fpc.floatingPanel, with: [
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

    func test_targetState_3positionsFromTip_bottomEdge() {
        let delegate = FloatingPanelTestDelegate()
        let fpc = FloatingPanelController(delegate: delegate)
        fpc.layout = FloatingPanelLayout3PositionsBottomEdge()

        fpc.showForTest()

            let fullPos = fpc.surfaceLocation(for: .full).y
            let halfPos = fpc.surfaceLocation(for: .half).y
            let tipPos = fpc.surfaceLocation(for: .tip).y

            // From .tip
            fpc.move(to: .tip, animated: false)
            assertTargetState(fpc.floatingPanel, with: [
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

    func test_targetState_3positionsAllProjection() {
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
        assertTargetState(fpc.floatingPanel, with: [
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
        assertTargetState(fpc.floatingPanel, with: [
            (#line, fullPos, CGPoint(x: 0.0, y: 1000.0), .tip),
            (#line, fullPos, CGPoint(x: 0.0, y: 3000.0), .tip),
            (#line, tipPos, CGPoint(x: 0.0, y: -3000.0), .full),
            (#line, tipPos, CGPoint(x: 0.0, y: -1000.0), .full),
            ])

        // From .tip
        fpc.move(to: .tip, animated: false)
        assertTargetState(fpc.floatingPanel, with: [
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

    func test_targetState_3positionsWithHidden() {
        class FloatingPanelLayout3PositionsWithHidden: FloatingPanelLayout {
            let initialState: FloatingPanelState = .hidden
            let position: FloatingPanelPosition = .bottom
            let anchors: [FloatingPanelState : FloatingPanelLayoutAnchoring] = [
                .full: FloatingPanelLayoutAnchor(absoluteInset: 20.0, edge: .top, referenceGuide: .superview),
                .half: FloatingPanelLayoutAnchor(absoluteInset: 250.0, edge: .bottom, referenceGuide: .superview),
                .hidden: FloatingPanelLayoutAnchor(absoluteInset: 0, edge: .bottom, referenceGuide: .superview),
            ]
        }
        let delegate = FloatingPanelTestDelegate()
        let fpc = FloatingPanelController(delegate: delegate)
        fpc.layout = FloatingPanelLayout3PositionsWithHidden()

        fpc.showForTest()
        XCTAssertEqual(fpc.state, .hidden)

        fpc.move(to: .full, animated: false)
        assertTargetState(fpc.floatingPanel, with: [
            (#line, fpc.surfaceView.frame.minY, CGPoint(x: 0.0, y: 1000.0), .half),
            ])
        fpc.move(to: .half, animated: false)
        assertTargetState(fpc.floatingPanel, with: [
            (#line, fpc.surfaceView.frame.minY, CGPoint(x: 0.0, y: -100.0), .half),
            (#line, fpc.surfaceView.frame.minY, CGPoint(x: 0.0, y: -1000.0), .full),
            (#line, fpc.surfaceView.frame.minY, CGPoint(x: 0.0, y: 0.0), .half),
            (#line, fpc.surfaceView.frame.minY, CGPoint(x: 0.0, y: 1000.0), .hidden),
            ])
    }

    func test_targetState_3positionsWithHiddenWithoutFull() {
        class FloatingPanelLayout3Positions: FloatingPanelLayout {
            let initialState: FloatingPanelState = .hidden
            let position: FloatingPanelPosition = .bottom
            let anchors: [FloatingPanelState : FloatingPanelLayoutAnchoring] = [
                .half: FloatingPanelLayoutAnchor(absoluteInset: 250.0, edge: .bottom, referenceGuide: .superview),
                .tip: FloatingPanelLayoutAnchor(absoluteInset: 60.0, edge: .bottom, referenceGuide: .superview),
                .hidden: FloatingPanelLayoutAnchor(absoluteInset: 0, edge: .bottom, referenceGuide: .superview),
            ]
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
        assertTargetState(fpc.floatingPanel, with: [
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
        assertTargetState(fpc.floatingPanel, with: [
            (#line, tipPos, CGPoint(x: 0.0, y: -100.0), .tip),
            (#line, tipPos, CGPoint(x: 0.0, y: -1000.0), .half),
            (#line, tipPos, CGPoint(x: 0.0, y: 0.0), .tip),
            (#line, tipPos, CGPoint(x: 0.0, y: 1000.0), .hidden),
            ])
    }

    func test_keep_pan_gesture_disabled() {
        let fpc = FloatingPanelController()
        fpc.panGestureRecognizer.isEnabled = false
        fpc.showForTest()
        XCTAssertFalse(fpc.panGestureRecognizer.isEnabled)
    }

    func test_is_scrollable() {
        class Delegate: FloatingPanelControllerDelegate {
            var shouldScroll = false
            func floatingPanel(
                _ fpc: FloatingPanelController,
                shouldAllowToScroll scrollView: UIScrollView,
                in state: FloatingPanelState
            ) -> Bool {
                return shouldScroll
            }
        }

        let fpc = FloatingPanelController()
        let scrollView = UIScrollView()
        let delegate = Delegate()
        fpc.layout = FloatingPanelBottomLayout()
        fpc.track(scrollView: scrollView)
        fpc.showForTest()

        XCTAssertTrue(fpc.floatingPanel.isScrollable(state: .full))
        XCTAssertFalse(fpc.floatingPanel.isScrollable(state: .half))

        fpc.delegate = delegate

        XCTAssertFalse(fpc.floatingPanel.isScrollable(state: .full))
        XCTAssertFalse(fpc.floatingPanel.isScrollable(state: .half))

        delegate.shouldScroll = true

        XCTAssertTrue(fpc.floatingPanel.isScrollable(state: .full))
        XCTAssertTrue(fpc.floatingPanel.isScrollable(state: .half))
    }

    func test_adjustScrollContentInsetIfNeeded() {
        class CustomScrollView: UIScrollView {
            var customSafeAreaInsets: UIEdgeInsets = .zero
            override var safeAreaInsets: UIEdgeInsets {
                customSafeAreaInsets
            }
        }
        class PanelDelegate: FloatingPanelControllerDelegate {
            func floatingPanel(_ fpc: FloatingPanelController, shouldAllowToScroll scrollView: UIScrollView, in state: FloatingPanelState) -> Bool {
                return state == .full || state == .half
            }
        }
        let delegate = PanelDelegate()

        do {
            let scrollView = CustomScrollView()
            scrollView.customSafeAreaInsets = UIEdgeInsets(top: 0, left: 0, bottom: 34, right: 0)
            let fpc = FloatingPanelController()
            fpc.delegate = delegate
            fpc.track(scrollView: scrollView)
            fpc.layout = FloatingPanelBottomLayout()
            fpc.contentInsetAdjustmentBehavior = .always
            fpc.contentMode = .static
            fpc.showForTest()

            fpc.move(to: .half, animated: false)
            fpc.floatingPanel.adjustScrollContentInsetIfNeeded()

            let expect = 34 + (fpc.surfaceLocation(for: .half).y - fpc.surfaceLocation(for: .full).y)
            XCTAssertEqual(
                scrollView.contentInset,
                UIEdgeInsets(top: 0, left: 0, bottom: expect, right: 0)
            )

            fpc.contentMode = .fitToBounds
            XCTAssertEqual(
                scrollView.contentInset,
                scrollView.customSafeAreaInsets
            )
        }

        do {
            let scrollView = CustomScrollView()
            scrollView.customSafeAreaInsets = UIEdgeInsets(top: 91, left: 0, bottom: 0, right: 0)
            let fpc = FloatingPanelController()
            fpc.delegate = delegate
            fpc.track(scrollView: scrollView)
            fpc.layout = FloatingPanelTopPositionedLayout()
            fpc.contentInsetAdjustmentBehavior = .always
            fpc.contentMode = .static
            fpc.showForTest()

            fpc.move(to: .half, animated: false)
            fpc.floatingPanel.adjustScrollContentInsetIfNeeded()

            let expect = 91 + (fpc.surfaceLocation(for: .full).y -  fpc.surfaceLocation(for: .half).y)
            XCTAssertEqual(
                scrollView.contentInset,
                UIEdgeInsets(top: expect, left: 0, bottom: 0, right: 0)
            )
            fpc.contentMode = .fitToBounds
            XCTAssertEqual(
                scrollView.contentInset,
                scrollView.customSafeAreaInsets
            )
        }
    }

    func test_adjustScrollContentInsetIfNeeded_normal() {
        class CustomScrollView: UIScrollView {
            var customSafeAreaInsets: UIEdgeInsets = .zero
            override var safeAreaInsets: UIEdgeInsets {
                customSafeAreaInsets
            }
        }
        do {
            let scrollView = CustomScrollView()
            scrollView.customSafeAreaInsets = UIEdgeInsets(top: 42, left: 0, bottom: 34, right: 0)
            let fpc = FloatingPanelController()
            fpc.track(scrollView: scrollView)
            fpc.layout = FloatingPanelBottomLayout()
            fpc.contentInsetAdjustmentBehavior = .always
            fpc.contentMode = .static
            fpc.showForTest()

            fpc.move(to: .half, animated: false)
            fpc.floatingPanel.adjustScrollContentInsetIfNeeded()

            XCTAssertEqual(
                scrollView.contentInset,
                UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            )

            fpc.move(to: .full, animated: false)
            fpc.floatingPanel.adjustScrollContentInsetIfNeeded()
            XCTAssertEqual(
                scrollView.contentInset,
                UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            )
        }
    }

    func test_initial_scroll_offset_reset() {
        let fpc = FloatingPanelController()
        let scrollView = UIScrollView()
        fpc.layout = FloatingPanelBottomLayout()
        fpc.track(scrollView: scrollView)
        fpc.showForTest()

        fpc.move(to: .full, animated: false)

        fpc.panGestureRecognizer.state = .began
        fpc.floatingPanel.handle(panGesture: fpc.panGestureRecognizer)

        fpc.panGestureRecognizer.state = .cancelled
        fpc.floatingPanel.handle(panGesture: fpc.panGestureRecognizer)

        waitRunLoop(secs: 1.0)

        let expect = CGPoint(x: 0, y: 100)

        scrollView.setContentOffset(expect, animated: false)

        fpc.move(to: .half, animated: true)

        waitRunLoop(secs: 1.0)

        XCTAssertEqual(expect, scrollView.contentOffset)
    }

    func test_handleGesture_endWithoutAttraction() throws {
        class Delegate: FloatingPanelControllerDelegate {
            var willAttract: Bool?
            func floatingPanelDidEndDragging(_ fpc: FloatingPanelController, willAttract attract: Bool) {
                willAttract = attract
            }
        }
        let fpc = FloatingPanelController()
        let delegate = Delegate()
        fpc.showForTest()
        fpc.delegate = delegate
        XCTAssertEqual(fpc.state, .half)

        fpc.floatingPanel.endWithoutAttraction(.full)

        XCTAssertEqual(fpc.state, .full)
        XCTAssertEqual(fpc.surfaceLocation(for: .full).y, fpc.surfaceLocation.y)
        XCTAssertEqual(delegate.willAttract, false)
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
private func assertTargetState(_ floatingPanel: Core, with params: [TestParameter]) {
    params.forEach { (line, pos, velocity, result) in
        floatingPanel.surfaceView.frame.origin.y = pos
        XCTAssertEqual(floatingPanel.targetState(from: pos, with: velocity.y), result, line: line)
    }
}
