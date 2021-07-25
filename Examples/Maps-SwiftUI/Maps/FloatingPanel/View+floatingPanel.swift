// Copyright 2021 the FloatingPanel authors. All rights reserved. MIT license.

import FloatingPanel
import SwiftUI

extension View {
    /// Presents a floating panel using the given closure as its content.
    ///
    /// The modifier's content view builder receives a `FloatingPanelProxy`
    /// instance; you use the proxy's methods to interact with the associated
    /// `FloatingPanelController`.
    ///
    /// - Parameters:
    ///   - delegate: A type that conforms to the
    ///     `FloatingPanelControllerDelegate` protocol. You have comprehensive
    ///     control over the floating panel behavior when you use a delegate.
    ///   - floatingPanelContent: The floating panel content. This view builder
    ///     receives a `FloatingPanelProxy` instance that you use to interact
    ///     with the `FloatingPanelController`.
    public func floatingPanel<FloatingPanelContent: View>(
        delegate: FloatingPanelControllerDelegate? = nil,
        @ViewBuilder _ floatingPanelContent: @escaping (_: FloatingPanelProxy) -> FloatingPanelContent
    ) -> some View {
        FloatingPanelView(
            delegate: delegate,
            content: { self },
            floatingPanelContent: floatingPanelContent
        )
        .ignoresSafeArea()
    }
}
