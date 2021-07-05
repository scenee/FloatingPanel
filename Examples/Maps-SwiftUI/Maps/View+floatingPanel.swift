// Copyright 2021 the FloatingPanel authors. All rights reserved. MIT license.

import SwiftUI

extension View {
    /// Presents a floating panel using the given closure as its content.
    ///
    /// - Parameters:
    ///   - floatingPanelContent: A closure returning the content of the
    ///     floating panel.
    public func floatingPanel<FloatingPanelContent: View>(
        @ViewBuilder _ floatingPanelContent: @escaping (_: FloatingPanelProxy) -> FloatingPanelContent
    ) -> some View {
        FloatingPanelView(
            content: { self },
            floatingPanelContent: floatingPanelContent
        )
        .ignoresSafeArea()
    }
}

