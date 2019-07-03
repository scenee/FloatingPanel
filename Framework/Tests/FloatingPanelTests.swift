//
//  Created by Shin Yamamoto on 2019/05/23.
//  Copyright © 2019 Shin Yamamoto. All rights reserved.
//

import XCTest
@testable import FloatingPanel

class FloatingPanelTests: XCTestCase {

    override func setUp() {}

    override func tearDown() {}

    func test_scrolllock() {
        let fpc = FloatingPanelController()
        fpc.loadViewIfNeeded()
        fpc.view.frame = CGRect(x: 0, y: 0, width: 375, height: 667)
        let contentVC1 = UITableViewController(nibName: nil, bundle: nil)
        XCTAssertEqual(contentVC1.tableView.showsVerticalScrollIndicator, true)
        XCTAssertEqual(contentVC1.tableView.bounces, true)

        fpc.set(contentViewController: contentVC1)
        fpc.track(scrollView: contentVC1.tableView)
        fpc.show(animated: false, completion: nil) // half
        XCTAssertEqual(fpc.position, .half)
        XCTAssertEqual(contentVC1.tableView.showsVerticalScrollIndicator, false)
        XCTAssertEqual(contentVC1.tableView.bounces, false)

        fpc.move(to: .full, animated: false)
        XCTAssertEqual(contentVC1.tableView.showsVerticalScrollIndicator, true)
        XCTAssertEqual(contentVC1.tableView.bounces, true)

        fpc.move(to: .tip, animated: false)
        XCTAssertEqual(contentVC1.tableView.showsVerticalScrollIndicator, false)
        XCTAssertEqual(contentVC1.tableView.bounces, false)

        let exp1 = expectation(description: "move to full with animation")
        fpc.move(to: .full, animated: true) {
            XCTAssertEqual(contentVC1.tableView.showsVerticalScrollIndicator, true)
            XCTAssertEqual(contentVC1.tableView.bounces, true)
            exp1.fulfill()
        }
        wait(for: [exp1], timeout: 1.0)

        let exp2 = expectation(description: "move to tip with animation")
        fpc.move(to: .tip, animated: false) {
            XCTAssertEqual(contentVC1.tableView.showsVerticalScrollIndicator, false)
            XCTAssertEqual(contentVC1.tableView.bounces, false)
            exp2.fulfill()
        }
        wait(for: [exp2], timeout: 1.0)

        // Reset the content vc
        let contentVC2 = UITableViewController(nibName: nil, bundle: nil)
        XCTAssertEqual(contentVC2.tableView.showsVerticalScrollIndicator, true)
        XCTAssertEqual(contentVC2.tableView.bounces, true)
        fpc.set(contentViewController: contentVC2)
        fpc.track(scrollView: contentVC2.tableView)
        fpc.show(animated: false, completion: nil)
        XCTAssertEqual(fpc.position, .half)
        XCTAssertEqual(contentVC2.tableView.showsVerticalScrollIndicator, false)
        XCTAssertEqual(contentVC2.tableView.bounces, false)
    }

}

private protocol FloatingPanelTestLayout: FloatingPanelLayout {}
private extension FloatingPanelTestLayout {
    func insetFor(position: FloatingPanelPosition) -> CGFloat? {
        switch position {
        case .full: return 18.0
        case .half: return 262.0
        case .tip: return 69.0
        default: return nil
        }
    }
}
