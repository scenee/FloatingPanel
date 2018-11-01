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
        myVC.loadViewIfNeeded()
        // Check if there are memory leak warnings in console logs
    }

    func test_addPanel() {
        guard let rootVC = UIApplication.shared.keyWindow?.rootViewController else { fatalError() }

        let fpc = FloatingPanelController()
        fpc.addPanel(toParent: rootVC)

        waitRunLoop(secs: 1.0)
        XCTAssert(fpc.surfaceView.frame.minY ==  (fpc.view.bounds.height - fpc.layoutInsets.bottom) - fpc.layout.insetFor(position: .half)!)

        fpc.move(to: .tip, animated: true)
        waitRunLoop(secs: 1.0)
        XCTAssert(fpc.surfaceView.frame.minY == (fpc.view.bounds.height - fpc.layoutInsets.bottom) - fpc.layout.insetFor(position: .tip)!)
    }
}

func waitRunLoop(secs: TimeInterval = 0) {
    RunLoop.main.run(until: Date(timeIntervalSinceNow: secs))
}

class MyZombieViewController: UIViewController, FloatingPanelLayout, FloatingPanelBehavior, FloatingPanelControllerDelegate {
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
