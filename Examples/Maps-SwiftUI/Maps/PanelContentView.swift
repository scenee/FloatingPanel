// Copyright 2021 the FloatingPanel authors. All rights reserved. MIT license.

import SwiftUI

struct PanelContentView: View {
    @State private var searchText = ""
    @State private var isSearchOnFocus = false
    var proxy: FloatingPanelProxy

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            resultList
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
            isShowingCancelButton: $isSearchOnFocus
        ) { isFocused in
            proxy.onSearchBarEditingChanged(isFocused)
            isSearchOnFocus = isFocused
        } onCancel: {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }

    var resultList: some View {
        ResultsList(onCreateScrollView: proxy.onScrollViewCreated(_:))
    }
}
