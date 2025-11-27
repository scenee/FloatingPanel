// Copyright 2025 the FloatingPanel authors. All rights reserved. MIT license.

import FloatingPanel
import SwiftUI

struct ContentView: View {
    let proxy: FloatingPanelProxy
    var body: some View {
        Group {
            if #available(iOS 17.0, *) {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(0...100, id: \.self) { i in
                            Text("Index \(i)")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .frame(height: 60)
                                .background(.clear)
                                .padding(.horizontal)
                        }
                    }
                }
                .scrollClipDisabled()
                .floatingPanelScrollTracking(proxy: proxy)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(0...100, id: \.self) { i in
                            Text("Index \(i)")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .frame(height: 60)
                                .background(.clear)
                                .padding(.horizontal)
                        }
                    }
                }
                .floatingPanelScrollTracking(proxy: proxy) { scrollView, _ in
                    scrollView.clipsToBounds = false
                }
            }
        }
        // Prevent revealing underlying content at the bottom of the panel when the panel is moving beyond its fully‑expanded position.
        .background {
            BackgroundView()
        }
    }
}

#Preview("ContentView") {
    // `FloatingPanelProxy` can be instantiated like this.
    ContentView(proxy: FloatingPanelProxy(controller: FloatingPanelController()))
}
