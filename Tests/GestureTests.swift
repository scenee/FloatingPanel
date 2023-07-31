// Copyright 2018 the FloatingPanel authors. All rights reserved. MIT license.

import XCTest
@testable import FloatingPanel

final class GestureTests: XCTestCase {

    func test_delegateProxy_shouldRecognizeSimultaneouslyWith() throws {
        class GestureDelegateProxy: NSObject, UIGestureRecognizerDelegate {
            var callsOfShouldRecognizeSimultaneouslyWith = 0
            func gestureRecognizer(
                _ gestureRecognizer: UIGestureRecognizer,
                shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
            ) -> Bool {
                callsOfShouldRecognizeSimultaneouslyWith += 1
                return true
            }
        }
        let fpc = FloatingPanelController()
        fpc.showForTest()

        let delegateProxy = GestureDelegateProxy()

        // Set a proxy delegate
        fpc.panGestureRecognizer.delegateProxy = delegateProxy

        _ = fpc.panGestureRecognizer.delegate!.gestureRecognizer?(
            UIGestureRecognizer(),
            shouldRecognizeSimultaneouslyWith: UIGestureRecognizer()
        )

        XCTAssertEqual(delegateProxy.callsOfShouldRecognizeSimultaneouslyWith, 1)

        // Check whether the default delegate method is called when the proxy delegate doesn't implement it.
        XCTAssertTrue(
            fpc.panGestureRecognizer.delegate!.gestureRecognizer!(
                fpc.panGestureRecognizer,
                shouldRequireFailureOf: FloatingPanelPanGestureRecognizer()
            )
        )

        // Clear the proxy delegate
        fpc.panGestureRecognizer.delegateProxy = nil

        _ = fpc.panGestureRecognizer.delegate!.gestureRecognizer?(
            UIGestureRecognizer(),
            shouldRecognizeSimultaneouslyWith: UIGestureRecognizer()
        )

        XCTAssertEqual(delegateProxy.callsOfShouldRecognizeSimultaneouslyWith, 1)
    }

    func test_delegateProxy_shouldRequireFailureOf() throws {
        class GestureDelegateProxy: NSObject, UIGestureRecognizerDelegate {
            var callsOfShouldRequireFailureOf = 0
            func gestureRecognizer(
                _ gestureRecognizer: UIGestureRecognizer,
                shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer
            ) -> Bool {
                callsOfShouldRequireFailureOf += 1
                return true
            }
        }
        let fpc = FloatingPanelController()
        fpc.showForTest()

        let delegateProxy = GestureDelegateProxy()

        // Set a proxy delegate
        fpc.panGestureRecognizer.delegateProxy = delegateProxy

        _ = fpc.panGestureRecognizer.delegate!.gestureRecognizer?(
            UIGestureRecognizer(),
            shouldRequireFailureOf: UIGestureRecognizer()
        )

        XCTAssertEqual(delegateProxy.callsOfShouldRequireFailureOf, 1)

        // Clear the proxy delegate
        fpc.panGestureRecognizer.delegateProxy = nil

        _ = fpc.panGestureRecognizer.delegate!.gestureRecognizer?(
            UIGestureRecognizer(),
            shouldRequireFailureOf: UIGestureRecognizer()
        )

        XCTAssertEqual(delegateProxy.callsOfShouldRequireFailureOf, 1)
    }

    func test_delegateProxy_shouldBeRequiredToFailBy() throws {
        class GestureDelegateProxy: NSObject, UIGestureRecognizerDelegate {
            var callsOfShouldBeRequiredToFailBy = 0
            func gestureRecognizer(
                _ gestureRecognizer: UIGestureRecognizer,
                shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
            ) -> Bool {
                callsOfShouldBeRequiredToFailBy += 1
                return false
            }
        }
        let fpc = FloatingPanelController()
        fpc.showForTest()

        let delegateProxy = GestureDelegateProxy()

        fpc.panGestureRecognizer.delegateProxy = delegateProxy

        _ = fpc.panGestureRecognizer.delegate!.gestureRecognizer?(
            UIGestureRecognizer(),
            shouldBeRequiredToFailBy: UIGestureRecognizer()
        )

        XCTAssertEqual(delegateProxy.callsOfShouldBeRequiredToFailBy, 1)

        // Check whether the delegate method of the "proxy" object is called.
        let otherPanGesture = UIPanGestureRecognizer()
        otherPanGesture.name = "_UISheetInteractionBackgroundDismissRecognizer"
        XCTAssertFalse(
            fpc.panGestureRecognizer.delegate!.gestureRecognizer!(
                fpc.panGestureRecognizer,
                shouldBeRequiredToFailBy: otherPanGesture
            )
        )
        XCTAssertEqual(delegateProxy.callsOfShouldBeRequiredToFailBy, 2)

        fpc.panGestureRecognizer.delegateProxy = nil

        // Check whether the delegate method of the "default" object is called.
        let otherPanGesture2 = UIPanGestureRecognizer()
        otherPanGesture2.name = "_UISheetInteractionBackgroundDismissRecognizer"
        XCTAssertTrue(
            fpc.panGestureRecognizer.delegate!.gestureRecognizer!(
                fpc.panGestureRecognizer,
                shouldBeRequiredToFailBy: otherPanGesture2
            )
        )
        XCTAssertEqual(delegateProxy.callsOfShouldBeRequiredToFailBy, 2)
    }
}
