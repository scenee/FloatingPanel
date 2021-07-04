// Copyright 2021 the FloatingPanel authors. All rights reserved. MIT license.

import FloatingPanel
import SwiftUI

struct FloatingPanelProxy {
    fileprivate class Coordinator {
        weak var fpc: FloatingPanelController?
    }

    fileprivate var coordinator = Coordinator()

    func onScrollViewCreated(_ scrollView: UIScrollView) {
        coordinator.fpc?.track(scrollView: scrollView)
    }

    func onSearchBarEditingChanged(_ isFocused: Bool) {
        coordinator.fpc?.move(to: isFocused ? .full : .half, animated: true)
    }
}

struct FloatingPanelView<Content: View, FloatingPanelContent: View>: UIViewControllerRepresentable {
    @ViewBuilder var content: Content
    @ViewBuilder var floatingPanelContent: (FloatingPanelProxy) -> FloatingPanelContent
    @State private var proxy = FloatingPanelProxy()

    public func makeUIViewController(context: Context) -> UIHostingController<Content> {
        let hostingController = UIHostingController(rootView: content)
        hostingController.view.backgroundColor = nil
        context.coordinator.setupFloatingPanel(hostingController)
        return hostingController
    }

    public func updateUIViewController(
        _ uiViewController: UIHostingController<Content>,
        context: Context
    ) {
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    public class Coordinator {
        let parent: FloatingPanelView<Content, FloatingPanelContent>
        private lazy var fpc = FloatingPanelController()
        private lazy var fpcDelegate = SearchPanelPhoneDelegate()

        init(parent: FloatingPanelView<Content, FloatingPanelContent>) {
            self.parent = parent
        }

        func setupFloatingPanel(_ parentViewController: UIViewController) {
            parent.proxy.coordinator.fpc = fpc
            fpc.contentMode = .fitToBounds
            fpc.delegate = fpcDelegate
            fpc.contentInsetAdjustmentBehavior = .never
            fpc.setAppearanceForPhone()
            let panelContent = parent.floatingPanelContent(parent.proxy)
            let hostingViewController = UIHostingController(rootView: panelContent)
            hostingViewController.view.backgroundColor = nil
            fpc.set(contentViewController: hostingViewController)
            fpc.addPanel(toParent: parentViewController, animated: true)
        }
    }
}

final class SearchPanelPhoneDelegate: NSObject, FloatingPanelControllerDelegate {

    func floatingPanel(
        _ vc: FloatingPanelController,
        layoutFor newCollection: UITraitCollection
    ) -> FloatingPanelLayout {
        FloatingPanelBottomLayout()
    }

    func floatingPanelWillBeginDragging(_ vc: FloatingPanelController) {
        if vc.state == .full {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}

extension FloatingPanelController {
    func setAppearanceForPhone() {
        let appearance = SurfaceAppearance()
        appearance.cornerCurve = .continuous
        appearance.cornerRadius = 8.0
        appearance.backgroundColor = .clear
        surfaceView.appearance = appearance
    }
}
