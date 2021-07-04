// Copyright 2021 the FloatingPanel authors. All rights reserved. MIT license.

import FloatingPanel
import SwiftUI

struct RootView<Content: View, PanelContent: View>: UIViewControllerRepresentable {
    @ViewBuilder var content: Content
    @ViewBuilder var panelContent: PanelContent

    public func makeUIViewController(context: Context) -> UIHostingController<Content> {
        UIHostingController(rootView: content)
    }

    public func updateUIViewController(
        _ uiViewController: UIHostingController<Content>,
        context: Context
    ) {
        context.coordinator.updateUIViewController(uiViewController: uiViewController)
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    public class Coordinator {
        let parent: RootView<Content, PanelContent>
        private lazy var fpc = FloatingPanelController()
        private lazy var fpcDelegate = SearchPanelPhoneDelegate()

        init(parent: RootView<Content, PanelContent>) {
            self.parent = parent
        }

        func updateUIViewController(uiViewController: UIHostingController<Content>) {
            fpc.delegate = fpcDelegate
            fpc.contentInsetAdjustmentBehavior = .never

            let panelContent = parent.panelContent
                .onPreferenceChange(ScrollViewPreferenceKey.self) { [weak fpc] scrollView in
                    if let scrollView = scrollView {
                        fpc?.track(scrollView: scrollView)
                    }
                }

            let hostingViewController = UIHostingController(rootView: panelContent)
            fpc.set(contentViewController: hostingViewController)
            fpc.addPanel(toParent: uiViewController, animated: true)
        }
    }
}

final class SearchPanelPhoneDelegate: NSObject, FloatingPanelControllerDelegate, UIGestureRecognizerDelegate {

    func floatingPanel(_ vc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout {
        FloatingPanelBottomLayout()
    }

    func floatingPanelWillBeginDragging(_ vc: FloatingPanelController) {
        if vc.state == .full {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}
