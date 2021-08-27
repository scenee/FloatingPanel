// Copyright 2021 the FloatingPanel authors. All rights reserved. MIT license.

import FloatingPanel
import SwiftUI

struct SurfaceAppearanceKey: EnvironmentKey {
    static var defaultValue = SurfaceAppearance()
}

extension EnvironmentValues {
    /// The appearance of a surface view.
    var surfaceAppearance: SurfaceAppearance {
        get { self[SurfaceAppearanceKey.self] }
        set { self[SurfaceAppearanceKey.self] = newValue }
    }
}

extension View {
    /// Sets the surface appearance for floating panels within this view.
    ///
    /// Use this modifier to set a specific surface appearance for floating
    /// panel instances within a view:
    ///
    ///     MainView()
    ///         .floatingPanel { _ in
    ///             FloatingPanelContent()
    ///         }
    ///         .floatingPanelSurfaceAppearance(.transparent)
    ///
    ///     extension SurfaceAppearance {
    ///         static var transparent: SurfaceAppearance {
    ///             let appearance = SurfaceAppearance()
    ///             appearance.backgroundColor = .clear
    ///             return appearance
    ///         }
    ///     }
    ///
    /// - Parameter surfaceAppearance: The surface appearance to set.
    public func floatingPanelSurfaceAppearance(
        _ surfaceAppearance: SurfaceAppearance
    ) -> some View {
        environment(\.surfaceAppearance, surfaceAppearance)
    }
}
