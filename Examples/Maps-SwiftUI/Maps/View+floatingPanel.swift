// Copyright 2021 the FloatingPanel authors. All rights reserved. MIT license.

import SwiftUI

extension View {
    func floatingPanel<FloatingPanelContent: View>(
        @ViewBuilder panelContent: @escaping (_: FloatingPanelProxy) -> FloatingPanelContent
    ) -> some View {
        FloatingPanelView(content: { self }, panelContent: panelContent)
            .ignoresSafeArea()
    }
}

