// Copyright 2018 the FloatingPanel authors. All rights reserved. MIT license.

import XCTest
@testable import FloatingPanel

class FloatingPanelStateTests: XCTestCase {
    override func setUp() { }
    override func tearDown() { }

    func test_nextAndPre() {
        var positions: [FloatingPanelState]
        positions = [.full, .half, .tip, .hidden]
        XCTAssertEqual(FloatingPanelState.full.next(in: positions),  .half)
        XCTAssertEqual(FloatingPanelState.full.pre(in: positions),  .full)
        XCTAssertEqual(FloatingPanelState.hidden.next(in: positions), .hidden)
        XCTAssertEqual(FloatingPanelState.hidden.pre(in: positions), .tip)

        positions = [.full, .hidden]
        XCTAssertEqual(FloatingPanelState.full.next(in: positions),  .hidden)
        XCTAssertEqual(FloatingPanelState.full.pre(in: positions),  .full)
        XCTAssertEqual(FloatingPanelState.hidden.next(in: positions), .hidden)
        XCTAssertEqual(FloatingPanelState.hidden.pre(in: positions), .full)
    }
}
