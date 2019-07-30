//
//  Created by Shin Yamamoto on 2019/05/23.
//  Copyright © 2019 Shin Yamamoto. All rights reserved.
//

import XCTest
@testable import FloatingPanel

class FloatingPanelSurfaceViewTests: XCTestCase {
    override func setUp() {}
    override func tearDown() {}

    func test_surfaceView() {
        let surface = FloatingPanelSurfaceView(frame: CGRect(x: 0.0, y: 0.0, width: 320.0, height: 480.0))
        XCTAssert(surface.contentView == nil)
        surface.layoutIfNeeded()
        XCTAssert(surface.grabberHandle.frame.minY == 6.0)
        XCTAssert(surface.grabberHandle.frame.width == surface.grabberHandleWidth)
        XCTAssert(surface.grabberHandle.frame.height == surface.grabberHandleHeight)
        surface.backgroundColor = .red
        surface.layoutIfNeeded()
        XCTAssert(surface.backgroundColor == surface.containerView.backgroundColor)
    }

    func test_surfaceView_constraintsUpdate() {
        let window = UIWindow()
        let surface = FloatingPanelSurfaceView(frame: CGRect(x: 0.0, y: 0.0, width: 320.0, height: 480.0))
        window.addSubview(surface)
        window.makeKeyAndVisible()
        XCTAssert(surface.contentView == nil)
        surface.layoutIfNeeded()
        XCTAssert(surface.grabberHandle.frame.minY == 6.0)
        XCTAssert(surface.grabberHandle.frame.width == surface.grabberHandleWidth)
        XCTAssert(surface.grabberHandle.frame.height == surface.grabberHandleHeight)

        surface.grabberHandleWidth = 44.0
        surface.grabberHandleHeight = 12.0
        surface.layoutIfNeeded()
        waitRunLoop(secs: 0.000_001)
        XCTAssert(surface.grabberHandle.frame.width == surface.grabberHandleWidth, "\(surface.grabberHandle.frame.width) == \(surface.grabberHandleWidth)")
        XCTAssert(surface.grabberHandle.frame.height == surface.grabberHandleHeight, "\(surface.grabberHandle.frame.height) == \(surface.grabberHandleHeight)")
        window.resignKey()
    }

    func test_surfaceView_cornderRaduis() {
        let surface = FloatingPanelSurfaceView(frame: CGRect(x: 0.0, y: 0.0, width: 320.0, height: 480.0))
        XCTAssert(surface.cornerRadius == 0.0)
        XCTAssert(surface.containerView.layer.masksToBounds == false)

        surface.cornerRadius = 10.0
        surface.layoutIfNeeded()
        XCTAssert(surface.cornerRadius == 10.0)
        XCTAssert(surface.containerView.layer.cornerRadius == 10.0)
        XCTAssert(surface.containerView.layer.masksToBounds == true)

        surface.containerView.layer.cornerRadius = 12.0
        surface.layoutIfNeeded()
        XCTAssert(surface.cornerRadius == 12.0)
        XCTAssert(surface.containerView.layer.masksToBounds == true)

        surface.cornerRadius = 0.0
        surface.layoutIfNeeded()
        XCTAssert(surface.cornerRadius == 0.0)
        XCTAssert(surface.containerView.layer.cornerRadius == 0.0)
        XCTAssert(surface.containerView.layer.masksToBounds == false)

        surface.containerView.layer.cornerRadius = 12.0
        surface.setNeedsLayout()
        surface.layoutIfNeeded()
        XCTAssert(surface.cornerRadius == 12.0)
        XCTAssert(surface.containerView.layer.masksToBounds == true)
    }

    func test_surfaceView_border() {
        let surface = FloatingPanelSurfaceView(frame: CGRect(x: 0.0, y: 0.0, width: 320.0, height: 480.0))
        XCTAssert(surface.borderColor == nil)
        XCTAssert(surface.borderWidth == 0.0)

        surface.borderColor = .red
        surface.borderWidth = 3.0
        surface.layoutIfNeeded()
        XCTAssert(surface.containerView.layer.borderColor == UIColor.red.cgColor)
        XCTAssert(surface.containerView.layer.borderWidth == 3.0)
    }
}
