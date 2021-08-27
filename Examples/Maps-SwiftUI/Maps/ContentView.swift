// Copyright 2021 the FloatingPanel authors. All rights reserved. MIT license.

import SwiftUI
import MapKit

struct ContentView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.623198015869235, longitude: -122.43066818432008),
        span: MKCoordinateSpan(latitudeDelta: 0.4425100023575723, longitudeDelta: 0.28543697435880233)
    )

    var body: some View {
        ZStack {
            Map(coordinateRegion: $region)
                .ignoresSafeArea()
            statusBarBlur
        }
    }

    private var statusBarBlur: some View {
        GeometryReader { geometry in
            VisualEffectBlur()
                .frame(height: geometry.safeAreaInsets.top)
                .ignoresSafeArea()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
