// Copyright 2021 the FloatingPanel authors. All rights reserved. MIT license.

#if canImport(SwiftUI)
import SwiftUI

/// A SwiftUI view that integrates a floating panel with customizable content.
///
/// ``FloatingPanelView`` provides a SwiftUI wrapper around the UIKit-based ``FloatingPanelController``,
/// allowing you to easily add floating panels to your SwiftUI interface. The view consists of
/// two main components:
///
/// - A main view that serves as the background or parent view
/// - A floating panel that contains custom content and can be positioned and animated
///
/// While you can use this view directly, it's recommended to use the ``SwiftUICore/View/floatingPanel(coordinator:onEvent:content:)``
/// view modifier instead, which provides a more SwiftUI-friendly API:
///
/// ```swift
/// MyView()
///     .floatingPanel { proxy in
///         // Your floating panel content
///         Text("Panel Content")
///     }
///     .floatingPanelLayout(MyCustomLayout())
///     .floatingPanelBehavior(MyCustomBehavior())
/// ```
///
/// You can also provide a custom coordinator and handle events:
///
/// ```swift
/// MyView()
///     .floatingPanel(
///         coordinator: MyCustomCoordinator.self,
///         onEvent: { event in
///             // Handle panel events
///         }
///     ) { proxy in
///         // Your floating panel content
///     }
/// ```
///
/// By default, ``FloatingPanelView`` uses ``FloatingPanelDefaultCoordinator`` to manage the
/// relationship between SwiftUI and UIKit components, but you can provide a custom
/// coordinator for more advanced control and event handling.
@available(iOS 14, *)
struct FloatingPanelView<MainView: View, ContentView: View>: UIViewControllerRepresentable {
    /// A closure that creates the coordinator responsible for managing the floating panel.
    let coordinator: () -> (any FloatingPanelCoordinator)

    /// The view builder that creates the main content underneath the floating panel.
    @ViewBuilder
    var main: MainView

    /// The view builder that creates the content displayed inside the floating panel.
    @ViewBuilder
    var content: (FloatingPanelProxy) -> ContentView

    /// The layout object that defines the position and size of the floating panel.
    @Environment(\.layout)
    private var layout: FloatingPanelLayout

    /// The behavior object that defines the interaction dynamics of the floating panel.
    @Environment(\.behavior)
    private var behavior: FloatingPanelBehavior

    /// The behavior for determining the adjusted content insets in the panel.
    @Environment(\.contentInsetAdjustmentBehavior)
    private var contentInsetAdjustmentBehavior

    /// Constants that define how a panel's content fills the surface.
    @Environment(\.contentMode)
    private var contentMode

    /// The vertical padding between the grabber handle and the content.
    @Environment(\.grabberHandlePadding)
    private var grabberHandlePadding

    /// The appearance configuration for the floating panel's surface view.
    @Environment(\.surfaceAppearance)
    private var surfaceAppearance

    func makeCoordinator() -> any FloatingPanelCoordinator {
        return coordinator()
    }

    func makeUIViewController(context: Context) -> UIHostingController<MainView> {
        let mainHostingController = UIHostingController(rootView: main)
        mainHostingController.view.backgroundColor = nil
        let contentHostingController = UIHostingController(rootView: content(context.coordinator.proxy))
        context.coordinator.setupFloatingPanel(
            mainHostingController: mainHostingController,
            contentHostingController: contentHostingController
        )
        update(floatingPanel: context.coordinator.proxy.controller, layout: layout, behavior: behavior)
        return mainHostingController
    }

    func updateUIViewController(
        _ uiViewController: UIHostingController<MainView>,
        context: Context
    ) {
        let controller = context.coordinator.proxy.controller

        context.coordinator.onUpdate(context: context)
        applyEnvironments(context: context)

        let animatableChanges = {
            update(floatingPanel: controller, layout: layout, behavior: behavior)
        }

        if let animation = context.transaction.animation, context.transaction.disablesAnimations == false {
            #if compiler(>=6.0)
            if #available(iOS 18, *) {
                UIView.animate(animation) {
                    animatableChanges()
                }
            } else {
                animateUsingDefaultAnimator(context: context) {
                    animatableChanges()
                }
            }
            #else
            animateUsingDefaultAnimator(context: context) {
                animatableChanges()
            }
            #endif
        } else {
            animatableChanges()
        }
    }
}

@available(iOS 14, *)
extension FloatingPanelView {
    /// Returns the default animator object for compatibility with iOS 17 and earlier.
    private func animateUsingDefaultAnimator(context: Context, changes: @escaping () -> Void) {
        let animator = context.coordinator.controller.makeDefaultAnimator()
        animator.addAnimations(changes)
        animator.startAnimation()
    }

    /// Update layout and behavior objects for the specified floating panel.
    private func update(
        floatingPanel controller: FloatingPanelController,
        layout: (any FloatingPanelLayout)?,
        behavior: (any FloatingPanelBehavior)?
    ) {
        let shouldInvalidateLayout = controller.layout !== layout

        if let layout = layout {
            controller.layout = layout
        } else {
            controller.layout = FloatingPanelBottomLayout()
        }

        if shouldInvalidateLayout {
            controller.invalidateLayout()
        }

        if let behavior = behavior {
            controller.behavior = behavior
        } else {
            controller.behavior = FloatingPanelDefaultBehavior()
        }
    }

    /// Applies environment values to the floating panel controller.
    private func applyEnvironments(context: Context) {
        let fpc = context.coordinator.proxy.controller
        if fpc.contentInsetAdjustmentBehavior != contentInsetAdjustmentBehavior {
            fpc.contentInsetAdjustmentBehavior = contentInsetAdjustmentBehavior
        }
        if fpc.contentMode != contentMode {
            fpc.contentMode = contentMode
        }
        if fpc.surfaceView.grabberHandlePadding != grabberHandlePadding {
            fpc.surfaceView.grabberHandlePadding = grabberHandlePadding
        }
        if fpc.surfaceView.appearance != surfaceAppearance {
            fpc.surfaceView.appearance = surfaceAppearance
        }
    }
}
#endif
