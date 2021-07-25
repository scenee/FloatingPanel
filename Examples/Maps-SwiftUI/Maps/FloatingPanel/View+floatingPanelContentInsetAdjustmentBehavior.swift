// Copyright 2021 the FloatingPanel authors. All rights reserved. MIT license.

import FloatingPanel
import SwiftUI

struct ContentInsetKey: EnvironmentKey {
    static var defaultValue: FloatingPanelController.ContentInsetAdjustmentBehavior = .always
}

extension EnvironmentValues {
    /// The behavior for determining the adjusted content offsets.
    var contentInsetAdjustmentBehavior: FloatingPanelController.ContentInsetAdjustmentBehavior {
        get { self[ContentInsetKey.self] }
        set { self[ContentInsetKey.self] = newValue }
    }
}

extension View {
    /// Sets the content inset adjustment behavior for floating panels within
    /// this view.
    ///
    /// Use this modifier to set a specific content inset adjustment behavior
    /// for floating panel instances within a view:
    ///
    ///     MainView()
    ///         .floatingPanel { _ in
    ///             FloatingPanelContent()
    ///         }
    ///         .floatingPanelContentInsetAdjustmentBehavior(.never)
    ///
    /// - Parameter contentInsetAdjustmentBehavior: The content inset adjustment
    ///   behavior to set.
    public func floatingPanelContentInsetAdjustmentBehavior(
        _ contentInsetAdjustmentBehavior: FloatingPanelController.ContentInsetAdjustmentBehavior
    ) -> some View {
        environment(\.contentInsetAdjustmentBehavior, contentInsetAdjustmentBehavior)
    }
}
