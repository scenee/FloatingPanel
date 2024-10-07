// Copyright 2025 the FloatingPanel authors. All rights reserved. MIT license.

import FloatingPanel
import SwiftUI

struct MultiPanelView: View {
    var body: some View {
        ZStack {
            Color.orange
                .ignoresSafeArea()
                .floatingPanel(
                    coordinator: MyPanelCoordinator.self
                ) { proxy in
                    ContentView(proxy: proxy)
                }
                .floatingPanelSurfaceAppearance(.transparent())
                .floatingPanelContentMode(.fitToBounds)
                .floatingPanel(
                    coordinator: MyPanelCoordinator.self
                ) { proxy in
                    ContentView(proxy: proxy)
                }
                .floatingPanelContentMode(.static)
                .floatingPanelSurfaceAppearance(.transparent(cornerRadius: 24))
        }
    }
}

#Preview {
    MultiPanelView()
}
