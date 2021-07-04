// Copyright 2021 the FloatingPanel authors. All rights reserved. MIT license.

import SwiftUI

struct PanelContentView: View {
    @State var searchText = ""
    @State var isShowingCancelButton = false
    var onKeyboardShown: () -> Void = { }
    var onCancel: () -> Void = { }

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
            isShowingCancelButton: $isShowingCancelButton
        ) { isFocused in
            if isFocused {
                onKeyboardShown()
            }
            isShowingCancelButton = isFocused
        } onCancel: {
            onCancel()
        }
    }

    var resultList: some View {
        ResultsList()
    }
}

