// Copyright 2018 the FloatingPanel authors. All rights reserved. MIT license.

import OSLog
import XCTest
@testable import FloatingPanel

class ControllerTests: XCTestCase {
    override func setUp() {}
    override func tearDown() {}

#if swift(>=5.5)  // Avoid the 'No exact matches in call to initializer' build failure for OSLogStore when running this test case on iOS 13.7 using Xcode 12.5.1
    func test_warningRetainCycle() throws {
        guard #available(iOS 15.0, *) else {
            throw XCTSkip("Unsupported iOS version: this test needs iOS 15 or later")
        }
        let myVC = MyZombieViewController(nibName: nil, bundle: nil)
        myVC.loadViewIfNeeded()
        let store = try OSLogStore(scope: .currentProcessIdentifier)
        let found = try store
            .getEntries(
                at: store.position(timeIntervalSinceLatestBoot: 0),
                matching: .init(format: "subsystem == '\(Logging.subsystem)'")
            )
            .contains {
                $0.composedMessage.contains("A memory leak occurs due to a retain cycle, as")
            }
        XCTAssertTrue(found)
    }
#endif

    func test_addPanel() {
        let rootVC = UIViewController()
        rootVC.loadViewIfNeeded()
        rootVC.view.bounds = .init(origin: .zero, size: .init(width: 390, height: 844))


        let fpc = FloatingPanelController()
        fpc.addPanel(toParent: rootVC)
        XCTAssertEqual(fpc.surfaceLocation.y, fpc.surfaceLocation(for: .half).y)
        fpc.move(to: .tip, animated: false)
        XCTAssertEqual(fpc.surfaceLocation.y, fpc.surfaceLocation(for: .tip).y)
    }

    func test_updateLayout_willTransition() throws {
        guard #available(iOS 12, *) else {
            throw XCTSkip("Unsupported iOS version: this test needs iOS 12 or later")
        }
        if #available(iOS 17, *) {
            throw XCTSkip("Unsupported iOS version: this test doesn't support iOS 17 or later")
        }
        class MyDelegate: FloatingPanelControllerDelegate {
            func floatingPanel(_ vc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout {
                if newCollection.userInterfaceStyle == .dark {
                    XCTFail()
                }
                return FloatingPanelBottomLayout()
            }
        }
        let myDelegate = MyDelegate()
        let fpc = FloatingPanelController(delegate: myDelegate)
        let traitCollection = UITraitCollection(traitsFrom: [fpc.traitCollection,
                                                             UITraitCollection(userInterfaceStyle: .dark)])
        XCTAssertEqual(traitCollection.userInterfaceStyle, .dark)
    }

    func test_moveTo() {
        let delegate = FloatingPanelTestDelegate()
        let fpc = FloatingPanelController(delegate: delegate)
        XCTAssertEqual(delegate.position, .hidden)
        fpc.showForTest()
        XCTAssertEqual(delegate.position, .half)

        fpc.hide()
        XCTAssertEqual(delegate.position, .hidden)
        
        fpc.move(to: .full, animated: false)
        XCTAssertEqual(fpc.state, .full)
        XCTAssertEqual(delegate.position, .full)
        XCTAssertEqual(fpc.surfaceLocation.y, fpc.surfaceLocation(for: .full).y)

        fpc.move(to: .half, animated: false)
        XCTAssertEqual(fpc.state, .half)
        XCTAssertEqual(delegate.position, .half)

        XCTAssertEqual(fpc.surfaceLocation, fpc.surfaceLocation(for: .half))

        fpc.move(to: .tip, animated: false)
        XCTAssertEqual(fpc.state, .tip)
        XCTAssertEqual(delegate.position, .tip)
        XCTAssertEqual(fpc.surfaceLocation.y, fpc.surfaceLocation(for: .tip).y)

        fpc.move(to: .hidden, animated: false)
        XCTAssertEqual(fpc.state, .hidden)
        XCTAssertEqual(delegate.position, .hidden)
        XCTAssertEqual(fpc.surfaceLocation.y, fpc.surfaceLocation(for: .hidden).y)

        XCTContext.runActivity(named: "move to full(animated)") { act in
            let exp = expectation(description: act.name)
            fpc.move(to: .full, animated: true) {
                XCTAssertEqual(fpc.surfaceLocation.y, fpc.surfaceLocation(for: .full).y)
                exp.fulfill()
            }
            XCTAssertEqual(fpc.state, .full)
            XCTAssertEqual(delegate.position, .full)
            wait(for: [exp], timeout: 1.0)
        }

        XCTContext.runActivity(named: "move to half(animated)") { act in
            let exp = expectation(description: act.name)
            fpc.move(to: .half, animated: true) {
                XCTAssertEqual(fpc.surfaceLocation, fpc.surfaceLocation(for: .half))
                exp.fulfill()
            }
            XCTAssertEqual(fpc.state, .half)
            XCTAssertEqual(delegate.position, .half)
            wait(for: [exp], timeout: 1.0)
        }

        XCTContext.runActivity(named: "move to tip(animated)") { act in
            let exp = expectation(description: act.name)
            fpc.move(to: .tip, animated: true) {
                XCTAssertEqual(fpc.surfaceLocation.y, fpc.surfaceLocation(for: .tip).y)
                exp.fulfill()
            }
            XCTAssertEqual(fpc.state, .tip)
            XCTAssertEqual(delegate.position, .tip)
            wait(for: [exp], timeout: 1.0)
        }

        fpc.move(to: .hidden, animated: true)
        XCTAssertEqual(fpc.state, .hidden)
        XCTAssertEqual(delegate.position, .hidden)
        XCTAssertEqual(fpc.surfaceLocation.y, fpc.surfaceLocation(for: .hidden).y)
    }

    func test_moveTo_bottomEdge() {
        class MyFloatingPanelTop2BottomLayout: FloatingPanelTop2BottomTestLayout {
            override var initialState: FloatingPanelState { return .half }
        }
        let delegate = FloatingPanelTestDelegate()
        let fpc = FloatingPanelController(delegate: delegate)
        fpc.layout = MyFloatingPanelTop2BottomLayout()
        XCTAssertEqual(delegate.position, .hidden)
        fpc.showForTest()
        XCTAssertEqual(delegate.position, .half)

        fpc.hide()
        XCTAssertEqual(delegate.position, .hidden)

        fpc.move(to: .full, animated: false)
        XCTAssertEqual(fpc.state, .full)
        XCTAssertEqual(delegate.position, .full)
        XCTAssertEqual(fpc.surfaceLocation.y, fpc.surfaceLocation(for: .full).y)

        fpc.move(to: .half, animated: false)
        XCTAssertEqual(fpc.state, .half)
        XCTAssertEqual(delegate.position, .half)
        XCTAssertEqual(fpc.surfaceLocation.y, fpc.surfaceLocation(for: .half).y)

        fpc.move(to: .tip, animated: false)
        XCTAssertEqual(fpc.state, .tip)
        XCTAssertEqual(delegate.position, .tip)
        XCTAssertEqual(fpc.surfaceLocation.y, fpc.surfaceLocation(for: .tip).y)

        fpc.move(to: .hidden, animated: false)
        XCTAssertEqual(fpc.state, .hidden)
        XCTAssertEqual(delegate.position, .hidden)
        XCTAssertEqual(fpc.surfaceLocation.y, fpc.surfaceLocation(for: .hidden).y)

        XCTContext.runActivity(named: "move to full(animated)") { act in
            let exp = expectation(description: act.name)
            fpc.move(to: .full, animated: true) {
                XCTAssertEqual(fpc.surfaceLocation.y, fpc.surfaceLocation(for: .full).y)
                exp.fulfill()
            }
            XCTAssertEqual(fpc.state, .full)
            XCTAssertEqual(delegate.position, .full)
            wait(for: [exp], timeout: 1.0)
        }

        XCTContext.runActivity(named: "move to half(animated)") { act in
            let exp = expectation(description: act.name)
            fpc.move(to: .half, animated: true) {
                XCTAssertEqual(fpc.surfaceLocation, fpc.surfaceLocation(for: .half))
                exp.fulfill()
            }
            XCTAssertEqual(fpc.state, .half)
            XCTAssertEqual(delegate.position, .half)
            wait(for: [exp], timeout: 1.0)
        }

        XCTContext.runActivity(named: "move to tip(animated)") { act in
            let exp = expectation(description: act.name)
            fpc.move(to: .tip, animated: true) {
                XCTAssertEqual(fpc.surfaceLocation.y, fpc.surfaceLocation(for: .tip).y)
                exp.fulfill()
            }
            XCTAssertEqual(fpc.state, .tip)
            XCTAssertEqual(delegate.position, .tip)
            wait(for: [exp], timeout: 1.0)
        }

        fpc.move(to: .hidden, animated: true)
        XCTAssertEqual(fpc.state, .hidden)
        XCTAssertEqual(delegate.position, .hidden)
        XCTAssertEqual(fpc.surfaceLocation.y, fpc.surfaceLocation(for: .hidden).y)
    }
    
    func test_moveWithNearbyPosition() {
        let delegate = FloatingPanelTestDelegate()
        let fpc = FloatingPanelController(delegate: delegate)
        XCTAssertEqual(delegate.position, .hidden)
        fpc.showForTest()
        
        XCTAssertEqual(fpc.nearbyState, .half)
        
        fpc.hide()
        XCTAssertEqual(fpc.nearbyState, .tip)
        
        fpc.move(to: .full, animated: false)
        XCTAssertEqual(fpc.nearbyState, .full)
        XCTAssertEqual(fpc.surfaceView.frame.minY, fpc.surfaceLocation(for: .full).y)
    }

    func test_moveTo_didMoveDelegate() {
        let delegate = FloatingPanelTestDelegate()
        let fpc = FloatingPanelController(delegate: delegate)
        XCTAssertEqual(delegate.position, .hidden)
        fpc.showForTest()

        XCTContext.runActivity(named: "move(to:animated:false") { act in
            let exp = expectation(description: act.name)
            exp.expectedFulfillmentCount = 1
            var count = 0
            delegate.didMoveCallback = { _ in
                count += 1
                exp.fulfill()
            }
            fpc.move(to: .full, animated: false)
            wait(for: [exp], timeout: 1.0)

            XCTAssertEqual(count, 1)
        }

        XCTContext.runActivity(named: "move(to:animated:true)") { act in
            let exp = expectation(description: act.name)
            exp.assertForOverFulfill = false
            exp.expectedFulfillmentCount = 1
            var count = 0
            delegate.didMoveCallback = { _ in
                count += 1
            }
            fpc.move(to: .half, animated: true) {
                exp.fulfill()
            }
            wait(for: [exp], timeout: 1.0)

            XCTAssertGreaterThan(count, 1)
        }

        XCTContext.runActivity(named: "move(to:animated:false) with animation") { act in
            let exp = expectation(description: act.name)
            exp.expectedFulfillmentCount = 1
            var count = 0
            delegate.didMoveCallback = { _ in
                count += 1
            }
            UIView.animate(withDuration: 0.3) {
                fpc.move(to: .full, animated: false) {
                    exp.fulfill()
                }
            }
            wait(for: [exp], timeout: 1.0)

            XCTAssertEqual(count, 1)
        }

        XCTContext.runActivity(named: "move(to:animated:true) with animation") { act in
            let exp = expectation(description: act.name)
            exp.assertForOverFulfill = false
            exp.expectedFulfillmentCount = 1
            var count = 0
            delegate.didMoveCallback = { _ in
                count += 1
            }
            UIView.animate(withDuration: 0.3) {
                fpc.move(to: .half, animated: true) {
                    exp.fulfill()
                }
            }
            wait(for: [exp], timeout: 1.0)

            XCTAssertGreaterThan(count, 1)
        }
    }

    func test_originSurfaceY() {
        let fpc = FloatingPanelController(delegate: nil)
        fpc.loadViewIfNeeded()
        fpc.view.frame = CGRect(x: 0, y: 0, width: 375, height: 667)
        fpc.show(animated: false, completion: nil)

        fpc.move(to: .full, animated: false)
        XCTAssertEqual(fpc.surfaceLocation, fpc.surfaceLocation(for: .full))
        fpc.move(to: .half, animated: false)
        XCTAssertEqual(fpc.surfaceLocation, fpc.surfaceLocation(for: .half))
        fpc.move(to: .tip, animated: false)
        XCTAssertEqual(fpc.surfaceLocation, fpc.surfaceLocation(for: .tip))
        fpc.move(to: .hidden, animated: false)
        XCTAssertEqual(fpc.surfaceLocation, fpc.surfaceLocation(for: .hidden))
    }

    func test_contentMode() {
        let fpc = FloatingPanelController(delegate: nil)
        fpc.loadViewIfNeeded()
        fpc.view.frame = CGRect(x: 0, y: 0, width: 375, height: 667)
        fpc.show(animated: false, completion: nil)

        fpc.contentMode = .static

        fpc.move(to: .full, animated: false)
        XCTAssertEqual(fpc.surfaceView.frame.height, fpc.view.bounds.height - fpc.surfaceLocation(for: .full).y)
        fpc.move(to: .half, animated: false)
        XCTAssertEqual(fpc.surfaceView.frame.height, fpc.view.bounds.height - fpc.surfaceLocation(for: .full).y)
        fpc.move(to: .tip, animated: false)
        XCTAssertEqual(fpc.surfaceView.frame.height, fpc.view.bounds.height - fpc.surfaceLocation(for: .full).y)

        fpc.contentMode = .fitToBounds

        fpc.move(to: .full, animated: false)
        XCTAssertEqual(fpc.surfaceView.frame.height, fpc.view.bounds.height - fpc.surfaceLocation(for: .full).y)
        fpc.move(to: .half, animated: false)
        XCTAssertEqual(fpc.surfaceView.frame.height, fpc.view.bounds.height - fpc.surfaceLocation(for: .half).y)
        fpc.move(to: .tip, animated: false)
        XCTAssertEqual(fpc.surfaceView.frame.height, fpc.view.bounds.height - fpc.surfaceLocation(for: .tip).y)
    }
}

private class MyZombieViewController: UIViewController, FloatingPanelLayout, FloatingPanelBehavior, FloatingPanelControllerDelegate {
    var fpc: FloatingPanelController?
    override func viewDidLoad() {
        fpc = FloatingPanelController(delegate: self)
        fpc?.addPanel(toParent: self)
        fpc?.layout = self
        fpc?.behavior = self
    }
    var position: FloatingPanelPosition {
        return .bottom
    }
    var initialState: FloatingPanelState {
        return .half
    }

    let anchors: [FloatingPanelState : FloatingPanelLayoutAnchoring] = [
            .full: FloatingPanelLayoutAnchor(absoluteInset: UIScreen.main.bounds.height == 667.0 ? 18.0 : 16.0,
                                             edge: .top,
                                             referenceGuide: .superview),
            .half: FloatingPanelLayoutAnchor(absoluteInset: 250.0,
                                             edge: .bottom,
                                             referenceGuide: .superview),
            .tip: FloatingPanelLayoutAnchor(absoluteInset: 60.0,
                                            edge: .bottom,
                                            referenceGuide: .superview),
    ]
}
