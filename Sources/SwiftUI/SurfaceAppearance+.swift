// Copyright 2018 the FloatingPanel authors. All rights reserved. MIT license.

#if canImport(SwiftUI)
import SwiftUI

@available(iOS 14, *)
extension FloatingPanel.SurfaceAppearance {
    /// Creates a transparent surface appearance with customizable borders, corners, and shadows.
    ///
    /// This utility method makes it easy to create visually appealing panel surfaces with
    /// common styling options like borders and shadows. The surface is transparent by default,
    /// allowing you to add background effects through your content using SwiftUI views if needed.
    ///
    /// Example usage:
    ///
    /// ```swift
    /// MainView()
    ///     .floatingPanel { _ in
    ///         ZStack {
    ///             // Your panel content
    ///             VStack {
    ///                 Text("Panel Title")
    ///                 // ...
    ///             }
    ///             .padding()
    ///         }
    ///         /// A material effect background within your content
    ///         .background {
    ///             GeometryReader { geometry in
    ///                 Rectangle()
    ///                     .fill(.clear)
    ///                     .frame(height: geometry.size.height * 2)
    ///                     .background(.regularMaterial)
    ///             }
    ///         }
    ///     }
    ///     .floatingPanelSurfaceAppearance(
    ///         .transparent(
    ///             borderColor: .secondary.opacity(0.3),
    ///             borderWidth: 1.0,
    ///             cornerRadius: 16.0,
    ///             shadows: [
    ///                 .init(color: .black, radius: 10, opacity: 0.1, offset: .zero),
    ///                 .init(color: .black, radius: 3, opacity: 0.1, offset: CGSize(width: 0, height: 2))
    ///             ]
    ///         )
    ///     )
    /// ```
    ///
    /// - Parameters:
    ///   - borderColor: The color of the border around the panel's edges. Pass `nil` for no border.
    ///   - borderWidth: The width of the border in points. Defaults to 0.0.
    ///   - cornerRadius: The radius of the panel's corners in points. Defaults to 8.0.
    ///   - shadows: An array of `Shadow` objects defining layered shadow effects.
    ///     Defaults to a single subtle shadow.
    ///
    /// - Returns: A configured `SurfaceAppearance` instance with the specified styling.
    public static func transparent(
        borderColor: Color? = nil,
        borderWidth: Double = 0.0,
        cornerRadius: Double = 8.0,
        shadows: [Shadow] = [Shadow()]
    ) -> SurfaceAppearance {
        let appearance = SurfaceAppearance()
        appearance.backgroundColor = .clear
        let borderUIColor: UIColor?
        if let borderColor {
            borderUIColor = UIColor(borderColor)
        } else {
            borderUIColor = nil
        }
        appearance.borderColor = borderUIColor
        appearance.borderWidth = CGFloat(borderWidth)
        appearance.cornerCurve = .continuous
        appearance.cornerRadius = cornerRadius
        appearance.shadows = shadows
        return appearance
    }
}
#endif
