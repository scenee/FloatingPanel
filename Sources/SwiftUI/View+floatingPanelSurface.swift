// Copyright 2021 the FloatingPanel authors. All rights reserved. MIT license.

#if canImport(SwiftUI)
#if compiler(>=6.0)
public import SwiftUI
#else
import SwiftUI
#endif

@available(iOS 14, *)
extension EnvironmentValues {
    struct SurfaceAppearanceKey: EnvironmentKey {
        static let defaultValue = SurfaceAppearance()
    }

    var surfaceAppearance: SurfaceAppearance {
        get { self[SurfaceAppearanceKey.self] }
        set { self[SurfaceAppearanceKey.self] = newValue }
    }

    struct GrabberHandlePaddingKey: EnvironmentKey {
        static let defaultValue: CGFloat = 6.0
    }

    var grabberHandlePadding: CGFloat {
        get { self[GrabberHandlePaddingKey.self] }
        set { self[GrabberHandlePaddingKey.self] = newValue }
    }
}

@available(iOS 14, *)
extension View {
    /// Sets the surface appearance for floating panels within this view.
    ///
    /// This modifier allows you to fully customize the visual styling of the floating panel's
    /// surface, including background color, corner radius, shadows, and borders.
    ///
    /// Example using a pre-defined appearance:
    ///
    /// ```swift
    /// MainView()
    ///     .floatingPanel { _ in
    ///         FloatingPanelContent()
    ///     }
    ///     .floatingPanelSurfaceAppearance(.transparent)
    /// ```
    ///
    /// - Parameter surfaceAppearance: The surface appearance to set for the floating panel.
    public func floatingPanelSurfaceAppearance(
        _ surfaceAppearance: SurfaceAppearance
    ) -> some View {
        environment(\.surfaceAppearance, surfaceAppearance)
    }

    /// Sets the grabber handle padding for floating panels within this view.
    ///
    /// This modifier adjusts the vertical spacing between the grabber handle, such as the visual
    /// indicator at the top of the bottom positioned panel that users can drag.
    ///
    /// Adjusting this value can help with:
    /// - Visual balance and spacing within the panel
    /// - Providing more space for touch interactions with the grabber
    ///
    /// ```swift
    /// MainView()
    ///     .floatingPanel { _ in
    ///         VStack(spacing: 0) {
    ///             Text("Panel Title")
    ///                 .font(.headline)
    ///
    ///             Divider()
    ///                 .padding(.vertical)
    ///
    ///             // Panel content
    ///         }
    ///         .padding(.horizontal)
    ///     }
    ///     // Add more space between the grabber and content for visual balance
    ///     .floatingPanelGrabberHandlePadding(16)
    /// ```
    ///
    /// The default padding is 6.0 points.
    ///
    /// - Parameter padding: The vertical padding in points between the grabber handle
    ///   and the panel content.
    public func floatingPanelGrabberHandlePadding(
        _ padding: CGFloat
    ) -> some View {
        environment(\.grabberHandlePadding, padding)
    }
}
#endif
