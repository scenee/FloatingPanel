// Copyright 2021 the FloatingPanel authors. All rights reserved. MIT license.

import SwiftUI

@main
struct MapsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .floatingPanel { proxy in
                    FloatingPanelContentView(proxy: proxy)
                }
                .floatingPanelSurfaceAppearance(.phone)
                .floatingPanelContentMode(.fitToBounds)
                .floatingPanelContentInsetAdjustmentBehavior(.never)
        }
    }
}
