// Copyright 2021 the FloatingPanel authors. All rights reserved. MIT license.

import SwiftUI

@main
struct MapsApp: App {
    var body: some Scene {
        WindowGroup {
            RootView {
                ContentView()
            } panelContent: {
                PanelContentView()
            }
            .ignoresSafeArea()
        }
    }
}
