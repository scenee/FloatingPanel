// Copyright 2025 the FloatingPanel authors. All rights reserved. MIT license.

import FloatingPanel
import SwiftUI

struct InsideTab: View {
    var body: some View {
        if #available(iOS 18.0, *) {
            TabView {
                Tab("Main", systemImage: "lanyardcard") {
                    MainView()
                }
                Tab("Multi Panel", systemImage: "lanyardcard") {
                    MultiPanelView()
                }
            }
        } else {
            TabView {
                MainView()
                    .tabItem {
                        Label("Main", systemImage: "lanyardcard")
                    }
                MultiPanelView()
                    .tabItem {
                        Label("Multi Panel 22", systemImage: "lanyardcard")
                    }
            }
        }
    }
}

#Preview {
    InsideTab()
}
