// Copyright 2025 the FloatingPanel authors. All rights reserved. MIT license.

#if canImport(SwiftUI)
import SwiftUI

@available(iOS 14, *)
extension EnvironmentValues {
    struct BehaviorKey: EnvironmentKey {
        static var defaultValue: FloatingPanelBehavior = FloatingPanelDefaultBehavior()
    }

    var behavior: FloatingPanelBehavior {
        get { self[BehaviorKey.self] }
        set { self[BehaviorKey.self] = newValue }
    }
}

@available(iOS 14, *)
extension View {
    /// Sets the behavior object controlling the interactive dynamics of floating panels within this view.
    ///
    /// The behavior object defines how the floating panel responds to user interactions,
    /// including:
    /// - Momentum and velocity effects during dragging
    /// - Position snapping behavior when released
    /// - Projection behavior after a swipe gesture
    /// - Interaction restrictions for certain positions
    ///
    /// By default, the panel uses `FloatingPanelDefaultBehavior`, but you can create
    /// your own custom behavior by implementing the `FloatingPanelBehavior` protocol:
    ///
    /// ```swift
    /// struct MyCustomBehavior: FloatingPanelBehavior {
    ///     func shouldProjectMomentum(_ fpc: FloatingPanelController, for proposedTargetPosition: FloatingPanelState) -> Bool {
    ///         return true
    ///     }
    ///
    ///     func momentumProjection(from initialVelocity: CGPoint) -> CGPoint {
    ///         return CGPoint(x: 0, y: initialVelocity.y * 0.5)
    ///     }
    /// }
    /// ```
    ///
    /// Apply the behavior to your floating panel:
    ///
    /// ```swift
    /// MainView()
    ///     .floatingPanel { _ in
    ///         FloatingPanelContent()
    ///     }
    ///     .floatingPanelBehavior(MyCustomBehavior())
    /// ```
    ///
    /// - Parameter behavior: An object conforming to the `FloatingPanelBehavior` protocol
    ///   that controls the panel's interactive dynamics, or `nil` to use the default behavior.
    public func floatingPanelBehavior(
        _ behavior: FloatingPanelBehavior?
    ) -> some View {
        environment(\.behavior, behavior ?? FloatingPanelDefaultBehavior())
    }
}
#endif
