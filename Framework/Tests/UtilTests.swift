//
//  UtilTests.swift
//  FloatingPanelTests
//
//  Created by Shin Yamamoto on 2019/10/24.
//  Copyright © 2019 scenee. All rights reserved.
//

import XCTest
@testable import FloatingPanel

class UtilTests: XCTestCase {
    func test_displayTrunc() {
        XCTAssertEqual(displayTrunc(333.222, by: 3), 333.3333333333333)
        XCTAssertNotEqual(displayTrunc(333.5, by: 3), 333.66666666666674)
        XCTAssertTrue(displayEqual(333.5, 333.66666666666674, by: 3))
    }
}
