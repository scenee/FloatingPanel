// Copyright 2021 the FloatingPanel authors. All rights reserved. MIT license.

import SwiftUI

extension View {
    func floatingPanel<FloatingPanelContent: View>(
        @ViewBuilder _ floatingPanelContent: @escaping (_: FloatingPanelProxy) -> FloatingPanelContent
    ) -> some View {
        FloatingPanelView(content: { self }, floatingPanelContent: floatingPanelContent)
            .ignoresSafeArea()
    }
}

