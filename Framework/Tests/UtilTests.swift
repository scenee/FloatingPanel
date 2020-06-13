// Copyright 2018 the FloatingPanel authors. All rights reserved. MIT license.

import XCTest
@testable import FloatingPanel

class UtilTests: XCTestCase {
    func test_displayTrunc() {
        XCTAssertEqual(displayTrunc(333.222, by: 3), 333.3333333333333)
        XCTAssertNotEqual(displayTrunc(333.5, by: 3), 333.66666666666674)
        XCTAssertTrue(displayEqual(333.5, 333.66666666666674, by: 3))
    }
}
