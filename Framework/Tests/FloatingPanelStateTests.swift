//
//  Created by Shin Yamamoto on 2019/07/05.
//  Copyright © 2019 scenee. All rights reserved.
//

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
