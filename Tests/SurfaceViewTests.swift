// Copyright 2018 the FloatingPanel authors. All rights reserved. MIT license.

import XCTest
@testable import FloatingPanel

class SurfaceViewTests: XCTestCase {
    override func setUp() {}
    override func tearDown() {}

    func test_surfaceView() {
        let surface = SurfaceView(frame: CGRect(x: 0.0, y: 0.0, width: 320.0, height: 480.0))
        XCTAssertTrue(SurfaceView.requiresConstraintBasedLayout)
        XCTAssert(surface.contentView == nil)
        surface.layoutIfNeeded()
        XCTAssert(surface.grabberHandle.frame.minY == 6.0)
        XCTAssert(surface.grabberHandle.frame.width == surface.grabberHandleSize.width)
        XCTAssert(surface.grabberHandle.frame.height == surface.grabberHandleSize.height)
        surface.backgroundColor = .red
        surface.layoutIfNeeded()
        XCTAssert(surface.backgroundColor == surface.containerView.backgroundColor)
    }

    func test_surfaceView_containerView() {
        XCTContext.runActivity(named: "Bottom sheet") { _ in
            let surface = SurfaceView(frame: CGRect(x: 0.0, y: 0.0, width: 320.0, height: 480.0))
            XCTAssertNil(surface.contentView)
            surface.layoutIfNeeded()

            let height = surface.bounds.height * 2
            surface.containerOverflow = height
            surface.setNeedsLayout()
            surface.layoutIfNeeded()
            XCTAssertEqual(surface.containerView.frame, CGRect(x: 0.0, y: 0.0, width: 320.0, height: 480.0 * 3))
        }

        XCTContext.runActivity(named: "Top sheet") { _ in
            let surface = SurfaceView(frame: CGRect(x: 0.0, y: 0.0, width: 320.0, height: 480.0))
            surface.position = .top
            XCTAssertNil(surface.contentView)
            surface.layoutIfNeeded()

            let height = surface.bounds.height * 2
            surface.containerOverflow = height
            surface.setNeedsLayout()
            surface.layoutIfNeeded()
            XCTAssertEqual(surface.containerView.frame, CGRect(x: 0.0, y: -height, width: 320.0, height: 480.0 * 3))
        }
    }

