// Copyright 2025 the FloatingPanel authors. All rights reserved. MIT license.

#if canImport(SwiftUI)
import SwiftUI

@available(iOS 14, *)
extension EnvironmentValues {
    struct StateKey: EnvironmentKey {
        static var defaultValue: Binding<FloatingPanelState?> = .constant(nil)
    }

    var state: Binding<FloatingPanelState?> {
        get { self[StateKey.self] }
        set { self[StateKey.self] = newValue }
    }
}

@available(iOS 14, *)
extension View {
    /// Sets a binding to track and control the floating panel's state.
    ///
    /// - Important: The timing of changes to this state differs from the timing of
    /// ``FloatingPanelController/state`` and ``FloatingPanelControllerDelegate/floatingPanelDidChangeState(_:)``.
    /// This state updates slightly later due to differences between UIKit animations and SwiftUI view management.
    ///
    /// This modifier provides two-way communication with the floating panel:
    /// - When the user interacts with the panel, the binding updates to reflect the new state
    /// - When you programmatically change the binding value, the panel changes or animates to the new state
    ///
    /// You can use this binding to:
    /// - Respond to state changes when the user interacts with the panel
    /// - Programmatically control the panel position with SwiftUI animations
    /// - Synchronize the panel state with other parts of your UI
    ///
    /// Example usage:
    ///
    /// ```swift
    /// struct MainView: View {
    ///     @State private var panelState: FloatingPanelState?
    ///
    ///     var body: some View {
    ///         ZStack {
    ///             Color.orange
    ///                 .ignoresSafeArea()
    ///                 .floatingPanel { _ in
    ///                     ContentView()
    ///                 }
    ///                 .floatingPanelState($panelState)
    ///
    ///             Button("Move to full") {
    ///                 withAnimation(.interactiveSpring) {
    ///                     panelState = .full
    ///                 }
    ///             }
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter state: A binding to a `FloatingPanelState` value that tracks and controls
    ///   the current state of the floating panel.
    public func floatingPanelState(
        _ state: Binding<FloatingPanelState?>
    ) -> some View {
        environment(\.state, state)
    }
}
#endif
