// Copyright 2021 the FloatingPanel authors. All rights reserved. MIT license.

#if canImport(SwiftUI)
import SwiftUI

@available(iOS 14, *)
extension View {
    /// Overlays this view with a floating panel.
    ///
    /// This modifier is the recommended way to add a floating panel to any SwiftUI view.
    /// It creates a `FloatingPanelView` with the current view as the main content and
    /// adds your custom content to the floating panel.
    ///
    /// ```swift
    /// ScrollView {
    ///     LazyVStack {
    ///         // Main content
    ///         ForEach(items) { item in
    ///             ItemView(item)
    ///         }
    ///     }
    /// }
    /// .floatingPanel { proxy in
    ///     // Panel content
    ///     DetailView()
    /// }
    /// ```
    ///
    /// You can customize the panel by using additional modifiers:
    ///
    /// ```swift
    /// ContentView()
    ///     .floatingPanel { proxy in
    ///         PanelContent()
    ///     }
    ///     .floatingPanelLayout(MyCustomLayout())
    ///     .floatingPanelBehavior(MyCustomBehavior())
    ///     .floatingPanelSurfaceAppearance(MySurfaceAppearance())
    /// ```
    ///
    /// - Parameters:
    ///   - coordinator: A coordinator type that conforms to the ``FloatingPanelCoordinator`` protocol.
    ///     Defaults to ``FloatingPanelDefaultCoordinator``. Use a custom coordinator for advanced control
    ///     over panel behavior and events.
    ///   - action: A closure that is called when events occur in the panel. The event type is defined
    ///     by the coordinator's associated `Event` type. This parameter is ignored if you use the default
    ///     coordinator, which doesn't emit events.
    ///   - content: A closure that returns the content to display in the floating panel.
    ///     This view builder receives a ``FloatingPanelProxy`` instance that you can use to
    ///     interact with the panel, such as tracking scroll views or moving the panel programmatically.
    public func floatingPanel<T: FloatingPanelCoordinator>(
        coordinator: T.Type = FloatingPanelDefaultCoordinator.self,
        onEvent action: ((T.Event) -> Void)? = nil,
        @ViewBuilder content: @escaping (FloatingPanelProxy) -> some View
    ) -> some View {
        FloatingPanelView(
            coordinator: { T.init(action: action ?? { _ in }) },
            main: { self },
            content: content
        )
        .ignoresSafeArea()
    }
}
#endif
