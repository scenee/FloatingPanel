// Copyright 2021 the FloatingPanel authors. All rights reserved. MIT license.

import SwiftUI

struct PanelContentView: View {
    @State private var scrollView: UIScrollView?
    @State private var searchText = ""
    @State private var isShowingCancelButton = false
    var onKeyboardShown: () -> Void = { }

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            resultList
        }
        // 👇🏻 for the floating panel handle.
        .padding(.top, 6)
        .background(VisualEffectBlur(blurStyle: .systemMaterial))
        .ignoresSafeArea()
        .preference(key: ScrollViewPreferenceKey.self, value: scrollView)
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
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }

    var resultList: some View {
        ResultsList { scrollView in
            self.scrollView = scrollView
        }
    }
}

struct ScrollViewPreferenceKey: PreferenceKey {
  static var defaultValue: UIScrollView? = nil
  static func reduce(value: inout UIScrollView?, nextValue: () -> UIScrollView?) {}
}
