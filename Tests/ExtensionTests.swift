// Copyright 2018 the FloatingPanel authors. All rights reserved. MIT license.

import XCTest
@testable import FloatingPanel

class ExtensionTests: XCTestCase {
    func test_roundedByDisplayScale() {
        XCTAssertEqual(CGFloat(333.222).rounded(by: 3), 333.3333333333333)
        XCTAssertNotEqual(CGFloat(333.5).rounded(by: 3), 333.66666666666674)
        XCTAssertTrue(CGFloat(333.5).isEqual(to: 333.66666666666674, on: 3.0))
    }
    
    func test_roundedByDisplayScale_2() {
        XCTAssertEqual(CGFloat(-0.16666666666674246).rounded(by: 3), 0.0)
        XCTAssertEqual(CGFloat(0.16666666666674246).rounded(by: 3), 0.0)

        XCTAssertEqual(CGFloat(-0.3333333333374246).rounded(by: 3), -0.3333333333333333)
        XCTAssertEqual(CGFloat(-0.3333333333074246).rounded(by: 3), -0.3333333333333333)
        XCTAssertEqual(CGFloat(0.33333333333374246).rounded(by: 3), 0.3333333333333333)
        XCTAssertEqual(CGFloat(0.33333333333074246).rounded(by: 3), 0.3333333333333333)

        XCTAssertEqual(CGFloat(-0.16666666666674246).rounded(by: 2), 0.0)
        XCTAssertEqual(CGFloat(0.16666666666674246).rounded(by: 2), 0.0)

        XCTAssertEqual(CGFloat(-0.16666666666674246).rounded(by: 6), -0.16666666666666666)
        XCTAssertEqual(CGFloat(0.16666666666674246).rounded(by: 6), 0.16666666666666666)
    }
}
