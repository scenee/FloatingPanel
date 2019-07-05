//
//  Created by Shin Yamamoto on 2019/07/05.
//  Copyright © 2019 scenee. All rights reserved.
//

import XCTest
@testable import FloatingPanel

class FloatingPanelPositionTests: XCTestCase {
    override func setUp() { }
    override func tearDown() { }

    func test_nextAndPre() {
        var positions: [FloatingPanelPosition]
        positions = [.full, .half, .tip, .hidden]
        XCTAssertEqual(FloatingPanelPosition.full.next(in: positions),  .half)
        XCTAssertEqual(FloatingPanelPosition.full.pre(in: positions),  .full)
        XCTAssertEqual(FloatingPanelPosition.hidden.next(in: positions), .hidden)
        XCTAssertEqual(FloatingPanelPosition.hidden.pre(in: positions), .tip)

        positions = [.full, .hidden]
        XCTAssertEqual(FloatingPanelPosition.full.next(in: positions),  .hidden)
        XCTAssertEqual(FloatingPanelPosition.full.pre(in: positions),  .full)
        XCTAssertEqual(FloatingPanelPosition.hidden.next(in: positions), .hidden)
        XCTAssertEqual(FloatingPanelPosition.hidden.pre(in: positions), .full)
    }
}
