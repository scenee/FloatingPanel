// Copyright 2021 the FloatingPanel authors. All rights reserved. MIT license.

import SwiftUI
import FloatingPanel

struct FloatingPanelContentView: View {
    @State private var searchText = ""
    @State private var isShowingCancelButton = false
    var proxy: FloatingPanelProxy

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            ResultsList()
                .ignoresSafeArea() // Needs here with `floatingPanelScrollTracking(proxy:)` on iOS 15
                .floatingPanelScrollTracking(proxy: proxy)
        }
        // 👇🏻 for the floating panel grabber handle.
        .padding(.top, 6)
        .background(
            VisualEffectBlur(blurStyle: .systemMaterial)
                // ⚠️ If the `VisualEffectBlur` view receives taps, it's going
                // to mess up with the whole panel and render it
                // non-interactive, make sure it never receives any taps.
                .allowsHitTesting(false)
        )
        .ignoresSafeArea()
    }

    var searchBar: some View {
        SearchBar(
            "Search for a place or address",
            text: $searchText,
            isShowingCancelButton: $isShowingCancelButton
        ) { isFocused in
            proxy.move(to: isFocused ? .full : .half, animated: true)
            isShowingCancelButton = isFocused
        } onCancel: {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}
