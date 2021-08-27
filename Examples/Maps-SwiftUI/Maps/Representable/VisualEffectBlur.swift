// Copyright 2021 the FloatingPanel authors. All rights reserved. MIT license.

import SwiftUI

@available(iOS, introduced: 13, deprecated: 15, message: "Use iOS 15 material API.")
public struct VisualEffectBlur<Content: View>: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style = .systemMaterial
    var vibrancyStyle: UIVibrancyEffectStyle? = nil
    @ViewBuilder var content: Content

    public func makeUIView(context: Context) -> UIVisualEffectView {
        context.coordinator.blurView
    }

    public func updateUIView(_ view: UIVisualEffectView, context: Context) {
        context.coordinator.update(
            content: content,
            blurStyle: blurStyle,
            vibrancyStyle: vibrancyStyle
        )
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(content: content)
    }

    public class Coordinator {
        let blurView = UIVisualEffectView()
        let vibrancyView = UIVisualEffectView()
        let hostingController: UIHostingController<Content>

        init(content: Content) {
            hostingController = UIHostingController(rootView: content)
            hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            hostingController.view.backgroundColor = nil
            blurView.contentView.addSubview(vibrancyView)

            blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            vibrancyView.contentView.addSubview(hostingController.view)
            vibrancyView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        }

        func update(content: Content, blurStyle: UIBlurEffect.Style, vibrancyStyle: UIVibrancyEffectStyle?) {
            hostingController.rootView = content

            let blurEffect = UIBlurEffect(style: blurStyle)
            blurView.effect = blurEffect

            if let vibrancyStyle = vibrancyStyle {
                vibrancyView.effect = UIVibrancyEffect(blurEffect: blurEffect, style: vibrancyStyle)
            } else {
                vibrancyView.effect = nil
            }

            hostingController.view.setNeedsDisplay()
        }
    }
}

public extension VisualEffectBlur where Content == EmptyView {
    init(
        blurStyle: UIBlurEffect.Style = .systemMaterial,
        vibrancyStyle: UIVibrancyEffectStyle? = nil
    ) {
        self.init(blurStyle: blurStyle, vibrancyStyle: vibrancyStyle) {
            EmptyView()
        }
    }
}
