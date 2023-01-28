// Copyright 2018 the FloatingPanel authors. All rights reserved. MIT license.

import XCTest

@testable import FloatingPanel

class ExtensionTests: XCTestCase {
    func test_roundedByDisplayScale() {
        XCTAssertEqual(CGFloat(333.222).rounded(by: 3), 333.3333333333333)
        XCTAssertNotEqual(CGFloat(333.5).rounded(by: 3), 333.66666666666674)
        XCTAssertTrue(CGFloat(333.5).isEqual(to: 333.66666666666674, on: 3.0))
    }
}
