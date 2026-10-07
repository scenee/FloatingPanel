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

    func test_shouldRequireFailureOf_crossScrollView() throws {
        let fpc = FloatingPanelController()
        fpc.showForTest()
        // Without a touch, the pan gesture's location is in the grabber area, where it never waits for the others.
        fpc.surfaceView.grabberAreaOffset = 0

        func shouldRequireFailure(of scrollView: UIScrollView) -> Bool {
            fpc.panGestureRecognizer.delegate!.gestureRecognizer!(
                fpc.panGestureRecognizer,
                shouldRequireFailureOf: scrollView.panGestureRecognizer
            )
        }

        // Should not wait for a scroll view that scrolls only across the panel's axis
        XCTAssertFalse(shouldRequireFailure(of: makeScrollView(contentSize: CGSize(width: 1000, height: 44))))

        let alwaysBounceHorizontal = makeScrollView(contentSize: CGSize(width: 375, height: 44))
        alwaysBounceHorizontal.alwaysBounceHorizontal = true
        XCTAssertFalse(shouldRequireFailure(of: alwaysBounceHorizontal))

        // Should wait for the other scroll views as before
        XCTAssertTrue(shouldRequireFailure(of: makeScrollView(contentSize: CGSize(width: 375, height: 500))))
        XCTAssertTrue(shouldRequireFailure(of: makeScrollView(contentSize: CGSize(width: 1000, height: 500))))
        XCTAssertTrue(shouldRequireFailure(of: makeScrollView(contentSize: CGSize(width: 375, height: 44))))

        let scrollDisabled = makeScrollView(contentSize: CGSize(width: 1000, height: 44))
        scrollDisabled.isScrollEnabled = false
        XCTAssertTrue(shouldRequireFailure(of: scrollDisabled))
    }

    func test_shouldBeginPanning_crossScrollView() throws {
        let contentVC = UIViewController()
        contentVC.view.frame = CGRect(x: 0, y: 0, width: 375, height: 667)

        let row = makeScrollView(contentSize: CGSize(width: 1000, height: 44))
        row.frame.origin.y = 40
        let scrollDisabledRow = makeScrollView(contentSize: CGSize(width: 1000, height: 44))
        scrollDisabledRow.frame.origin.y = 100
        scrollDisabledRow.isScrollEnabled = false
        let verticalScrollView = makeScrollView(contentSize: CGSize(width: 375, height: 500))
        verticalScrollView.frame = CGRect(x: 0, y: 160, width: 375, height: 60)
        // A tracking scroll view inside a horizontally paging scroll view
        let pagingScrollView = makeScrollView(contentSize: CGSize(width: 1125, height: 100))
        pagingScrollView.frame = CGRect(x: 0, y: 400, width: 375, height: 100)
        pagingScrollView.isPagingEnabled = true
        let trackingScrollView = makeScrollView(contentSize: CGSize(width: 375, height: 500))
        trackingScrollView.frame = CGRect(x: 0, y: 0, width: 375, height: 100)
        pagingScrollView.addSubview(trackingScrollView)
        [row, scrollDisabledRow, verticalScrollView, pagingScrollView].forEach { contentVC.view.addSubview($0) }

        let fpc = FloatingPanelController()
        fpc.set(contentViewController: contentVC)
        fpc.track(scrollView: trackingScrollView)
        fpc.showForTest()
        fpc.view.layoutIfNeeded()

        func shouldBegin(on view: UIView, translation: CGPoint) -> Bool {
            let location = view.convert(CGPoint(x: view.bounds.midX, y: view.bounds.midY), to: fpc.surfaceView)
            return fpc.floatingPanel.shouldBeginPanning(at: location, translation: translation)
        }
        let alongAxis = CGPoint(x: 3, y: -20)
        let acrossAxis = CGPoint(x: -20, y: 3)

        // Over a scroll view that scrolls only across the panel's axis, begin only on a drag along the axis
        XCTAssertTrue(shouldBegin(on: row, translation: alongAxis))
        XCTAssertFalse(shouldBegin(on: row, translation: acrossAxis))
        XCTAssertTrue(shouldBegin(on: trackingScrollView, translation: alongAxis))
        XCTAssertFalse(shouldBegin(on: trackingScrollView, translation: acrossAxis))

        // Elsewhere, begin on a drag in any direction as before
        XCTAssertTrue(shouldBegin(on: scrollDisabledRow, translation: acrossAxis))
        XCTAssertTrue(shouldBegin(on: verticalScrollView, translation: acrossAxis))
        XCTAssertTrue(shouldBegin(on: contentVC.view, translation: acrossAxis))

        // Begin to stop an animation even without a translation
        XCTAssertTrue(shouldBegin(on: row, translation: .zero))
    }

    private func makeScrollView(contentSize: CGSize) -> UIScrollView {
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 375, height: 44))
        scrollView.contentSize = contentSize
        return scrollView
    }
}
