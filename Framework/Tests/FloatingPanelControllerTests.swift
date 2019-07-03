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
