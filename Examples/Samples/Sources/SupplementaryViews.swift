// Copyright 2018 the FloatingPanel authors. All rights reserved. MIT license.

import UIKit

@IBDesignable
final class CloseButton: UIButton {
    override var isHighlighted: Bool { didSet { setNeedsDisplay() } }
    override var isSelected: Bool { didSet { setNeedsDisplay() } }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        render()
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        render()
    }

    func render() {
        self.backgroundColor = .clear
    }

    override func draw(_ rect: CGRect) {
        func p(_ p: CGFloat) -> CGFloat {
            return p * (2.0 / 3.0)
        }

        guard let context = UIGraphicsGetCurrentContext() else { return }

        context.setLineWidth(p(1.0))

        let color = UIColor(displayP3Red: 0.76,
                            green: 0.77,
                            blue: 0.76,
                            alpha: 1.0)

        context.setFillColor(color.cgColor)

        context.beginPath()
        context.addArc(center: CGPoint(x: rect.width * 0.5,
                                       y: rect.height * 0.5),
                       radius: p(36.0) * 0.5,
                       startAngle: 0,
                       endAngle: CGFloat.pi * 2.0,
                       clockwise: true)
        context.fillPath()

        let highlightedColor = UIColor(displayP3Red: 0.53,
                                       green: 0.53,
                                       blue: 0.53,
                                       alpha: 1.0)

        let crossColor: UIColor = isHighlighted || isSelected ? highlightedColor : .white
        context.setStrokeColor(crossColor.cgColor)
        context.setBlendMode(.normal)
        context.setLineWidth(p(3.5))
        context.setLineCap(.round)

        let offset = (rect.width - p(36.0)) * 0.5

        context.beginPath()
        context.addLines(between: [CGPoint(x: offset + p(12.0), y: offset + p(12.0)),
                                   CGPoint(x: offset + p(24.0), y: offset + p(24.0))])
        context.strokePath()

        context.beginPath()
        context.addLines(between: [CGPoint(x: offset +  p(24.0), y: offset + p(12.0)),
                                   CGPoint(x: offset + p(12.0), y: offset + p(24.0))])
        context.strokePath()
    }
}

@IBDesignable
final class SafeAreaView: UIView {
    override func prepareForInterfaceBuilder() {
        let label = UILabel()
        label.text = "Safe Area"
        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: -4.0),
            ])
    }
}


@IBDesignable
final class OnSafeAreaView: UIView {
    override func prepareForInterfaceBuilder() {
        let label = UILabel()
        label.text = "On Safe Area"
        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: -4.0),
            ])
    }
}
