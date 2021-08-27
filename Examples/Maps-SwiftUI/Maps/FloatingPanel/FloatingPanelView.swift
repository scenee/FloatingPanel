// Copyright 2021 the FloatingPanel authors. All rights reserved. MIT license.

import FloatingPanel
import SwiftUI

/// A proxy for exposing the methods of the floating panel controller.
public struct FloatingPanelProxy {
    /// The associated floating panel controller.
    public weak var fpc: FloatingPanelController?

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
    public func move(
        to floatingPanelState: FloatingPanelState,
        animated: Bool,
        completion: (() -> Void)? = nil
    ) {
        fpc?.move(to: floatingPanelState, animated: animated, completion: completion)
    }
}

/// A view with an associated floating panel.
struct FloatingPanelView<Content: View, FloatingPanelContent: View>: UIViewControllerRepresentable {
    /// A type that conforms to the `FloatingPanelControllerDelegate` protocol.
    var delegate: FloatingPanelControllerDelegate?

    /// The behavior for determining the adjusted content offsets.
    @Environment(\.contentInsetAdjustmentBehavior) var contentInsetAdjustmentBehavior

    /// Constants that define how a panel content fills in the surface.
    @Environment(\.contentMode) var contentMode

    /// The floating panel grabber handle offset.
    @Environment(\.grabberHandlePadding) var grabberHandlePadding

    /// The floating panel `surfaceView` appearance.
    @Environment(\.surfaceAppearance) var surfaceAppearance

    /// The view builder that creates the floating panel parent view content.
    @ViewBuilder var content: Content

    /// The view builder that creates the floating panel content.
    @ViewBuilder var floatingPanelContent: (FloatingPanelProxy) -> FloatingPanelContent

    public func makeUIViewController(context: Context) -> UIHostingController<Content> {
        let hostingController = UIHostingController(rootView: content)
        hostingController.view.backgroundColor = nil
        // We need to wait for the current runloop cycle to complete before our
        // view is actually added (into the view hierarchy), otherwise the
        // environment is not ready yet.
        DispatchQueue.main.async {
            context.coordinator.setupFloatingPanel(hostingController)
        }
        return hostingController
    }

    public func updateUIViewController(
        _ uiViewController: UIHostingController<Content>,
        context: Context
    ) {
        context.coordinator.updateIfNeeded()
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

        init(parent: FloatingPanelView<Content, FloatingPanelContent>) {
            self.parent = parent
        }

        func setupFloatingPanel(_ parentViewController: UIViewController) {
            updateIfNeeded()
            let panelContent = parent.floatingPanelContent(FloatingPanelProxy(fpc: fpc))
            let hostingViewController = UIHostingController(
                rootView: panelContent,
                ignoresKeyboard: true
            )
            hostingViewController.view.backgroundColor = nil
            fpc.set(contentViewController: hostingViewController)
            fpc.addPanel(toParent: parentViewController, at: 1, animated: false)
        }

        func updateIfNeeded() {
            if fpc.contentInsetAdjustmentBehavior != parent.contentInsetAdjustmentBehavior {
                fpc.contentInsetAdjustmentBehavior = parent.contentInsetAdjustmentBehavior
            }
            if fpc.contentMode != parent.contentMode {
                fpc.contentMode = parent.contentMode
            }
            if fpc.delegate !== parent.delegate {
                fpc.delegate = parent.delegate
            }
            if fpc.surfaceView.grabberHandlePadding != parent.grabberHandlePadding {
                fpc.surfaceView.grabberHandlePadding = parent.grabberHandlePadding
            }
            if fpc.surfaceView.appearance != parent.surfaceAppearance {
                fpc.surfaceView.appearance = parent.surfaceAppearance
            }
        }
    }
}
