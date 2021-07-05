// Copyright 2021 the FloatingPanel authors. All rights reserved. MIT license.

import SwiftUI

struct FloatingPanelContentView: View {
    @State private var searchText = ""
    @State private var isShowingCancelButton = false
    var proxy: FloatingPanelProxy

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            resultsList
        }
        // 👇🏻 for the floating panel handle.
        .padding(.top, 6)
        .background(VisualEffectBlur(blurStyle: .systemMaterial))
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

    var resultsList: some View {
        ResultsList(onScrollViewCreated: proxy.track(scrollView:))
    }
}
