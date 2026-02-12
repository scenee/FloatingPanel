// Copyright 2018 the FloatingPanel authors. All rights reserved. MIT license.

import SwiftUI
import XCTest

@testable import FloatingPanel

@available(iOS 14, *)
class CoordinatorProxyTests: XCTestCase {
    override func setUp() {}
    override func tearDown() {}

    // MARK: - Test doubles

    /// Records calls to `move(to:animated:completion:)` without performing real movement.
    final class SpyFloatingPanelController: FloatingPanelController {
        struct MoveCall {
            let state: FloatingPanelState
            let animated: Bool
        }
        fileprivate(set) var moveCalls: [MoveCall] = []

        override func move(
            to state: FloatingPanelState,
            animated: Bool,
            completion: (() -> Void)? = nil
        ) {
            moveCalls.append(MoveCall(state: state, animated: animated))
            super.move(to: state, animated: animated, completion: completion)
        }
    }

    /// A minimal `FloatingPanelCoordinator` that allows injecting a custom controller.
    final class TestCoordinator: FloatingPanelCoordinator {
        typealias Event = Void
        let proxy: FloatingPanelProxy
        let action: (Event) -> Void

        init(action: @escaping (Event) -> Void) {
            self.action = action
            self.proxy = FloatingPanelProxy(controller: FloatingPanelController())
        }

        /// Designated initializer for tests — accepts a pre-made controller.
        init(controller: FloatingPanelController) {
            self.action = { _ in }
            self.proxy = FloatingPanelProxy(controller: controller)
        }

        func setupFloatingPanel<Main: View, Content: View>(
            mainHostingController: UIHostingController<Main>,
            contentHostingController: UIHostingController<Content>
        ) {
            contentHostingController.view.backgroundColor = .clear
            controller.set(contentViewController: contentHostingController)
            controller.addPanel(toParent: mainHostingController, animated: false)
        }

        func onUpdate<Representable>(
            context: UIViewControllerRepresentableContext<Representable>
        ) where Representable: UIViewControllerRepresentable {}
    }

    // MARK: - Helpers

    private func makeProxy(
        spy: SpyFloatingPanelController
    ) -> FloatingPanelCoordinatorProxy {
        let coordinator = TestCoordinator(controller: spy)
        spy.showForTest()
        var state: FloatingPanelState? = spy.state
        let binding = Binding<FloatingPanelState?>(
            get: { state },
            set: { state = $0 }
        )
        return FloatingPanelCoordinatorProxy(
            coordinator: coordinator,
            state: binding
        )
    }
}

// MARK: - Issue #680: update(state:) should skip move when state is unchanged

/// Tests for `FloatingPanelCoordinatorProxy.update(state:)` — the internal bridge between
/// SwiftUI state bindings and `FloatingPanelController`.
@available(iOS 14, *)
extension CoordinatorProxyTests {
    /// During a drag gesture, a delegate callback can trigger a SwiftUI re-render which
    /// calls `update(state:)` with the current state. The fix ensures this redundant call
    /// does NOT invoke `controller.move(to:animated:)`, preserving the interactive transition.
    func test_updateState_skipsMove_whenStateIsUnchanged() {
        let spy = SpyFloatingPanelController()
        let proxy = makeProxy(spy: spy)
        XCTAssertEqual(spy.state, .half)

        // Clear any move calls from setup
        spy.moveCalls.removeAll()

        // update(state:) with the SAME state must not trigger move(to:)
        proxy.update(state: .half)

        XCTAssertTrue(
            spy.moveCalls.isEmpty,
            "move(to:animated:) must not be called when the state is unchanged, "
                + "but was called \(spy.moveCalls.count) time(s)"
        )
    }

    func test_updateState_movesPanel_whenStateIsDifferent() {
        let spy = SpyFloatingPanelController()
        let proxy = makeProxy(spy: spy)
        XCTAssertEqual(spy.state, .half)

        spy.moveCalls.removeAll()

        proxy.update(state: .full)

        XCTAssertEqual(
            spy.moveCalls.count, 1,
            "move(to:animated:) should be called exactly once"
        )
        XCTAssertEqual(spy.moveCalls.first?.state, .full)
        XCTAssertEqual(spy.moveCalls.first?.animated, false)
    }

    func test_updateState_doesNothing_whenStateIsNil() {
        let spy = SpyFloatingPanelController()
        let proxy = makeProxy(spy: spy)
        XCTAssertEqual(spy.state, .half)

        spy.moveCalls.removeAll()

        proxy.update(state: nil)

        XCTAssertTrue(
            spy.moveCalls.isEmpty,
            "move(to:animated:) must not be called when state is nil"
        )
    }
}
