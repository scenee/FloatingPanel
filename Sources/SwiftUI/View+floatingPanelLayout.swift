// Copyright 2025 the FloatingPanel authors. All rights reserved. MIT license.

#if canImport(SwiftUI)
import SwiftUI

@available(iOS 14, *)
extension EnvironmentValues {
    struct LayoutKey: EnvironmentKey {
        static var defaultValue: FloatingPanelLayout = FloatingPanelBottomLayout()
    }

    var layout: FloatingPanelLayout {
        get { self[LayoutKey.self] }
        set { self[LayoutKey.self] = newValue }
    }
}

@available(iOS 14, *)
extension View {
    /// Sets the layout object that defines the position and dimensions of floating panels within this view.
    ///
    /// The layout object controls critical aspects of the floating panel's appearance:
    /// - Available positions (full, half, tip, etc.) and their insets from screen edges
    /// - Initial position when the panel first appears
    /// - Anchoring behavior and constraints
    /// - Layout adaptation for different size classes and device orientations
    ///
    /// FloatingPanel comes with several built-in layouts:
    /// - `FloatingPanelBottomLayout`: Standard bottom-anchored panel (default)
    ///
    /// You can also create custom layouts by implementing the `FloatingPanelLayout` protocol:
    ///
    /// ```swift
    /// struct MyCustomLayout: FloatingPanelLayout {
    ///     var position: FloatingPanelPosition {
    ///         return .bottom
    ///     }
    ///
    ///     var initialState: FloatingPanelState {
    ///         return .half
    ///     }
    ///
    ///     var anchors: [FloatingPanelState: FloatingPanelLayoutAnchoring] {
    ///         return [
    ///             .full: FloatingPanelLayoutAnchor(absoluteInset: 16.0, edge: .top, referenceGuide: .safeArea),
    ///             .half: FloatingPanelLayoutAnchor(fractionalInset: 0.5, edge: .bottom, referenceGuide: .safeArea),
    ///             .tip: FloatingPanelLayoutAnchor(absoluteInset: 44.0, edge: .bottom, referenceGuide: .safeArea)
    ///         ]
    ///     }
    /// }
    /// ```
    ///
    /// Apply the layout to your floating panel:
    ///
    /// ```swift
    /// MainView()
    ///     .floatingPanel { _ in
    ///         FloatingPanelContent()
    ///     }
    ///     .floatingPanelLayout(MyCustomLayout())
    /// ```
    ///
    /// - Parameter layout: An object conforming to the `FloatingPanelLayout` protocol
    ///   that defines the panel's position and dimensions, or `nil` to use the default layout.
    public func floatingPanelLayout(
        _ layout: FloatingPanelLayout?
    ) -> some View {
        environment(\.layout, layout ?? FloatingPanelBottomLayout())
    }
}
#endif
