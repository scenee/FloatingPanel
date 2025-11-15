// Copyright 2021 the FloatingPanel authors. All rights reserved. MIT license.

#if canImport(SwiftUI)
import SwiftUI

/// A proxy for exposing and controlling the floating panel within SwiftUI views.
///
/// `FloatingPanelProxy` provides a bridge between SwiftUI views and the underlying
/// `FloatingPanelController`, enabling you to programmatically interact with the
/// floating panel from your SwiftUI content. This proxy is automatically provided to
/// the content view through the `floatingPanel()` modifier's content closure.
///
/// Use this proxy to:
/// - Programmatically move the panel to different positions
/// - Access the underlying UIKit controller for advanced customization
///
/// ```swift
/// MyView()
///     .floatingPanel { proxy in
///         ScrollView {
///             VStack {
///                 // Your content
///
///                 Button("Move To Full") {
///                     proxy.move(to: .full, animated: true)
///                 }
///             }
///         }
///     }
/// ```
@available(iOS 14, *)
@MainActor
public struct FloatingPanelProxy {
    /// The associated floating panel controller.
    ///
    /// This gives direct access to the underlying `FloatingPanelController` instance,
    /// allowing you to use any features not directly exposed by the proxy methods.
    /// Use this property when you need advanced control over the panel's behavior.
    public let controller: FloatingPanelController

    public init(controller: FloatingPanelController) {
        self.controller = controller
    }

    /// Moves the floating panel to the specified position.
    ///
    /// Use this method to programmatically change the panel's position in response to
    /// user actions or application state changes. The available positions are defined
    /// by the current `FloatingPanelLayout` and typically include `.full`, `.half`,
    /// and `.tip`.
    ///
    /// ```swift
    /// Button("Show Full Panel") {
    ///     proxy.move(to: .full, animated: true)
    /// }
    /// ```
    ///
    /// You can also use this method with a completion handler to perform actions
    /// after the panel has finished moving:
    ///
    /// ```swift
    /// proxy.move(to: .full, animated: true) {
    ///     // Code to execute after the panel reaches the full position
    ///     self.loadDetailedData()
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - floatingPanelState: The state to move to (e.g., `.full`, `.half`, `.tip`).
    ///     The available states depend on the current `FloatingPanelLayout`.
    ///   - animated: `true` to animate the transition to the new state; `false`
    ///     for an immediate transition without animation.
    ///   - completion: An optional closure that will be executed after the panel
    ///     has completed moving to the new position.
    public func move(
        to floatingPanelState: FloatingPanelState,
        animated: Bool,
        completion: (() -> Void)? = nil
    ) {
        // Need to use this method which doesn't use the custom NumericSpringingAnimator because it doesn't work with
        // SwiftUI animation.
        controller.moveForSwiftUI(to: floatingPanelState, animated: animated, completion: completion)
    }
}

@available(iOS 14, *)
extension FloatingPanelProxy {
    /// Tracks the specified scroll view to coordinate panel and scroll movements.
    ///
    /// - Important: It is strongly recommended to use ``SwiftUICore/View/floatingPanelScrollTracking(proxy:onScrollViewDetected:)``
    /// instead of this method, as it provides a more SwiftUI-friendly approach to scroll tracking.
    ///
    /// - Parameter scrollView: The scroll view to track. The panel will coordinate
    ///   its movements with this scroll view.
    public func track(scrollView: UIScrollView) {
        controller.track(scrollView: scrollView)
    }
}
#endif
