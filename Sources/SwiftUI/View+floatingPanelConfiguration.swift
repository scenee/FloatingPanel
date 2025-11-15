// Copyright 2021 the FloatingPanel authors. All rights reserved. MIT license.

#if canImport(SwiftUI)
#if compiler(>=6.0)
public import SwiftUI
#else
import SwiftUI
#endif

@available(iOS 14, *)
extension EnvironmentValues {
    struct ContentInsetAdjustmentBehaviorKey: EnvironmentKey {
        static let defaultValue: FloatingPanelController.ContentInsetAdjustmentBehavior = .always
    }

    var contentInsetAdjustmentBehavior: FloatingPanelController.ContentInsetAdjustmentBehavior {
        get { self[ContentInsetAdjustmentBehaviorKey.self] }
        set { self[ContentInsetAdjustmentBehaviorKey.self] = newValue }
    }

    struct ContentModeKey: EnvironmentKey {
        static let defaultValue: FloatingPanelController.ContentMode = .static
    }

    var contentMode: FloatingPanelController.ContentMode {
        get { self[ContentModeKey.self] }
        set { self[ContentModeKey.self] = newValue }
    }
}

@available(iOS 14, *)
extension View {
    /// Sets the content mode for floating panels within this view.
    ///
    /// The content mode controls how the panel's content view is sized and positioned
    /// when the panel's position changes. Each mode has different behavior:
    ///
    /// - `.static`: The content view maintains its current frame regardless of the
    ///   panel's position. This is the default mode and is suitable for most use cases
    ///   where the content should remain stable.
    ///
    /// - `.fitToBounds`: The content view is resized to fit within the panel's bounds
    ///   at each position. This is useful when you want the content to always fill
    ///   the available space within the panel.
    ///
    /// Example usage:
    ///
    /// ```swift
    /// MainView()
    ///     .floatingPanel { _ in
    ///         VStack {
    ///             Text("Panel Content")
    ///             Image("illustration")
    ///         }
    ///     }
    ///     .floatingPanelContentMode(.fitToBounds)
    /// ```
    ///
    /// - Parameter contentMode: The content mode to use for the floating panel.
    public func floatingPanelContentMode(
        _ contentMode: FloatingPanelController.ContentMode
    ) -> some View {
        environment(\.contentMode, contentMode)
    }

    /// Sets the content inset adjustment behavior for floating panels within this view.
    ///
    /// This modifier controls how the panel adjusts its content insets in relation to
    /// the safe area and the panel's position. This is particularly important for
    /// scrollable content within the panel.
    ///
    /// Available behaviors:
    ///
    /// - `.always`: Always adjust content insets to account for safe areas and panel
    ///   position. This ensures content is properly inset beneath system bars and panel
    ///   elements like the grabber handle. This is the default and recommended for most cases.
    ///
    /// - `.never`: Never adjust content insets. Content will extend to the edges of the
    ///   panel regardless of safe areas. Use this when you want to manually manage insets
    ///   or create custom overlay effects.
    ///
    /// Example usage:
    ///
    /// ```swift
    /// MainView()
    ///     .floatingPanel { _ in
    ///         ScrollView {
    ///             LazyVStack {
    ///                 ForEach(items) { item in
    ///                     ItemRow(item)
    ///                 }
    ///             }
    ///         }
    ///     }
    ///     .floatingPanelContentInsetAdjustmentBehavior(.always)
    /// ```
    ///
    /// - Parameter contentInsetAdjustmentBehavior: The content inset adjustment behavior
    ///   to use for the floating panel.
    public func floatingPanelContentInsetAdjustmentBehavior(
        _ contentInsetAdjustmentBehavior: FloatingPanelController.ContentInsetAdjustmentBehavior
    ) -> some View {
        environment(\.contentInsetAdjustmentBehavior, contentInsetAdjustmentBehavior)
    }
}
#endif
