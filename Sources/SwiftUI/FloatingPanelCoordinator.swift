// Copyright 2025 the FloatingPanel authors. All rights reserved. MIT license.

#if canImport(SwiftUI)
#if compiler(>=6.0)
public import SwiftUI
#else
import SwiftUI
#endif

/// A protocol that defines the coordination between SwiftUI and UIKit for FloatingPanel integration.
///
/// The FloatingPanelCoordinator is responsible for managing the connection between the SwiftUI view hierarchy
/// and the underlying ``FloatingPanelController``. It handles the setup, configuration, and event dispatching
/// for floating panels within SwiftUI.
///
/// Implementations of this protocol should handle the following responsibilities:
/// - Creating and configuring the FloatingPanelController
/// - Setting up the content and main views
/// - Managing panel state and position
/// - Handling events and passing them back to SwiftUI
///
/// By default, you can use the built-in ``FloatingPanelDefaultCoordinator`` for basic floating panel integration,
/// or implement a custom coordinator for more advanced functionality and control over events.
///
/// To implement a custom coordinator, you must:
/// 1. Define an associated Event type based on the events you want to monitor
/// 2. Implement the required initializer and properties
/// 3. Handle the setup of the floating panel with the provided hosting controllers
/// 4. Optionally provide custom implementation for `onUpdate` method
@available(iOS 14, *)
@MainActor
public protocol FloatingPanelCoordinator {
    /// The type of events this coordinator can dispatch to its host view.
    ///
    /// This can be an empty enum like in `FloatingPanelDefaultCoordinator.Event` if you don't need
    /// to handle any events, or a more complex type that represents the various events that can occur
    /// in your floating panel implementation.
    associatedtype Event

    /// Creates a new coordinator with an action handler for events.
    ///
    /// - Parameter action: A closure that will be called when events occur in the floating panel.
    ///   The closure takes an event of the associated `Event` type and performs any necessary actions.
    init(action: @escaping (Event) -> Void)

    /// A proxy object that provides access to the underlying FloatingPanelController.
    ///
    /// Use this property to interact with the floating panel, such as moving it to different states
    /// or tracking scroll views.
    var proxy: FloatingPanelProxy { get }

    /// Sets up the floating panel with main and content views.
    ///
    /// This method is called during the creation of the floating panel to configure the relationship
    /// between the main view (the view containing the floating panel) and the content view (the view
    /// displayed within the floating panel).
    ///
    /// - Parameters:
    ///   - mainHostingController: The UIHostingController that hosts the main SwiftUI view.
    ///   - contentHostingController: The UIHostingController that hosts the content SwiftUI view
    ///     to be displayed in the floating panel.
    func setupFloatingPanel<Main: View, Content: View>(
        mainHostingController: UIHostingController<Main>,
        contentHostingController: UIHostingController<Content>
    )

    /// Called when the SwiftUI context updates.
    ///
    /// Use this method to respond to changes in the SwiftUI environment or to update
    /// the floating panel's configuration based on new context.
    ///
    /// - Parameter context: The UIViewControllerRepresentableContext providing context for the update.
    func onUpdate<Representable>(
        context: UIViewControllerRepresentableContext<Representable>
    ) where Representable: UIViewControllerRepresentable
}

@available(iOS 14, *)
extension FloatingPanelCoordinator {
    /// A convenience property that returns the underlying FloatingPanelController.
    ///
    /// This property provides direct access to the controller for advanced configurations
    /// and operations.
    public var controller: FloatingPanelController {
        proxy.controller
    }

}

/// A default implementation of the `FloatingPanelCoordinator` protocol.
///
/// This coordinator provides a simple implementation for setting up the floating panel with
/// minimal configuration. It creates a standard ``FloatingPanelController`` with default settings
/// and an empty event enumeration. Use this coordinator for basic floating panel integration
/// when you don't need custom event handling or special configuration.
@available(iOS 14, *)
@MainActor
public final class FloatingPanelDefaultCoordinator: FloatingPanelCoordinator {
    public enum Event {}

    public let proxy: FloatingPanelProxy
    public let action: (FloatingPanelDefaultCoordinator.Event) -> Void

    public init(action: @escaping (FloatingPanelDefaultCoordinator.Event) -> Void) {
        self.action = action
        self.proxy = .init(controller: FloatingPanelController())
    }

    /// Default implementation for setting up the floating panel with main and content views.
    ///
    /// - Parameters:
    ///   - mainHostingController: The UIHostingController that hosts the main SwiftUI view.
    ///   - contentHostingController: The UIHostingController that hosts the content SwiftUI view
    ///     to be displayed in the floating panel.
    public func setupFloatingPanel<Main: View, Content: View>(
        mainHostingController: UIHostingController<Main>,
        contentHostingController: UIHostingController<Content>
    ) {
        // Set up the content
        contentHostingController.view.backgroundColor = .clear
        controller.set(contentViewController: contentHostingController)

        // Show the panel
        controller.addPanel(toParent: mainHostingController, animated: false)
    }

    public func onUpdate<Representable>(
        context: UIViewControllerRepresentableContext<Representable>
    ) where Representable: UIViewControllerRepresentable {}
}
#endif
