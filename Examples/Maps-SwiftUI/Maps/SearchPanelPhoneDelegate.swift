// Copyright 2021 the FloatingPanel authors. All rights reserved. MIT license.

import FloatingPanel

final class SearchPanelPhoneDelegate: FloatingPanelControllerDelegate {
    func floatingPanelWillBeginDragging(_ vc: FloatingPanelController) {
        if vc.state == .full {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}
