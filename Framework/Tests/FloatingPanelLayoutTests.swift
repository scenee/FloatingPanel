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
        XCTAssertEqual(fpc.floatingPanel.layoutAdapter.edgeMostState, .full)
        XCTAssertEqual(fpc.floatingPanel.layoutAdapter.edgeLeastState, .tip)

        class FloatingPanelLayoutWithHidden: FloatingPanelLayout {
            var stateAnchors: [FloatingPanelState: FloatingPanelLayoutAnchoring]  {
                return [
                    .full: FloatingPanelLayoutAnchor(absoluteInset: 18.0, edge: .top, referenceGuide: .safeArea),
                    .half: FloatingPanelLayoutAnchor(fractionalInset: 0.5, edge: .bottom, referenceGuide: .safeArea),
                    .hidden: FloatingPanelLayoutAnchor(absoluteInset: 0, edge: .bottom, referenceGuide: .superview)
                ]
            }
            let initialState: FloatingPanelState = .hidden
            let anchorPosition: FloatingPanelPosition = .bottom
        }
        class FloatingPanelLayout2Positions: FloatingPanelLayout {
            var stateAnchors: [FloatingPanelState: FloatingPanelLayoutAnchoring]  {
                return [
                    .half: FloatingPanelLayoutAnchor(fractionalInset: 0.5, edge: .bottom, referenceGuide: .safeArea),
                    .tip: FloatingPanelLayoutAnchor(absoluteInset: 69.0, edge: .bottom, referenceGuide: .safeArea),
                ]
            }
            let initialState: FloatingPanelState = .tip
            let anchorPosition: FloatingPanelPosition = .bottom
        }
        fpc.layout = FloatingPanelLayoutWithHidden()
        XCTAssertEqual(fpc.floatingPanel.layoutAdapter.edgeMostState, .full)
        XCTAssertEqual(fpc.floatingPanel.layoutAdapter.edgeLeastState, .hidden)

        fpc.layout = FloatingPanelLayout2Positions()
        XCTAssertEqual(fpc.floatingPanel.layoutAdapter.edgeMostState, .half)
        XCTAssertEqual(fpc.floatingPanel.layoutAdapter.edgeLeastState, .tip)
    }

    func test_layoutSegment_3position() {
        class FloatingPanelLayout3Positions: FloatingPanelTestLayout {
            override var initialState: FloatingPanelState  { .half }
        }

        fpc.layout = FloatingPanelLayout3Positions()

        let fullPos = fpc.surfaceLocation(for: .full).y
        let halfPos = fpc.surfaceLocation(for: .half).y
        let tipPos = fpc.surfaceLocation(for: .tip).y

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
            override var initialState: FloatingPanelState  { .half }
            override var stateAnchors: [FloatingPanelState : FloatingPanelLayoutAnchoring]
                { super.stateAnchors.filter { (key, _) in key != .tip } }
        }

        fpc.layout = FloatingPanelLayout2Positions()

        let fullPos = fpc.surfaceLocation(for: .full).y
        let halfPos = fpc.surfaceLocation(for: .half).y

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
            override var initialState: FloatingPanelState  { .full }
            override var stateAnchors: [FloatingPanelState : FloatingPanelLayoutAnchoring]
                { super.stateAnchors.filter { (key, _) in key == .full } }
        }

        fpc.layout = FloatingPanelLayout1Positions()

        let fullPos = fpc.surfaceLocation(for: .full).y

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

    func test_updateInteractiveEdgeConstraint() {
        fpc.showForTest()
        fpc.move(to: .full, animated: false)

        fpc.floatingPanel.layoutAdapter.startInteraction(at: fpc.state)
        fpc.floatingPanel.layoutAdapter.startInteraction(at: fpc.state) // Should be ignore

        let fullPos = fpc.surfaceLocation(for: .full).y
        let tipPos = fpc.surfaceLocation(for: .tip).y

        var next: CGFloat

        fpc.floatingPanel.layoutAdapter.updateInteractiveEdgeConstraint(diff: -100.0,
                                                                        overflow: false,
                                                                        allowsRubberBanding: fpc.floatingPanel.behaviorAdapter.allowsRubberBanding(for:))
        next = fpc.surfaceLocation.y
        XCTAssertEqual(next, fullPos)

        fpc.floatingPanel.layoutAdapter.updateInteractiveEdgeConstraint(diff: 100.0,
                                                                        overflow: true,
                                                                        allowsRubberBanding: fpc.floatingPanel.behaviorAdapter.allowsRubberBanding(for:))
        next = fpc.surfaceLocation.y
        XCTAssertEqual(next, fullPos + 100.0)

        fpc.floatingPanel.layoutAdapter.updateInteractiveEdgeConstraint(diff: tipPos - fullPos,
                                                                        overflow: true,
                                                                        allowsRubberBanding: fpc.floatingPanel.behaviorAdapter.allowsRubberBanding(for:))
        next = fpc.surfaceLocation.y
        XCTAssertEqual(next, tipPos)

        fpc.floatingPanel.layoutAdapter.updateInteractiveEdgeConstraint(diff: tipPos - fullPos + 100.0,
                                                                        overflow: false,
                                                                        allowsRubberBanding: fpc.floatingPanel.behaviorAdapter.allowsRubberBanding(for:))
        next = fpc.surfaceLocation.y
        XCTAssertEqual(next, tipPos)

        fpc.floatingPanel.layoutAdapter.updateInteractiveEdgeConstraint(diff: tipPos - fullPos + 100.0,
                                                                        overflow: true,
                                                                        allowsRubberBanding: fpc.floatingPanel.behaviorAdapter.allowsRubberBanding(for:))
        next = fpc.surfaceLocation.y
        XCTAssertEqual(next, tipPos + 100.0)

        fpc.floatingPanel.layoutAdapter.endInteraction(at: fpc.state)
    }

    func test_updateInteractiveEdgeConstraint_bottomEdge() {
        fpc.layout = FloatingPanelTop2BottomTestLayout()
        fpc.showForTest()
        fpc.move(to: .tip, animated: false)
        XCTAssertEqual(fpc.surfaceView.frame, CGRect(x: 0.0, y: -667.0 + 60.0, width: 375.0, height: 667))
        XCTAssertEqual(fpc.surfaceView.containerView.frame, CGRect(x: 0.0, y: -667.0,
                                                                   width: 375.0, height: 667 * 2.0))

        fpc.floatingPanel.layoutAdapter.startInteraction(at: fpc.state)
        fpc.floatingPanel.layoutAdapter.startInteraction(at: fpc.state) // Should be ignore

        XCTAssertEqual(fpc.floatingPanel.layoutAdapter.interactionEdgeConstraint?.constant, 60.0)

        let fullPos = fpc.surfaceLocation(for: .full).y
        let tipPos = fpc.surfaceLocation(for: .tip).y

        var pre: CGFloat
        var next: CGFloat
        pre = fpc.surfaceLocation.y
        fpc.floatingPanel.layoutAdapter.updateInteractiveEdgeConstraint(diff: -100.0,
                                                                        overflow: false,
                                                                        allowsRubberBanding: fpc.floatingPanel.behaviorAdapter.allowsRubberBanding(for:))
        next = fpc.surfaceLocation.y
        XCTAssertEqual(next, pre)

        fpc.floatingPanel.layoutAdapter.updateInteractiveEdgeConstraint(diff: 100.0,
                                                                        overflow: true,
                                                                        allowsRubberBanding: fpc.floatingPanel.behaviorAdapter.allowsRubberBanding(for:))
        next = fpc.surfaceLocation.y
        XCTAssertEqual(next, tipPos + 100.0)

        fpc.floatingPanel.layoutAdapter.updateInteractiveEdgeConstraint(diff: fullPos - tipPos,
                                                                        overflow: true,
                                                                        allowsRubberBanding: fpc.floatingPanel.behaviorAdapter.allowsRubberBanding(for:))
        next = fpc.surfaceLocation.y
        XCTAssertEqual(next, fullPos)

        fpc.floatingPanel.layoutAdapter.updateInteractiveEdgeConstraint(diff: fullPos - tipPos + 100,
                                                                        overflow: false,
                                                                        allowsRubberBanding: fpc.floatingPanel.behaviorAdapter.allowsRubberBanding(for:))
        next = fpc.surfaceLocation.y
        XCTAssertEqual(next, fullPos)

        fpc.floatingPanel.layoutAdapter.updateInteractiveEdgeConstraint(diff: fullPos - tipPos + 100,
                                                                        overflow: true,
                                                                        allowsRubberBanding: fpc.floatingPanel.behaviorAdapter.allowsRubberBanding(for:))
        next = fpc.surfaceLocation.y
        XCTAssertEqual(next, fullPos + 100.0)

        fpc.floatingPanel.layoutAdapter.endInteraction(at: fpc.state)
    }

    func test_updateInteractiveEdgeConstraintWithHidden() {
        class FloatingPanelLayout2Positions: FloatingPanelLayout {
            var stateAnchors: [FloatingPanelState: FloatingPanelLayoutAnchoring]  {
                return [
                    .full: FloatingPanelLayoutAnchor(absoluteInset: 18.0, edge: .bottom, referenceGuide: .safeArea),
                    .hidden: FloatingPanelLayoutAnchor(absoluteInset: 0, edge: .bottom, referenceGuide: .superview),
                ]
            }
            let initialState: FloatingPanelState = .hidden
            let anchorPosition: FloatingPanelPosition = .bottom
        }
        fpc.layout = FloatingPanelLayout2Positions()
        fpc.showForTest()
        fpc.move(to: .full, animated: false)

        fpc.floatingPanel.layoutAdapter.startInteraction(at: fpc.state)

        let fullPos = fpc.surfaceLocation(for: .full).y
        let hiddenPos = fpc.surfaceLocation(for: .hidden).y

        var next: CGFloat

        fpc.floatingPanel.layoutAdapter.updateInteractiveEdgeConstraint(diff: -100.0,
                                                                        overflow: false,
                                                                        allowsRubberBanding: fpc.floatingPanel.behaviorAdapter.allowsRubberBanding(for:))
        next = fpc.surfaceLocation.y
        XCTAssertEqual(next, fullPos)

        fpc.floatingPanel.layoutAdapter.updateInteractiveEdgeConstraint(diff: -100.0,
                                                                        overflow: true,
                                                                        allowsRubberBanding: fpc.floatingPanel.behaviorAdapter.allowsRubberBanding(for:))
        next = fpc.surfaceLocation.y
        XCTAssertEqual(next, fullPos - 100.0)

        fpc.floatingPanel.layoutAdapter.updateInteractiveEdgeConstraint(diff: hiddenPos - fullPos + 100.0,
                                                                        overflow: true,
                                                                        allowsRubberBanding: fpc.floatingPanel.behaviorAdapter.allowsRubberBanding(for:))
        next = fpc.surfaceLocation.y
        XCTAssertEqual(next, hiddenPos + 100.0)

        fpc.floatingPanel.layoutAdapter.endInteraction(at: fpc.state)
    }

    func test_updateInteractiveEdgeConstraintWithHidden_bottomEdge() {
        class FloatingPanelLayout2Positions: FloatingPanelLayout {
            var stateAnchors: [FloatingPanelState: FloatingPanelLayoutAnchoring]  {
                [
                    .full: FloatingPanelLayoutAnchor(absoluteInset: 18.0, edge: .bottom, referenceGuide: .safeArea),
                    .hidden: FloatingPanelLayoutAnchor(absoluteInset: 0, edge: .top, referenceGuide: .superview),
                ]
            }
            let initialState: FloatingPanelState = .hidden
            let anchorPosition: FloatingPanelPosition = .top
        }
        fpc.layout = FloatingPanelLayout2Positions()
        fpc.showForTest()
        fpc.move(to: .full, animated: false)

        fpc.floatingPanel.layoutAdapter.startInteraction(at: fpc.state)

        let fullPos = fpc.surfaceLocation(for: .full).y
        let hiddenPos = fpc.surfaceLocation(for: .hidden).y

        var next: CGFloat

        fpc.floatingPanel.layoutAdapter.updateInteractiveEdgeConstraint(diff: 100.0,
                                                                        overflow: false,
                                                                        allowsRubberBanding: fpc.floatingPanel.behaviorAdapter.allowsRubberBanding(for:))
        next = fpc.surfaceLocation.y
        XCTAssertEqual(next, fullPos)

        fpc.floatingPanel.layoutAdapter.updateInteractiveEdgeConstraint(diff: 100.0,
                                                                        overflow: true,
                                                                        allowsRubberBanding: fpc.floatingPanel.behaviorAdapter.allowsRubberBanding(for:))
        next = fpc.surfaceLocation.y
        XCTAssertEqual(next, fullPos + 100.0)

        fpc.floatingPanel.layoutAdapter.updateInteractiveEdgeConstraint(diff: hiddenPos - fullPos + 100.0,
                                                                        overflow: true,
                                                                        allowsRubberBanding: fpc.floatingPanel.behaviorAdapter.allowsRubberBanding(for:))
        next = fpc.surfaceLocation.y
        XCTAssertEqual(next, hiddenPos + 100.0)

        fpc.floatingPanel.layoutAdapter.endInteraction(at: fpc.state)
    }

    func test_updateInteractiveTopConstraintWithMinusInsets() {
        class FloatingPanelLayoutMinusInsets: FloatingPanelLayout {
            var stateAnchors: [FloatingPanelState: FloatingPanelLayoutAnchoring]  {
                [
                    .full: FloatingPanelLayoutAnchor(absoluteInset: -200, edge: .top, referenceGuide: .safeArea),
                    .tip: FloatingPanelLayoutAnchor(absoluteInset: -200, edge: .bottom, referenceGuide: .safeArea),
                ]
            }
            let initialState: FloatingPanelState = .full
            let anchorPosition: FloatingPanelPosition = .bottom
        }
        fpc.layout = FloatingPanelLayoutMinusInsets()
        fpc.showForTest()
        fpc.floatingPanel.layoutAdapter.startInteraction(at: fpc.state)

        let fullPos = fpc.surfaceLocation(for: .full).y
        let tipPos = fpc.surfaceLocation(for: .tip).y

        var next: CGFloat
        fpc.floatingPanel.layoutAdapter.updateInteractiveEdgeConstraint(diff: -100.0,
                                                                        overflow: false,
                                                                        allowsRubberBanding: fpc.floatingPanel.behaviorAdapter.allowsRubberBanding(for:))
        next = fpc.surfaceLocation.y
        XCTAssertEqual(next, fullPos)

        fpc.floatingPanel.layoutAdapter.updateInteractiveEdgeConstraint(diff: -100.0,
                                                                        overflow: true,
                                                                        allowsRubberBanding: fpc.floatingPanel.behaviorAdapter.allowsRubberBanding(for:))
        next = fpc.surfaceLocation.y
        XCTAssertEqual(next, fullPos - 100)

        fpc.floatingPanel.layoutAdapter.updateInteractiveEdgeConstraint(diff: tipPos - fullPos + 100.0,
                                                                        overflow: true,
                                                                        allowsRubberBanding: fpc.floatingPanel.behaviorAdapter.allowsRubberBanding(for:))
        next = fpc.surfaceLocation.y
        XCTAssertEqual(next, tipPos + 100)

        fpc.floatingPanel.layoutAdapter.endInteraction(at: fpc.state)
    }

    func test_surfaceLocation() {
        fpc = CustomSafeAreaFloatingPanelController()
        fpc.loadViewIfNeeded()
        fpc.view.frame = CGRect(x: 0, y: 0, width: 375, height: 667)

        class MyFloatingPanelFullLayout: FloatingPanelTestLayout {}
        class MyFloatingPanelSafeAreaLayout: FloatingPanelTestLayout {
            override var referenceGuide: FloatingPanelLayoutReferenceGuide {
                return .safeArea
            }
        }

        let myLayout = MyFloatingPanelFullLayout()
        fpc.layout = myLayout
        fpc.showForTest()

        let bounds = fpc.view!.bounds
        XCTAssertEqual(fpc.layout.stateAnchors.filter({ $0.value.referenceGuide != .superview }).count, 0)
        XCTAssertEqual(fpc.surfaceLocation(for: .full).y, myLayout.fullInset)
        XCTAssertEqual(fpc.surfaceLocation(for: .half).y, bounds.height - myLayout.halfInset)
        XCTAssertEqual(fpc.surfaceLocation(for: .tip).y, bounds.height - myLayout.tipInset)
        XCTAssertEqual(fpc.surfaceLocation(for: .hidden).y, bounds.height + 100.0)

        fpc.layout = MyFloatingPanelSafeAreaLayout()

        XCTAssertEqual(fpc.layout.stateAnchors.filter({ $0.value.referenceGuide != .safeArea }).count, 0)
        XCTAssertEqual(fpc.surfaceLocation(for: .full).y, myLayout.fullInset + fpc.fp_safeAreaInsets.top)
        XCTAssertEqual(fpc.surfaceLocation(for: .half).y, bounds.height - myLayout.halfInset + fpc.fp_safeAreaInsets.bottom)
        XCTAssertEqual(fpc.surfaceLocation(for: .tip).y, bounds.height - myLayout.tipInset +  fpc.fp_safeAreaInsets.bottom)
        XCTAssertEqual(fpc.surfaceLocation(for: .hidden).y, bounds.height + 100.0)
    }

    func test_surfaceLocation_bottomEdge() {
        fpc = CustomSafeAreaFloatingPanelController()
        fpc.loadViewIfNeeded()
        fpc.view.frame = CGRect(x: 0, y: 0, width: 375, height: 667)

        class MyFloatingPanelFullLayout: FloatingPanelTop2BottomTestLayout { }
        class MyFloatingPanelSafeAreaLayout: FloatingPanelTop2BottomTestLayout {
            override var referenceGuide: FloatingPanelLayoutReferenceGuide {
                return .safeArea
            }
        }
        let myLayout = MyFloatingPanelFullLayout()
        fpc.layout = myLayout
        fpc.showForTest()

        let bounds = fpc.view!.bounds
        XCTAssertEqual(fpc.layout.stateAnchors.filter({ $0.value.referenceGuide != .superview }).count, 0)
        XCTAssertEqual(fpc.surfaceLocation(for: .full).y, bounds.height - myLayout.fullInset)
        XCTAssertEqual(fpc.surfaceLocation(for: .half).y, myLayout.halfInset)
        XCTAssertEqual(fpc.surfaceLocation(for: .tip).y,  myLayout.tipInset)
        XCTAssertEqual(fpc.surfaceLocation(for: .hidden).y, -100.0)


        fpc.layout = MyFloatingPanelSafeAreaLayout()

        XCTAssertEqual(fpc.layout.stateAnchors.filter({ $0.value.referenceGuide != .safeArea }).count, 0)
        XCTAssertEqual(fpc.surfaceLocation(for: .full).y, bounds.height - myLayout.fullInset + fpc.fp_safeAreaInsets.bottom)
        XCTAssertEqual(fpc.surfaceLocation(for: .half).y, myLayout.halfInset + fpc.fp_safeAreaInsets.top)
        XCTAssertEqual(fpc.surfaceLocation(for: .tip).y, myLayout.tipInset + fpc.fp_safeAreaInsets.top)
        XCTAssertEqual(fpc.surfaceLocation(for: .hidden).y, -100.0)
    }

    func test_layoutAnchor_topPosition() {
        let position: FloatingPanelPosition = .top
        fpc = CustomSafeAreaFloatingPanelController()
        fpc.loadViewIfNeeded()
        fpc.view.frame = CGRect(x: 0, y: 0, width: 375, height: 667)

        for prop in [
            // from top edge
            (anchor: FloatingPanelLayoutAnchor(absoluteInset: 0.0, edge: .top, referenceGuide: .safeArea),
             result: (#line, constant: 0.0, firstAnchor: fpc.surfaceView.bottomAnchor, secondAnchor: fpc.fp_safeAreaLayoutGuide.topAnchor)),
            (anchor: FloatingPanelLayoutAnchor(absoluteInset: 100.0, edge: .top, referenceGuide: .safeArea),
             result: (#line, constant: 100.0, firstAnchor: fpc.surfaceView.bottomAnchor, secondAnchor: fpc.fp_safeAreaLayoutGuide.topAnchor)),
            (anchor: FloatingPanelLayoutAnchor(absoluteInset: 0.0, edge: .top, referenceGuide: .superview),
             result: (#line, constant: 0.0, firstAnchor: fpc.surfaceView.bottomAnchor, secondAnchor: fpc.view.topAnchor)),
            (anchor: FloatingPanelLayoutAnchor(absoluteInset: 100.0, edge: .top, referenceGuide: .superview),
             result: (#line, constant: 100.0, firstAnchor: fpc.surfaceView.bottomAnchor, secondAnchor: fpc.view.topAnchor)),
            // from bottom edge
            (anchor: FloatingPanelLayoutAnchor(absoluteInset: 0.0, edge: .bottom, referenceGuide: .safeArea),
             result: (#line, constant: 0.0, firstAnchor: fpc.fp_safeAreaLayoutGuide.bottomAnchor, secondAnchor: fpc.surfaceView.bottomAnchor)),
            (anchor: FloatingPanelLayoutAnchor(absoluteInset: 100.0, edge: .bottom, referenceGuide: .safeArea),
             result: (#line, constant: 100.0, firstAnchor: fpc.fp_safeAreaLayoutGuide.bottomAnchor, secondAnchor: fpc.surfaceView.bottomAnchor)),
            (anchor: FloatingPanelLayoutAnchor(absoluteInset: 0.0, edge: .bottom, referenceGuide: .superview),
             result: (#line, constant: 0.0, firstAnchor: fpc.view.bottomAnchor, secondAnchor: fpc.surfaceView.bottomAnchor)),
            (anchor: FloatingPanelLayoutAnchor(absoluteInset: 100.0, edge: .bottom, referenceGuide: .superview),
             result: (#line, constant: 100.0, firstAnchor: fpc.view.bottomAnchor, secondAnchor: fpc.surfaceView.bottomAnchor)),
            ] {
                let c = prop.anchor.layoutConstraints(fpc, for: position)[0]
                XCTAssertEqual(c.constant, CGFloat(prop.result.constant), line: UInt(prop.result.0))
                XCTAssertEqual(c.firstAnchor, prop.result.firstAnchor, line: UInt(prop.result.0))
                XCTAssertEqual(c.secondAnchor, prop.result.secondAnchor, line: UInt(prop.result.0))
        }

        // fractional
        for prop in [
            // from top edge
            (anchor: FloatingPanelLayoutAnchor(fractionalInset: 0.0, edge: .top, referenceGuide: .safeArea),
             result: (#line, multiplier: 1.0, secondAnchor: nil)),
            (anchor: FloatingPanelLayoutAnchor(fractionalInset: 0.5, edge: .top, referenceGuide: .safeArea),
             result: (#line, multiplier: 0.5, secondAnchor: fpc.fp_safeAreaLayoutGuide.heightAnchor)),
            (anchor: FloatingPanelLayoutAnchor(fractionalInset: 0.0, edge: .top, referenceGuide: .superview),
             result: (#line, multiplier: 1.0, secondAnchor: nil)),
            (anchor: FloatingPanelLayoutAnchor(fractionalInset: 0.5, edge: .top, referenceGuide: .superview),
             result: (#line, multiplier: 0.5, secondAnchor: fpc.view.heightAnchor)),

            // from bottom edge
            (anchor: FloatingPanelLayoutAnchor(fractionalInset: 0.0, edge: .bottom, referenceGuide: .safeArea),
             result: (#line, multiplier: 1.0, secondAnchor: nil)),
            (anchor: FloatingPanelLayoutAnchor(fractionalInset: 0.5, edge: .bottom, referenceGuide: .safeArea),
             result: (#line, multiplier: 0.5, secondAnchor: fpc.fp_safeAreaLayoutGuide.heightAnchor)),
            (anchor: FloatingPanelLayoutAnchor(fractionalInset: 0.0, edge: .bottom, referenceGuide: .superview),
             result: (#line, multiplier: 1.0, secondAnchor: nil)),
            (anchor: FloatingPanelLayoutAnchor(fractionalInset: 0.5, edge: .bottom, referenceGuide: .superview),
             result: (#line, multiplier: 0.5, secondAnchor: fpc.view.heightAnchor)),
            ] {
                let c = prop.anchor.layoutConstraints(fpc, for: position)[0]
                XCTAssertEqual(c.multiplier, CGFloat(prop.result.multiplier), line: UInt(prop.result.0))
                XCTAssertTrue(c.firstAnchor is NSLayoutAnchor<NSLayoutDimension>, line: UInt(prop.result.0))
                XCTAssertEqual(c.secondAnchor, prop.result.secondAnchor, line: UInt(prop.result.0))
                print(c)
        }
    }
    func test_layoutAnchor_bottomPosition() {
        let position: FloatingPanelPosition = .bottom

        fpc = CustomSafeAreaFloatingPanelController()
        fpc.loadViewIfNeeded()
        fpc.view.frame = CGRect(x: 0, y: 0, width: 375, height: 667)

        for prop in [
            // from top edge
            (anchor: FloatingPanelLayoutAnchor(absoluteInset: 0.0, edge: .top, referenceGuide: .safeArea),
             result: (#line, constant: 0.0, firstAnchor: fpc.surfaceView.topAnchor, secondAnchor: fpc.fp_safeAreaLayoutGuide.topAnchor)),
            (anchor: FloatingPanelLayoutAnchor(absoluteInset: 100.0, edge: .top, referenceGuide: .safeArea),
             result: (#line, constant: 100.0, firstAnchor: fpc.surfaceView.topAnchor, secondAnchor: fpc.fp_safeAreaLayoutGuide.topAnchor)),
            (anchor: FloatingPanelLayoutAnchor(absoluteInset: 0.0, edge: .top, referenceGuide: .superview),
             result: (#line, constant: 0.0, firstAnchor: fpc.surfaceView.topAnchor, secondAnchor: fpc.view.topAnchor)),
            (anchor: FloatingPanelLayoutAnchor(absoluteInset: 100.0, edge: .top, referenceGuide: .superview),
             result: (#line, constant: 100.0, firstAnchor: fpc.surfaceView.topAnchor, secondAnchor: fpc.view.topAnchor)),

            // from bottom edge
            (anchor: FloatingPanelLayoutAnchor(absoluteInset: 0.0, edge: .bottom, referenceGuide: .safeArea),
             result: (#line, constant: 0.0, firstAnchor: fpc.fp_safeAreaLayoutGuide.bottomAnchor, secondAnchor: fpc.surfaceView.topAnchor)),
            (anchor: FloatingPanelLayoutAnchor(absoluteInset: 100.0, edge: .bottom, referenceGuide: .safeArea),
             result: (#line, constant: 100.0, firstAnchor: fpc.fp_safeAreaLayoutGuide.bottomAnchor, secondAnchor: fpc.surfaceView.topAnchor)),
            (anchor: FloatingPanelLayoutAnchor(absoluteInset: 0.0, edge: .bottom, referenceGuide: .superview),
             result: (#line, constant: 0.0, firstAnchor: fpc.view.bottomAnchor, secondAnchor: fpc.surfaceView.topAnchor)),
            (anchor: FloatingPanelLayoutAnchor(absoluteInset: 100.0, edge: .bottom, referenceGuide: .superview),
             result: (#line, constant: 100.0, firstAnchor: fpc.view.bottomAnchor, secondAnchor: fpc.surfaceView.topAnchor)),
            ] {
                let c = prop.anchor.layoutConstraints(fpc, for: position)[0]
                XCTAssertEqual(c.constant, CGFloat(prop.result.constant), line: UInt(prop.result.0))
                XCTAssertEqual(c.firstAnchor, prop.result.firstAnchor, line: UInt(prop.result.0))
                XCTAssertEqual(c.secondAnchor, prop.result.secondAnchor, line: UInt(prop.result.0))
        }

        // fractional
        for prop in [
            // from top edge
            (anchor: FloatingPanelLayoutAnchor(fractionalInset: 0.0, edge: .top, referenceGuide: .safeArea),
             result: (#line, multiplier: 1.0, secondAnchor: nil)),
            (anchor: FloatingPanelLayoutAnchor(fractionalInset: 0.5, edge: .top, referenceGuide: .safeArea),
             result: (#line, multiplier: 0.5, secondAnchor: fpc.fp_safeAreaLayoutGuide.heightAnchor)),
            (anchor: FloatingPanelLayoutAnchor(fractionalInset: 0.0, edge: .top, referenceGuide: .superview),
             result: (#line, multiplier: 1.0, secondAnchor: nil)),
            (anchor: FloatingPanelLayoutAnchor(fractionalInset: 0.5, edge: .top, referenceGuide: .superview),
             result: (#line, multiplier: 0.5, secondAnchor: fpc.view.heightAnchor)),

            // from bottom edge
            (anchor: FloatingPanelLayoutAnchor(fractionalInset: 0.0, edge: .bottom, referenceGuide: .safeArea),
             result: (#line, multiplier: 1.0, secondAnchor: nil)),
            (anchor: FloatingPanelLayoutAnchor(fractionalInset: 0.5, edge: .bottom, referenceGuide: .safeArea),
             result: (#line, multiplier: 0.5, secondAnchor: fpc.fp_safeAreaLayoutGuide.heightAnchor)),
            (anchor: FloatingPanelLayoutAnchor(fractionalInset: 0.0, edge: .bottom, referenceGuide: .superview),
             result: (#line, multiplier: 1.0, secondAnchor: nil)),
            (anchor: FloatingPanelLayoutAnchor(fractionalInset: 0.5, edge: .bottom, referenceGuide: .superview),
             result: (#line, multiplier: 0.5, secondAnchor: fpc.view.heightAnchor)),
            ] {
                let c = prop.anchor.layoutConstraints(fpc, for: position)[0]
                XCTAssertEqual(c.multiplier, CGFloat(prop.result.multiplier), line: UInt(prop.result.0))
                XCTAssertTrue(c.firstAnchor is NSLayoutAnchor<NSLayoutDimension>, line: UInt(prop.result.0))
                XCTAssertEqual(c.secondAnchor, prop.result.secondAnchor, line: UInt(prop.result.0))
                print(c)
        }
    }

    func test_intrinsicLayoutAnchor_topPosition() {
        class ContentViewController: UIViewController {
            class IntrinsicView: UIView {
                override var intrinsicContentSize: CGSize {
                    return CGSize(width: UIView.noIntrinsicMetric, height: 420)
                }
            }
            override func loadView() {
                self.view = IntrinsicView()
            }
        }
        let position: FloatingPanelPosition = .top

        fpc = CustomSafeAreaFloatingPanelController()
        fpc.loadViewIfNeeded()
        fpc.view.frame = CGRect(x: 0, y: 0, width: 375, height: 667)
        let contentVC = ContentViewController()
        contentVC.loadViewIfNeeded()
        fpc.set(contentViewController: contentVC)

        for prop in [
            (anchor: FloatingPanelIntrinsicLayoutAnchor(absoluteOffset: 0.0, referenceGuide: .safeArea),
             result: (#line, constant: 420, firstAnchor: fpc.surfaceView.bottomAnchor, secondAnchor: fpc.fp_safeAreaLayoutGuide.topAnchor)),
            (anchor: FloatingPanelIntrinsicLayoutAnchor(absoluteOffset: 42.0, referenceGuide: .safeArea),
             result: (#line, constant: 420 - 42, firstAnchor: fpc.surfaceView.bottomAnchor, secondAnchor: fpc.fp_safeAreaLayoutGuide.topAnchor)),
            (anchor: FloatingPanelIntrinsicLayoutAnchor(absoluteOffset: 0.0, referenceGuide: .superview),
             result: (#line, constant: 420, firstAnchor: fpc.surfaceView.bottomAnchor, secondAnchor: fpc.view.topAnchor)),
            (anchor: FloatingPanelIntrinsicLayoutAnchor(absoluteOffset: 42.0, referenceGuide: .superview),
             result: (#line, constant: 420 - 42, firstAnchor: fpc.surfaceView.bottomAnchor, secondAnchor: fpc.view.topAnchor)),

            (anchor: FloatingPanelIntrinsicLayoutAnchor(fractionalOffset: 0.0, referenceGuide: .safeArea),
             result: (#line, constant: 420, firstAnchor: fpc.surfaceView.bottomAnchor, secondAnchor: fpc.fp_safeAreaLayoutGuide.topAnchor)),
            (anchor: FloatingPanelIntrinsicLayoutAnchor(fractionalOffset: 0.5, referenceGuide: .safeArea),
             result: (#line, constant: 210, firstAnchor: fpc.surfaceView.bottomAnchor, secondAnchor: fpc.fp_safeAreaLayoutGuide.topAnchor)),
            (anchor: FloatingPanelIntrinsicLayoutAnchor(fractionalOffset: 1.0, referenceGuide: .safeArea),
             result: (#line, constant: 0, firstAnchor: fpc.surfaceView.bottomAnchor, secondAnchor: fpc.fp_safeAreaLayoutGuide.topAnchor)),
            (anchor: FloatingPanelIntrinsicLayoutAnchor(fractionalOffset: 0.0, referenceGuide: .superview),
             result: (#line, constant: 420, firstAnchor: fpc.surfaceView.bottomAnchor, secondAnchor: fpc.view.topAnchor)),
            (anchor: FloatingPanelIntrinsicLayoutAnchor(fractionalOffset: 0.5, referenceGuide: .superview),
             result: (#line, constant: 210, firstAnchor: fpc.surfaceView.bottomAnchor, secondAnchor: fpc.view.topAnchor)),
            (anchor: FloatingPanelIntrinsicLayoutAnchor(fractionalOffset: 1.0, referenceGuide: .superview),
             result: (#line, constant: 0, firstAnchor: fpc.surfaceView.bottomAnchor, secondAnchor: fpc.view.topAnchor)),
            ] {
                let c = prop.anchor.layoutConstraints(fpc, for: position)[0]
                XCTAssertEqual(c.constant, CGFloat(prop.result.constant), line: UInt(prop.result.0))
                XCTAssertEqual(c.firstAnchor, prop.result.firstAnchor, line: UInt(prop.result.0))
                XCTAssertEqual(c.secondAnchor, prop.result.secondAnchor, line: UInt(prop.result.0))
        }
    }

    func test_intrinsicLayoutAnchor_bottomPosition() {
        class ContentViewController: UIViewController {
            class IntrinsicView: UIView {
                override var intrinsicContentSize: CGSize {
                    return CGSize(width: UIView.noIntrinsicMetric, height: 420)
                }
            }
            override func loadView() {
                self.view = IntrinsicView()
            }
        }
        let position: FloatingPanelPosition = .bottom

        fpc = CustomSafeAreaFloatingPanelController()
        fpc.loadViewIfNeeded()
        fpc.view.frame = CGRect(x: 0, y: 0, width: 375, height: 667)
        let contentVC = ContentViewController()
        contentVC.loadViewIfNeeded()
        fpc.set(contentViewController: contentVC)

        for prop in [
            (anchor: FloatingPanelIntrinsicLayoutAnchor(absoluteOffset: 0.0, referenceGuide: .safeArea),
             result: (#line, constant: -420, firstAnchor: fpc.surfaceView.topAnchor, secondAnchor: fpc.fp_safeAreaLayoutGuide.bottomAnchor)),
            (anchor: FloatingPanelIntrinsicLayoutAnchor(absoluteOffset: 42.0, referenceGuide: .safeArea),
             result: (#line, constant: -420 + 42, firstAnchor: fpc.surfaceView.topAnchor, secondAnchor: fpc.fp_safeAreaLayoutGuide.bottomAnchor)),
            (anchor: FloatingPanelIntrinsicLayoutAnchor(absoluteOffset: 0.0, referenceGuide: .superview),
             result: (#line, constant: -420, firstAnchor: fpc.surfaceView.topAnchor, secondAnchor: fpc.view.bottomAnchor)),
            (anchor: FloatingPanelIntrinsicLayoutAnchor(absoluteOffset: 42.0, referenceGuide: .superview),
             result: (#line, constant: -420 + 42, firstAnchor: fpc.surfaceView.topAnchor, secondAnchor: fpc.view.bottomAnchor)),

            (anchor: FloatingPanelIntrinsicLayoutAnchor(fractionalOffset: 0.0, referenceGuide: .safeArea),
             result: (#line, constant: -420, firstAnchor: fpc.surfaceView.topAnchor, secondAnchor: fpc.fp_safeAreaLayoutGuide.bottomAnchor)),
            (anchor: FloatingPanelIntrinsicLayoutAnchor(fractionalOffset: 0.5, referenceGuide: .safeArea),
             result: (#line, constant: -210, firstAnchor: fpc.surfaceView.topAnchor, secondAnchor: fpc.fp_safeAreaLayoutGuide.bottomAnchor)),
            (anchor: FloatingPanelIntrinsicLayoutAnchor(fractionalOffset: 1.0, referenceGuide: .safeArea),
             result: (#line, constant: 0, firstAnchor: fpc.surfaceView.topAnchor, secondAnchor: fpc.fp_safeAreaLayoutGuide.bottomAnchor)),
            (anchor: FloatingPanelIntrinsicLayoutAnchor(fractionalOffset: 0.0, referenceGuide: .superview),
             result: (#line, constant: -420, firstAnchor: fpc.surfaceView.topAnchor, secondAnchor: fpc.view.bottomAnchor)),
            (anchor: FloatingPanelIntrinsicLayoutAnchor(fractionalOffset: 0.5, referenceGuide: .superview),
             result: (#line, constant: -210, firstAnchor: fpc.surfaceView.topAnchor, secondAnchor: fpc.view.bottomAnchor)),
            (anchor: FloatingPanelIntrinsicLayoutAnchor(fractionalOffset: 1.0, referenceGuide: .superview),
             result: (#line, constant: 0, firstAnchor: fpc.surfaceView.topAnchor, secondAnchor: fpc.view.bottomAnchor)),
            ] {
                let c = prop.anchor.layoutConstraints(fpc, for: position)[0]
                XCTAssertEqual(c.constant, CGFloat(prop.result.constant), line: UInt(prop.result.0))
                XCTAssertEqual(c.firstAnchor, prop.result.firstAnchor, line: UInt(prop.result.0))
                XCTAssertEqual(c.secondAnchor, prop.result.secondAnchor, line: UInt(prop.result.0))
        }
    }
}

private typealias LayoutSegmentTestParameter = (UInt, pos: CGFloat, forwardY: Bool, lower: FloatingPanelState?, upper: FloatingPanelState?)
private func assertLayoutSegment(_ floatingPanel: FloatingPanelCore, with params: [LayoutSegmentTestParameter]) {
    params.forEach { (line, pos, forwardY, lowr, upper) in
        let segument = floatingPanel.layoutAdapter.segument(at: pos, forward: forwardY)
        XCTAssertEqual(segument.lower, lowr, line: line)
        XCTAssertEqual(segument.upper, upper, line: line)
    }
}

private class CustomSafeAreaFloatingPanelController: FloatingPanelController {
    override var fp_safeAreaInsets: UIEdgeInsets {
        return UIEdgeInsets(top: 64.0, left: 0.0, bottom: 0.0, right: 34.0)
    }
}
