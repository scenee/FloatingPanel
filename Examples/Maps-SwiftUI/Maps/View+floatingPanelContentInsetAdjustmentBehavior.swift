// Copyright 2021 the FloatingPanel authors. All rights reserved. MIT license.

import FloatingPanel
import SwiftUI

struct ContentInsetKey: EnvironmentKey {
    static var defaultValue: FloatingPanelController.ContentInsetAdjustmentBehavior = .always
}

extension EnvironmentValues {
    var contentInsetAdjustmentBehavior: FloatingPanelController.ContentInsetAdjustmentBehavior {
        get { self[ContentInsetKey.self] }
        set { self[ContentInsetKey.self] = newValue }
    }
}

extension View {
    public func floatingPanelContentInsetAdjustmentBehavior(_ contentInsetAdjustmentBehavior: FloatingPanelController.ContentInsetAdjustmentBehavior) -> some View {
        environment(\.contentInsetAdjustmentBehavior, contentInsetAdjustmentBehavior)
    }
}
