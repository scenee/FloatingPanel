// Copyright 2021 the FloatingPanel authors. All rights reserved. MIT license.

import FloatingPanel
import SwiftUI

struct ContentModeKey: EnvironmentKey {
    static var defaultValue: FloatingPanelController.ContentMode = .static
}

extension EnvironmentValues {
    /// Used to determine how the floating panel controller lays out the content
    /// view when the surface position changes.
    var contentMode: FloatingPanelController.ContentMode {
        get { self[ContentModeKey.self] }
        set { self[ContentModeKey.self] = newValue }
    }
}

extension View {
    /// Sets the content mode for floating panels within this view.
    ///
    /// Use this modifier to set a specific content mode for floating panel
    /// instances within a view:
    ///
    ///     MainView()
    ///         .floatingPanel { _ in
    ///             FloatingPanelContent()
    ///         }
    ///         .floatingPanelContentMode(.static)
    ///
    /// - Parameter contentMode: The content mode to set.
    public func floatingPanelContentMode(
        _ contentMode: FloatingPanelController.ContentMode
    ) -> some View {
        environment(\.contentMode, contentMode)
    }
}
