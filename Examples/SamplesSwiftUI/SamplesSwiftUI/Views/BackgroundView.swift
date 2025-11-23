import SwiftUI

struct BackgroundView: View {
    var body: some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(.clear)
                .frame(height: geometry.size.height * 2)
                .backgroundEffect()
        }
    }
}

extension View {
    @ViewBuilder
    fileprivate func backgroundEffect() -> some View {
        if #available(iOS 26, *) {
            self.glassEffect(.regular, in: .rect)
        } else {
            self.background(.regularMaterial)
        }
    }
}
