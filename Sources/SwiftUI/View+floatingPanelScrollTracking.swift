// Copyright 2025 the FloatingPanel authors. All rights reserved. MIT license.

#if canImport(SwiftUI)
import SwiftUI

@available(iOS 14, *)
extension View {
    /// Automatically tracks scroll views within this view for seamless integration with a floating panel.
    ///
    /// This modifier automatically detects and tracks a `UIScrollView` instance within your SwiftUI content,
    /// linking it with the floating panel for coordinated scrolling behavior. This is essential for
    /// creating a smooth user experience when a scrollable view is contained in a floating panel.
    ///
    /// Example usage:
    ///
    /// ```swift
    /// MainView()
    ///     .floatingPanel { proxy in
    ///         ScrollView {
    ///             VStack(spacing: 20) {
    ///                 ForEach(items) { item in
    ///                     ItemRow(item)
    ///                 }
    ///             }
    ///             .padding()
    ///         }
    ///         .floatingPanelScrollTracking(proxy: proxy)
    ///     }
    /// ```
    ///
    /// For advanced customization, you can provide an onScrollViewDetected closure to access the hosting controller
    /// and scroll view directly:
    ///
    /// ```swift
    /// .floatingPanelScrollTracking(proxy: proxy) { scrollView, _ in
    ///     // Customize scroll view behavior or appearance
    ///     scrollView.showsVerticalScrollIndicator = false
    ///     scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - proxy: The ``FloatingPanelProxy`` instance from the floating panel's content closure.
    ///   - onScrollViewDetected: Optional closure called when a scroll view is found, allowing for additional customization.
    ///     The closure receives the detected scroll view and its hosting view controller in that order.
    public func floatingPanelScrollTracking(
        proxy: FloatingPanelProxy,
        onScrollViewDetected: ((UIScrollView, UIHostingController<Self>) -> Void)? = nil
    ) -> some View {
        ScrollViewRepresentable(proxy: proxy, onScrollViewDetected: onScrollViewDetected) { self }
    }
}

@available(iOS 14, *)
private struct ScrollViewRepresentable<Content>: UIViewControllerRepresentable where Content: View {
    let proxy: FloatingPanelProxy
    let onScrollViewDetected: ((UIScrollView, UIHostingController<Content>) -> Void)?
    @ViewBuilder
    let content: () -> Content

    func makeUIViewController(context: Context) -> ScrollViewHostingController<Content> {
        let vc = ScrollViewHostingController(
            rootView: content(),
            proxy: proxy,
            onScrollViewDetected: onScrollViewDetected
        )
        vc.view.backgroundColor = .clear
        return vc
    }

    func updateUIViewController(
        _ uiViewController: ScrollViewHostingController<Content>,
        context: Context
    ) {
        uiViewController.rootView = content()
    }

    class ScrollViewHostingController<V>: UIHostingController<V> where V: View {
        let proxy: FloatingPanelProxy
        let onScrollViewDetected: ((UIScrollView, UIHostingController<V>) -> Void)?

        private weak var detectedScrollView: UIScrollView?

        init(
            rootView: V,
            proxy: FloatingPanelProxy,
            onScrollViewDetected: ((UIScrollView, UIHostingController<V>) -> Void)?
        ) {
            self.proxy = proxy
            self.onScrollViewDetected = onScrollViewDetected
            super.init(rootView: rootView)
        }

        @MainActor @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewWillLayoutSubviews() {
            super.viewWillLayoutSubviews()
            if detectedScrollView == nil,
                let scrollView = findUIScrollView(in: self.view)
            {
                proxy.track(scrollView: scrollView)
                onScrollViewDetected?(scrollView, self)
                detectedScrollView = scrollView
            }
        }

        func findUIScrollView(in root: UIView?) -> UIScrollView? {
            guard let root = root else { return nil }
            var queue = ArraySlice([root])
            while !queue.isEmpty {
                let view = queue.popFirst()
                if view?.isKind(of: UIScrollView.self) ?? false {
                    return (view as? UIScrollView)
                }
                queue += view?.subviews ?? []
            }
            return nil
        }
    }
}
#endif
