// Copyright 2021 the FloatingPanel authors. All rights reserved. MIT license.

import FloatingPanel
import SwiftUI

struct ContentModeKey: EnvironmentKey {
    static var defaultValue: FloatingPanelController.ContentMode = .static
}

extension EnvironmentValues {
    var contentMode: FloatingPanelController.ContentMode {
        get { self[ContentModeKey.self] }
        set { self[ContentModeKey.self] = newValue }
    }
}

extension View {
    public func floatingPanelContentMode(_ contentMode: FloatingPanelController.ContentMode) -> some View {
        environment(\.contentMode, contentMode)
    }
}
