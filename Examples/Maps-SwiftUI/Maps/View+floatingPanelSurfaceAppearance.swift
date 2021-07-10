// Copyright 2021 the FloatingPanel authors. All rights reserved. MIT license.

import FloatingPanel
import SwiftUI

struct SurfaceAppearanceKey: EnvironmentKey {
  static var defaultValue = SurfaceAppearance()
}

extension EnvironmentValues {
  var surfaceAppearance: SurfaceAppearance {
    get { self[SurfaceAppearanceKey.self] }
    set { self[SurfaceAppearanceKey.self] = newValue }
  }
}

extension View {
  public func floatingPanelSurfaceAppearance(_ surfaceAppearance: SurfaceAppearance) -> some View {
    environment(\.surfaceAppearance, surfaceAppearance)
  }
}
