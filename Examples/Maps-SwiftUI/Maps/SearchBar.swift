// Copyright 2021 the FloatingPanel authors. All rights reserved. MIT license.

import SwiftUI

/// UIKit's `UISearchBar`brought to SwiftUI.
public struct SearchBar: UIViewRepresentable {
    var title: String
    @Binding var text: String
    @Binding var isShowingCancelButton: Bool
    var onEditingChanged: (Bool) -> Void
    var onCancel: () -> Void

    public init(
        _ title: String = "",
        text: Binding<String>,
        isShowingCancelButton: Binding<Bool>,
        onEditingChanged: @escaping (Bool) -> Void = { _ in },
        onCancel: @escaping () -> Void
    ) {
        self.title = title
        self._text = text
        self._isShowingCancelButton = isShowingCancelButton
        self.onEditingChanged = onEditingChanged
        self.onCancel = onCancel
    }

    public func makeUIView(context: UIViewRepresentableContext<SearchBar>) -> UISearchBar {
        let searchBar = UISearchBar(frame: .zero)
        searchBar.searchBarStyle = .minimal
        searchBar.isTranslucent = true
        searchBar.placeholder = title
        searchBar.delegate = context.coordinator
        searchBar.autocapitalizationType = .none
        return searchBar
    }

    public func updateUIView(_ uiView: UISearchBar, context: UIViewRepresentableContext<SearchBar>) {
        uiView.text = text
        uiView.placeholder = title
        uiView.setShowsCancelButton(isShowingCancelButton, animated: true)
    }

    public func makeCoordinator() -> SearchBar.Coordinator {
        Coordinator(parent: self)
    }

    public class Coordinator: NSObject, UISearchBarDelegate {
        var parent: SearchBar

        init(parent: SearchBar) {
            self.parent = parent
        }

        public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            parent.text = searchText
        }

        public func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
            parent.onEditingChanged(true)
        }

        public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            searchBar.resignFirstResponder()
        }

        public func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
            parent.onEditingChanged(false)
        }

        public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
            parent.onCancel()
        }
    }
}
