//
//  Created by Shin Yamamoto on 2018/09/18.
//  Copyright © 2018 Shin Yamamoto. All rights reserved.
//

import XCTest
@testable import FloatingPanel

class FloatingPanelControllerTests: XCTestCase {
    override func setUp() {}
    override func tearDown() {}

    func test_warningRetainCycle() {
        let myVC = MyZombieViewController(nibName: nil, bundle: nil)
        let exp = expectation(description: "Warning retain cycle")
        exp.expectedFulfillmentCount = 2 // For layout & behavior logs
        log.hook = {(log, level) in
            if log.contains("A memory leak will occur by a retain cycle because") {
                XCTAssert(level == .warning)
                exp.fulfill()
            }
        }
        myVC.loadViewIfNeeded()
        wait(for: [exp], timeout: 10)
    }

    func test_addPanel() {
        guard let rootVC = UIApplication.shared.keyWindow?.rootViewController else { fatalError() }
        let fpc = FloatingPanelController()
        fpc.addPanel(toParent: rootVC)
        XCTAssert(fpc.surfaceView.frame.minY ==  (fpc.view.bounds.height - fpc.layoutInsets.bottom) - fpc.layout.insetFor(position: .half)!)
        fpc.move(to: .tip, animated: false)
        XCTAssert(fpc.surfaceView.frame.minY == (fpc.view.bounds.height - fpc.layoutInsets.bottom) - fpc.layout.insetFor(position: .tip)!)
    }

