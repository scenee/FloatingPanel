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

// MARK: - Stale binding guard: prevents revert when unrelated @State triggers re-render

/// When `observeStateChanges()` defers a binding update via `Task { @MainActor }`,
/// a delegate callback (e.g. `didEndAttracting`) can trigger a SwiftUI re-render
/// before that deferred task runs. In that re-render, `update(state:)` receives
/// the OLD binding value. These tests verify that the proxy does not move the panel
/// back to the stale state.
@available(iOS 14, *)
extension CoordinatorProxyTests {

    /// Simulates the exact bug scenario:
    /// 1. Panel internally reaches `.full` (via drag/attraction)
    /// 2. A delegate callback causes a SwiftUI re-render
    /// 3. `update(state:)` is called with the stale `.half` binding
    /// The panel must NOT revert to `.half`.
    func test_updateState_skipsMove_whenBindingIsStaleAfterInternalStateChange() {
        let spy = SpyFloatingPanelController()
        let proxy = makeProxy(spy: spy)
        XCTAssertEqual(spy.state, .half)

        // Establish lastKnownBindingState = .half
        proxy.update(state: .half)
        spy.moveCalls.removeAll()

        // Simulate the panel internally moving to .full (e.g. user drag completed)
        spy.move(to: .full, animated: false)
        spy.moveCalls.removeAll()

        // Simulate stale re-render: a delegate callback updates an unrelated @State,
        // causing updateUIViewController to be called with the OLD binding value (.half)
        proxy.update(state: .half)

        XCTAssertTrue(
            spy.moveCalls.isEmpty,
            "Stale binding value must not cause move(to:), "
                + "but was called \(spy.moveCalls.count) time(s)"
        )
        XCTAssertEqual(spy.state, .full, "Panel must remain at .full")
    }

    /// After a stale re-render, the deferred `Task` updates the binding to match
    /// the controller's current state. This synced value must not trigger a redundant move.
    func test_updateState_skipsRedundantMove_whenDeferredBindingSyncsToControllerState() {
        let spy = SpyFloatingPanelController()
        let proxy = makeProxy(spy: spy)
        XCTAssertEqual(spy.state, .half)

        proxy.update(state: .half)
        spy.moveCalls.removeAll()

        // Panel moves internally to .full
        spy.move(to: .full, animated: false)
        spy.moveCalls.removeAll()

        // Stale re-render (skipped by lastKnownBindingState guard)
        proxy.update(state: .half)
        XCTAssertTrue(spy.moveCalls.isEmpty)

        // Deferred Task finally updates the binding to .full.
        // update(state:) is called again with the synced value.
        proxy.update(state: .full)

        XCTAssertTrue(
            spy.moveCalls.isEmpty,
            "When binding syncs to controller's current state, no move should occur, "
                + "but was called \(spy.moveCalls.count) time(s)"
        )
    }

    /// After the stale-binding cycle resolves, a new intentional state change
    /// (e.g. user taps "Move to tip") must still be applied.
    func test_updateState_movesPanel_whenNewStateRequestedAfterStaleCycle() {
        let spy = SpyFloatingPanelController()
        let proxy = makeProxy(spy: spy)
        XCTAssertEqual(spy.state, .half)

        proxy.update(state: .half)
        spy.moveCalls.removeAll()

        // Panel moves internally to .full
        spy.move(to: .full, animated: false)
        spy.moveCalls.removeAll()

        // Stale re-render (skipped)
        proxy.update(state: .half)

        // Deferred binding sync (no move needed — controller already at .full)
        proxy.update(state: .full)
        spy.moveCalls.removeAll()

        // User requests a new state (e.g. "Move to tip" button)
        proxy.update(state: .tip)

        XCTAssertEqual(
            spy.moveCalls.count, 1,
            "A new intentional state change must trigger move(to:)"
        )
        XCTAssertEqual(spy.moveCalls.first?.state, .tip)
        XCTAssertEqual(spy.moveCalls.first?.animated, false)
    }
}
