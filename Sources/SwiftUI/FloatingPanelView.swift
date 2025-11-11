// Copyright 2021 the FloatingPanel authors. All rights reserved. MIT license.

#if canImport(SwiftUI)
import SwiftUI
import Combine

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

    /// A binding to the floating panel's current anchor state.
    @Environment(\.state)
    private var state: Binding<FloatingPanelState?>

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

    func makeCoordinator() -> FloatingPanelCoordinatorProxy {
        return FloatingPanelCoordinatorProxy(
            coordinator: coordinator(),
            state: state
        )
    }

    func makeUIViewController(context: Context) -> UIHostingController<MainView> {
        let mainHostingController = UIHostingController(rootView: main)
        mainHostingController.view.backgroundColor = nil
        let contentHostingController = UIHostingController(rootView: content(context.coordinator.proxy))
        context.coordinator.setupFloatingPanel(
            mainHostingController: mainHostingController,
            contentHostingController: contentHostingController
        )

        context.coordinator.observeStateChanges()
        context.coordinator.update(layout: layout, behavior: behavior)

        return mainHostingController
    }

    func updateUIViewController(
        _ uiViewController: UIHostingController<MainView>,
        context: Context
    ) {
        context.coordinator.onUpdate(context: context)
        applyEnvironment(context: context)
        applyAnimatableEnvironment(context: context)
    }
}

@available(iOS 14, *)
extension FloatingPanelView {
    // MARK: - Environment updates
    /// Applies environment values to the floating panel controller.
    func applyEnvironment(context: Context) {
        let fpc = context.coordinator.controller
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

    /// Applies environment values to the floating panel controller with animations if needed.
    func applyAnimatableEnvironment(context: Context) {
        context.coordinator.apply(
            animatableChanges: {
                context.coordinator.update(state: state.wrappedValue)
                context.coordinator.update(layout: layout, behavior: behavior)
            },
            transaction: context.transaction
        )
    }
}

/// A proxy for exposing and controlling a client coordinator object.
///
/// This proxy is introduced to make the implementation more extensible, rather than directly treating a Coordinator
/// with a lifecycle that spans across FloatingPanelView as a FloatingPanelCoordinator. This object was created to
/// control `FloatingPanelView/state` binding property.
@available(iOS 14, *)
class FloatingPanelCoordinatorProxy {
    private let origin: any FloatingPanelCoordinator
    private var stateBinding: Binding<FloatingPanelState?>

    private var subscriptions: Set<AnyCancellable> = Set()

    var proxy: FloatingPanelProxy { origin.proxy }
    var controller: FloatingPanelController { origin.controller }

    init(
        coordinator: any FloatingPanelCoordinator,
        state: Binding<FloatingPanelState?>
    ) {
        self.origin = coordinator
        self.stateBinding = state
    }

    deinit {
        for subscription in subscriptions {
            subscription.cancel()
        }
    }

    func setupFloatingPanel<Main: View, Content: View>(
        mainHostingController: UIHostingController<Main>,
        contentHostingController: UIHostingController<Content>
    ) {
        origin.setupFloatingPanel(
            mainHostingController: mainHostingController,
            contentHostingController: contentHostingController
        )
    }

    func onUpdate<Representable>(
        context: UIViewControllerRepresentableContext<Representable>
    ) where Representable: UIViewControllerRepresentable {
        origin.onUpdate(context: context)
    }
}

@available(iOS 14, *)
extension FloatingPanelCoordinatorProxy {
    // MARK: - Layout and behavior updates

    /// Update layout and behavior objects for the specified floating panel.
    func update(
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
}

@available(iOS 14, *)
extension FloatingPanelCoordinatorProxy {
    // MARK: - State updates

    // Update the state of FloatingPanelController
    func update(state: FloatingPanelState?) {
        guard let state = state else { return }
        controller.move(to: state, animated: false)
    }

    /// Start observing ``FloatingPanelController/state`` through the `Core` object.
    func observeStateChanges() {
        controller.floatingPanel.statePublisher?
            .sink { [weak self] state in
                guard let self = self else { return }
                // Needs to update the state binding value on the next run loop cycle to avoid this error.
                // > Modifying state during view update, this will cause undefined behavior.
                Task { @MainActor in
                    self.stateBinding.wrappedValue = state
                }
            }.store(in: &subscriptions)
    }
}

@available(iOS 14, *)
extension FloatingPanelCoordinatorProxy {
    // MARK: - Environment updates

    /// Applies animatable environment value changes.
    func apply(animatableChanges: @escaping () -> Void, transaction: Transaction) {
        /// Returns the default animator object for compatibility with iOS 17 and earlier.
        func animateUsingDefaultAnimator(changes: @escaping () -> Void) {
            let animator = controller.makeDefaultAnimator()
            animator.addAnimations(changes)
            animator.startAnimation()
        }

        if let animation = transaction.animation, transaction.disablesAnimations == false {
            #if compiler(>=6.0)
            if #available(iOS 18, *) {
                UIView.animate(animation) {
                    animatableChanges()
                }
            } else {
                animateUsingDefaultAnimator {
                    animatableChanges()
                }
            }
            #else
            animateUsingDefaultAnimator {
                animatableChanges()
            }
            #endif
        } else {
            animatableChanges()
        }
    }
}
#endif