    @available(iOS 12.0, *)
    func test_updateLayout_willTransition() {
        class MyDelegate: FloatingPanelControllerDelegate {
            func floatingPanel(_ vc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout? {
                if newCollection.userInterfaceStyle == .dark {
                    XCTFail()
                }
                return nil
            }
        }
        let myDelegate = MyDelegate()
        let fpc = FloatingPanelController(delegate: myDelegate)
        let traitCollection = UITraitCollection(traitsFrom: [fpc.traitCollection,
                                                             UITraitCollection(userInterfaceStyle: .dark)])
        XCTAssertEqual(traitCollection.userInterfaceStyle, .dark)
        fpc.prepare(for: traitCollection)
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
        XCTAssertEqual(fpc.position, .full)
        XCTAssertEqual(delegate.position, .full)
        XCTAssertEqual(fpc.surfaceView.frame.minY, fpc.originYOfSurface(for: .full))

        fpc.move(to: .half, animated: false)
        XCTAssertEqual(fpc.position, .half)
        XCTAssertEqual(delegate.position, .half)
        XCTAssertEqual(fpc.surfaceView.frame.minY, fpc.originYOfSurface(for: .half))

        fpc.move(to: .tip, animated: false)
        XCTAssertEqual(fpc.position, .tip)
        XCTAssertEqual(delegate.position, .tip)
        XCTAssertEqual(fpc.surfaceView.frame.minY, fpc.originYOfSurface(for: .tip))

        fpc.move(to: .hidden, animated: false)
        XCTAssertEqual(fpc.position, .hidden)
        XCTAssertEqual(delegate.position, .hidden)
        XCTAssertEqual(fpc.surfaceView.frame.minY, fpc.originYOfSurface(for: .hidden))

        fpc.move(to: .full, animated: true)
        XCTAssertEqual(fpc.position, .full)
        XCTAssertEqual(delegate.position, .full)
        XCTAssertEqual(fpc.surfaceView.frame.minY, fpc.originYOfSurface(for: .full))

        fpc.move(to: .half, animated: true)
        XCTAssertEqual(fpc.position, .half)
        XCTAssertEqual(delegate.position, .half)
        XCTAssertEqual(fpc.surfaceView.frame.minY, fpc.originYOfSurface(for: .half))

        fpc.move(to: .tip, animated: true)
        XCTAssertEqual(fpc.position, .tip)
        XCTAssertEqual(delegate.position, .tip)
        XCTAssertEqual(fpc.surfaceView.frame.minY, fpc.originYOfSurface(for: .tip))

        fpc.move(to: .hidden, animated: true)
        XCTAssertEqual(fpc.position, .hidden)
        XCTAssertEqual(delegate.position, .hidden)
        XCTAssertEqual(fpc.surfaceView.frame.minY, fpc.originYOfSurface(for: .hidden))
    }
    
    func test_moveWithNearbyPosition() {
        let delegate = FloatingPanelTestDelegate()
        let fpc = FloatingPanelController(delegate: delegate)
        XCTAssertEqual(delegate.position, .hidden)
        fpc.showForTest()
        
        XCTAssertEqual(fpc.nearbyPosition, .half)
        
        fpc.hide()
        XCTAssertEqual(fpc.nearbyPosition, .tip)
        
        fpc.move(to: .full, animated: false)
        XCTAssertEqual(fpc.nearbyPosition, .full)
        XCTAssertEqual(fpc.surfaceView.frame.minY, fpc.originYOfSurface(for: .full))
    }

    func test_originSurfaceY() {
        let fpc = FloatingPanelController(delegate: nil)
        fpc.loadViewIfNeeded()
        fpc.view.frame = CGRect(x: 0, y: 0, width: 375, height: 667)
        fpc.show(animated: false, completion: nil)

        fpc.move(to: .full, animated: false)
        XCTAssertEqual(fpc.surfaceView.frame.minY, fpc.originYOfSurface(for: .full))
        fpc.move(to: .half, animated: false)
        XCTAssertEqual(fpc.surfaceView.frame.minY, fpc.originYOfSurface(for: .half))
        fpc.move(to: .tip, animated: false)
        XCTAssertEqual(fpc.surfaceView.frame.minY, fpc.originYOfSurface(for: .tip))
        fpc.move(to: .hidden, animated: false)
        XCTAssertEqual(fpc.surfaceView.frame.minY, fpc.originYOfSurface(for: .hidden))
    }

    func test_contentMode() {
        let fpc = FloatingPanelController(delegate: nil)
        fpc.loadViewIfNeeded()
        fpc.view.frame = CGRect(x: 0, y: 0, width: 375, height: 667)
        fpc.show(animated: false, completion: nil)

        fpc.contentMode = .static

        fpc.move(to: .full, animated: false)
        XCTAssertEqual(fpc.surfaceView.frame.height, fpc.view.bounds.height - fpc.originYOfSurface(for: .full))
        fpc.move(to: .half, animated: false)
        XCTAssertEqual(fpc.surfaceView.frame.height, fpc.view.bounds.height - fpc.originYOfSurface(for: .full))
        fpc.move(to: .tip, animated: false)
        XCTAssertEqual(fpc.surfaceView.frame.height, fpc.view.bounds.height - fpc.originYOfSurface(for: .full))

        fpc.contentMode = .fitToBounds

        fpc.move(to: .full, animated: false)
        XCTAssertEqual(fpc.surfaceView.frame.height, fpc.view.bounds.height - fpc.originYOfSurface(for: .full))
        fpc.move(to: .half, animated: false)
        XCTAssertEqual(fpc.surfaceView.frame.height, fpc.view.bounds.height - fpc.originYOfSurface(for: .half))
        fpc.move(to: .tip, animated: false)
        XCTAssertEqual(fpc.surfaceView.frame.height, fpc.view.bounds.height - fpc.originYOfSurface(for: .tip))
    }
}

private class MyZombieViewController: UIViewController, FloatingPanelLayout, FloatingPanelBehavior, FloatingPanelControllerDelegate {
    var fpc: FloatingPanelController?
    override func viewDidLoad() {
        fpc = FloatingPanelController(delegate: self)
        fpc?.addPanel(toParent: self)
    }
    func floatingPanel(_ vc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout? {
        return self
    }

    func floatingPanel(_ vc: FloatingPanelController, behaviorFor newCollection: UITraitCollection) -> FloatingPanelBehavior? {
        return self
    }
    var initialPosition: FloatingPanelPosition {
        return .half
    }

    func insetFor(position: FloatingPanelPosition) -> CGFloat? {
        switch position {
        case .full: return UIScreen.main.bounds.height == 667.0 ? 18.0 : 16.0
        case .half: return 262.0
        case .tip: return 69.0
        case .hidden: return nil
        }
    }
}
