// Copyright 2021 the FloatingPanel authors. All rights reserved. MIT license.

import FloatingPanel
import SwiftUI

/// A proxy for exposing the methods of the floating panel controller.
public struct FloatingPanelProxy {
    /// The associated floating panel controller.
    weak var fpc: FloatingPanelController?

    /// Tracks the specified scroll view to correspond with the scroll.
    ///
    /// - Parameter scrollView: Specify a scroll view to continuously and
    ///   seamlessly work in concert with interactions of the surface view.
    public func track(scrollView: UIScrollView) {
        fpc?.track(scrollView: scrollView)
    }

    /// Moves the floating panel to the specified position.
    ///
    /// - Parameters:
    ///   - floatingPanelState: The state to move to.
    ///   - animated: `true` to animate the transition to the new state; `false`
    ///     otherwise.
    public func move(to floatingPanelState: FloatingPanelState, animated: Bool) {
        fpc?.move(to: floatingPanelState, animated: animated)
    }
}


/// A view with an associated floating panel.
struct FloatingPanelView<Content: View, FloatingPanelContent: View>: UIViewControllerRepresentable {
    /// The view builder that creates the floating panel parent view content.
    @ViewBuilder var content: Content

    /// The view builder that creates the floating panel content.
    @ViewBuilder var floatingPanelContent: (FloatingPanelProxy) -> FloatingPanelContent

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

    /// `FloatingPanelView` coordinator.
    ///
    /// Responsible to setup the view hierarchy and floating panel.
    final class Coordinator {
        private let parent: FloatingPanelView<Content, FloatingPanelContent>
        private lazy var fpc = FloatingPanelController()
        private lazy var fpcDelegate = SearchPanelPhoneDelegate()

        init(parent: FloatingPanelView<Content, FloatingPanelContent>) {
            self.parent = parent
        }

        func setupFloatingPanel(_ parentViewController: UIViewController) {
            fpc.contentMode = .fitToBounds
            fpc.delegate = fpcDelegate
            fpc.contentInsetAdjustmentBehavior = .never
            fpc.setAppearanceForPhone()
            let panelContent = parent.floatingPanelContent(FloatingPanelProxy(fpc: fpc))
            let hostingViewController = UIHostingController(rootView: panelContent)
            hostingViewController.view.backgroundColor = nil
            fpc.set(contentViewController: hostingViewController)
            fpc.addPanel(toParent: parentViewController, animated: true)
        }
    }
}

final class SearchPanelPhoneDelegate: FloatingPanelControllerDelegate {
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
