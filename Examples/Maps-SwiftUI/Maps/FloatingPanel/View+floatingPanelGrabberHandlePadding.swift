// Copyright 2021 the FloatingPanel authors. All rights reserved. MIT license.

import FloatingPanel
import SwiftUI

struct GrabberHandlePaddingKey: EnvironmentKey {
    static var defaultValue: CGFloat = 6.0
}

extension EnvironmentValues {
    /// The offset of the grabber handle from the interactive edge.
    var grabberHandlePadding: CGFloat {
        get { self[GrabberHandlePaddingKey.self] }
        set { self[GrabberHandlePaddingKey.self] = newValue }
    }
}

extension View {
    /// Sets the grabber handle padding for floating panels within this view.
    ///
    /// Use this modifier to set a specific padding to floating panel instances
    /// within a view:
    ///
    ///     MainView()
    ///         .floatingPanel { _ in
    ///             FloatingPanelContent()
    ///         }
    ///         .floatingPanelGrabberHandlePadding(16)
    ///
    /// - Parameter padding: The grabber handle padding to set.
    public func floatingPanelGrabberHandlePadding(
        _ padding: CGFloat
    ) -> some View {
        environment(\.grabberHandlePadding, padding)
    }
}