    func test_surfaceView_contentView() {
        for (position, mode, line) in [
            (.top, .static, #line),
            (.top, .fitToBounds, #line),
            (.bottom, .static, #line),
            (.bottom, .fitToBounds, #line),
        ] as [(FloatingPanelPosition, FloatingPanelController.ContentMode, UInt)] {
            let surface = SurfaceView(frame: CGRect(x: 0.0, y: 0.0, width: 320.0, height: 480.0))
            surface.position = position
            surface.layoutIfNeeded()

            let contentView = UIView()
            surface.set(contentView: contentView, mode: mode)

            let height = surface.bounds.height * 2
            surface.containerOverflow = height
            surface.setNeedsLayout()
            surface.layoutIfNeeded()

            switch position {
            case .top:
                XCTAssertEqual(surface.containerView.frame,
                               CGRect(x: 0.0, y: -height, width: 320.0, height: 480.0 * 3),
                               line: line)
                XCTAssertEqual(surface.convert(surface.contentView?.frame ?? .zero, from: surface.containerView),
                               surface.bounds,
                               line: line)
            case .bottom:
                XCTAssertEqual(surface.contentView?.frame ?? .zero, surface.bounds, line: line)
            default:
                break
            }
        }
    }


    func test_surfaceView_grabberHandle() {
        XCTContext.runActivity(named: "Bottom sheet") { _ in
            let surface = SurfaceView(frame: CGRect(x: 0.0, y: 0.0, width: 320.0, height: 480.0))
            XCTAssertNil(surface.contentView)
            surface.layoutIfNeeded()

            XCTAssertEqual(surface.grabberHandle.frame.minY,  6.0)
            XCTAssertEqual(surface.grabberHandle.frame.width, surface.grabberHandleSize.width)
            XCTAssertEqual(surface.grabberHandle.frame.height, surface.grabberHandleSize.height)

            surface.grabberHandlePadding = 10.0
            surface.grabberHandleSize = CGSize(width: 44.0, height: 12.0)
            surface.setNeedsLayout()
            surface.layoutIfNeeded()
            XCTAssertEqual(surface.grabberHandle.frame.minY,  surface.grabberHandlePadding)
            XCTAssertEqual(surface.grabberHandle.frame.width, surface.grabberHandleSize.width)
            XCTAssertEqual(surface.grabberHandle.frame.height, surface.grabberHandleSize.height)
        }

        XCTContext.runActivity(named: "Top sheet") { _ in
            let surface = SurfaceView(frame: CGRect(x: 0.0, y: 0.0, width: 320.0, height: 480.0))
            surface.position = .top
            XCTAssertNil(surface.contentView)
            surface.layoutIfNeeded()

            XCTAssertEqual(surface.grabberHandle.frame.maxY, (surface.bounds.maxY - 6.0))
            XCTAssertEqual(surface.grabberHandle.frame.width, surface.grabberHandleSize.width)
            XCTAssertEqual(surface.grabberHandle.frame.height, surface.grabberHandleSize.height)

            surface.grabberHandlePadding = 10.0
            surface.setNeedsLayout()
            surface.layoutIfNeeded()
            XCTAssertEqual(surface.grabberHandle.frame.maxY,  surface.bounds.maxY - surface.grabberHandlePadding)
        }
    }

    func test_surfaceView_contentMargins() {
        XCTContext.runActivity(named: "Top sheet") { _ in
            let surface = SurfaceView(frame: CGRect(x: 0.0, y: 0.0, width: 320.0, height: 480.0))
            surface.position = .top
            surface.layoutIfNeeded()
            XCTAssertEqual(surface.containerView.frame, surface.bounds)
            surface.containerMargins = UIEdgeInsets(top: 16.0, left: 16.0, bottom: 16.0, right: 16.0)
            surface.setNeedsLayout()
            surface.layoutIfNeeded()
            XCTAssertEqual(surface.containerView.frame, surface.bounds.inset(by: surface.containerMargins))
        }
        XCTContext.runActivity(named: "Bottom sheet") { _ in
            let surface = SurfaceView(frame: CGRect(x: 0.0, y: 0.0, width: 320.0, height: 480.0))
            surface.layoutIfNeeded()
            XCTAssertEqual(surface.containerView.frame, surface.bounds)
            surface.containerMargins = UIEdgeInsets(top: 16.0, left: 16.0, bottom: 16.0, right: 16.0)
            surface.setNeedsLayout()
            surface.layoutIfNeeded()
            XCTAssertEqual(surface.containerView.frame, surface.bounds.inset(by: surface.containerMargins))
        }
    }

    func test_surfaceView_contentInsets() {
        for (position, mode, line) in [
            (.top, .static, #line),
            (.top, .fitToBounds, #line),
            (.bottom, .static, #line),
            (.bottom, .fitToBounds, #line),
        ] as [(FloatingPanelPosition, FloatingPanelController.ContentMode, UInt)] {
            let surface = SurfaceView(frame: CGRect(x: 0.0, y: 0.0, width: 320.0, height: 480.0))
            surface.position = position
            let contentView = UIView()
            surface.set(contentView: contentView, mode: mode)
            surface.layoutIfNeeded()
            XCTAssertEqual(surface.contentView?.frame ?? .zero, surface.bounds, line: line)
            surface.contentPadding = UIEdgeInsets(top: 16.0, left: 16.0, bottom: 16.0, right: 16.0)
            surface.setNeedsLayout()
            surface.layoutIfNeeded()
            XCTAssertEqual(surface.contentView?.frame ?? .zero, surface.bounds.inset(by: surface.contentPadding), line: line)
        }
    }

    func test_surfaceView_containerMargins_and_contentInsets() {
        for (mode, line) in [
            (.static, #line),
            (.fitToBounds, #line),
        ] as [(FloatingPanelController.ContentMode, UInt)] {
            let surface = SurfaceView(frame: CGRect(x: 0.0, y: 0.0, width: 320.0, height: 480.0))
            let contentView = UIView()
            surface.set(contentView: contentView, mode: mode)
            surface.layoutIfNeeded()
            XCTAssertEqual(surface.contentView?.frame ?? .zero, surface.bounds, line: line)
            surface.containerMargins = UIEdgeInsets(top: 16.0, left: 16.0, bottom: 16.0, right: 16.0)
            surface.contentPadding = UIEdgeInsets(top: 16.0, left: 16.0, bottom: 16.0, right: 16.0)
            surface.setNeedsLayout()
            surface.layoutIfNeeded()
            XCTAssertEqual(surface.containerView.frame, surface.bounds.inset(by: surface.containerMargins), line: line)
            XCTAssertEqual(surface.contentView?.frame ?? .zero, surface.containerView.bounds.inset(by: surface.contentPadding), line: line)
        }
    }

    func test_surfaceView_cornerRadius() {
        let surface = SurfaceView(frame: CGRect(x: 0.0, y: 0.0, width: 320.0, height: 480.0))
        XCTAssert(surface.containerView.layer.cornerRadius == 0.0)
        XCTAssert(surface.containerView.layer.masksToBounds == false)

        let appearance = SurfaceAppearance()

        appearance.cornerRadius = 10.0
        surface.appearance = appearance
        surface.layoutIfNeeded()
        XCTAssert(surface.containerView.layer.cornerRadius == 10.0)
        XCTAssert(surface.containerView.layer.masksToBounds == true)

        surface.containerView.layer.cornerRadius = 12.0
        surface.layoutIfNeeded()
        XCTAssert(surface.containerView.layer.cornerRadius == 12.0)
        XCTAssert(surface.containerView.layer.masksToBounds == true)

        appearance.cornerRadius = 0.0
        surface.appearance = appearance
        surface.layoutIfNeeded()
        XCTAssert(surface.containerView.layer.cornerRadius == 0.0)
        XCTAssert(surface.containerView.layer.masksToBounds == false)

        surface.containerView.layer.cornerRadius = 12.0 // Don't change it directly
        XCTAssert(surface.containerView.layer.cornerRadius == 12.0)
        XCTAssertFalse(surface.containerView.layer.masksToBounds == true)

        surface.setNeedsLayout()
        surface.layoutIfNeeded()
        // Reset corner radius by the current appearance
        XCTAssert(surface.containerView.layer.cornerRadius == 0.0)
        XCTAssert(surface.containerView.layer.masksToBounds == false)

    }

    func test_surfaceView_border() {
        let surface = SurfaceView(frame: CGRect(x: 0.0, y: 0.0, width: 320.0, height: 480.0))
        XCTAssert(surface.containerView.layer.borderWidth == 0.0)

        let appearance = SurfaceAppearance()
        appearance.borderColor = .red
        appearance.borderWidth = 3.0
        surface.appearance = appearance
        surface.layoutIfNeeded()
        XCTAssert(surface.containerView.layer.borderColor == UIColor.red.cgColor)
        XCTAssert(surface.containerView.layer.borderWidth == 3.0)
    }

    func test_surfaceView_grabberArea() {
        let sv = SurfaceView()
        sv.bounds  = .init(x: 0, y: 0, width: 375, height: 500)
        sv.grabberAreaOffset = 44.0
        // Top
        do {
            sv.position = .top
            XCTAssertEqual(sv.grabberAreaFrame,
                           .init(x: 0,
                                 y: sv.bounds.height - sv.grabberAreaOffset,
                                 width: sv.bounds.width,
                                 height: sv.grabberAreaOffset))
        }
        // Bottom
        do {
            sv.position = .bottom
            XCTAssertEqual(sv.grabberAreaFrame,
                           .init(x: 0,
                                 y: 0,
                                 width: sv.bounds.width,
                                 height: sv.grabberAreaOffset))
        }
        // Left
        do {
            sv.position = .left
            XCTAssertEqual(sv.grabberAreaFrame,
                           .init(x: sv.bounds.width - sv.grabberAreaOffset,
                                 y: 0,
                                 width: sv.grabberAreaOffset,
                                 height: sv.bounds.height))
        }
        // Right
        do {
            sv.position = .right
            XCTAssertEqual(sv.grabberAreaFrame,
                           .init(x: 0,
                                 y: 0,
                                 width: sv.grabberAreaOffset,
                                 height: sv.bounds.height))
        }
    }

    func test_surfaceView_grabberAreaDetection() {
        let sv = SurfaceView()
        sv.bounds  = .init(x: 0, y: 0, width: 375, height: 500)
        // Top
        do {
            sv.position = .top
            XCTAssertTrue(sv.grabberAreaContains(.init(x: 0, y: sv.bounds.height)))
            XCTAssertTrue(sv.grabberAreaContains(.init(x: sv.bounds.width / 2, y: sv.bounds.height)))
            XCTAssertTrue(sv.grabberAreaContains(.init(x: sv.bounds.width / 2, y: sv.bounds.height + 2)))
            XCTAssertFalse(sv.grabberAreaContains(.init(x: -2, y: sv.bounds.height)))
            XCTAssertFalse(sv.grabberAreaContains(.init(x: -2, y: -2)))
        }
        // Bottom
        do {
            sv.position = .bottom
            XCTAssertTrue(sv.grabberAreaContains(.init(x: 0, y: 0)))
            XCTAssertTrue(sv.grabberAreaContains(.init(x: sv.bounds.width / 2, y: 0)))
            XCTAssertTrue(sv.grabberAreaContains(.init(x: sv.bounds.width / 2, y: -2)))
            XCTAssertFalse(sv.grabberAreaContains(.init(x: -2, y: 0)))
            XCTAssertFalse(sv.grabberAreaContains(.init(x: -2, y: -2)))
        }
        // Left
        do {
            sv.position = .left
            XCTAssertTrue(sv.grabberAreaContains(.init(x: sv.bounds.width, y: 0)))
            XCTAssertTrue(sv.grabberAreaContains(.init(x: sv.bounds.width, y: sv.bounds.height / 2)))
            XCTAssertTrue(sv.grabberAreaContains(.init(x: sv.bounds.width + 2, y: sv.bounds.height / 2)))
            XCTAssertFalse(sv.grabberAreaContains(.init(x: sv.bounds.width, y: -2)))
            XCTAssertFalse(sv.grabberAreaContains(.init(x: -2, y: -2)))
        }
        // Right
        do {
            sv.position = .right
            XCTAssertTrue(sv.grabberAreaContains(.init(x: 0, y: 0)))
            XCTAssertTrue(sv.grabberAreaContains(.init(x: 0, y: sv.bounds.height / 2)))
            XCTAssertTrue(sv.grabberAreaContains(.init(x: -2, y: sv.bounds.height / 2)))
            XCTAssertFalse(sv.grabberAreaContains(.init(x: 0, y: -2)))
            XCTAssertFalse(sv.grabberAreaContains(.init(x: -2, y: -2)))
        }
    }

}
