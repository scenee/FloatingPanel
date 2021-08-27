// Copyright 2021 the FloatingPanel authors. All rights reserved. MIT license.

import FloatingPanel

extension FloatingPanel.SurfaceAppearance {
    static var phone: SurfaceAppearance {
        let appearance = SurfaceAppearance()
        appearance.cornerCurve = .continuous
        appearance.cornerRadius = 8.0
        appearance.backgroundColor = .clear
        return appearance
    }
}
