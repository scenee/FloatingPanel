//
//  Created by Shin Yamamoto on 2018/09/26.
//  Copyright © 2018 Shin Yamamoto. All rights reserved.
//

import UIKit

class FloatingPanelSurfaceContentView: UIView {}

/// A view that presents a surface interface in a floating panel.
public class FloatingPanelSurfaceView: UIView {

    /// A GrabberHandleView object displayed at the top of the surface view
    public var grabberHandle: GrabberHandleView!

    /// The height of the grabber bar area
    public static var topGrabberBarHeight: CGFloat {
        return Default.grabberTopPadding * 2 + GrabberHandleView.Default.height // 17.0
    }

    /// A UIView object that can have the surface view added to it.
    public var contentView: UIView!

    private var color: UIColor? = .white { didSet { setNeedsDisplay() } }

    public override var backgroundColor: UIColor? {
        get { return color }
        set {
            color = newValue
            setNeedsDisplay()
        }
    }

    /// The radius to use when drawing rounded corners
    public var cornerRadius: CGFloat = 0.0 { didSet { setNeedsLayout() } }

    /// A Boolean indicating whether the surface shadow is displayed.
    public var shadowHidden: Bool = false  { didSet { setNeedsLayout() } }

    /// The color of the surface shadow.
    public var shadowColor: UIColor = .black  { didSet { setNeedsLayout() } }

    /// The offset (in points) of the surface shadow.
    public var shadowOffset: CGSize = CGSize(width: 0.0, height: 1.0)  { didSet { setNeedsLayout() } }

    /// The opacity of the surface shadow.
    public var shadowOpacity: Float = 0.2 { didSet { setNeedsLayout() } }

    /// The blur radius (in points) used to render the surface shadow.
    public var shadowRadius: CGFloat = 3  { didSet { setNeedsLayout() } }

    /// The width of the surface border.
    public var borderColor: UIColor?  { didSet { setNeedsLayout() } }

    /// The color of the surface border.
    public var borderWidth: CGFloat = 0.0  { didSet { setNeedsLayout() } }

    private var shadowLayer: CAShapeLayer!  { didSet { setNeedsLayout() } }

    private struct Default {
        public static let grabberTopPadding: CGFloat = 6.0
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        render()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        render()
    }

    private func render() {
        super.backgroundColor = .clear

        let contentView = FloatingPanelSurfaceContentView()
        addSubview(contentView)
        self.contentView = contentView as UIView
        // contentView.backgroundColor = .lightGray
        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: topAnchor, constant: 0.0),
            contentView.leftAnchor.constraint(equalTo: leftAnchor, constant: 0.0),
            contentView.rightAnchor.constraint(equalTo: rightAnchor, constant: 0.0),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0.0),
            ])

        let grabberHandle = GrabberHandleView()
        addSubview(grabberHandle)
        self.grabberHandle = grabberHandle

        grabberHandle.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            grabberHandle.topAnchor.constraint(equalTo: topAnchor, constant: Default.grabberTopPadding),
            grabberHandle.widthAnchor.constraint(equalToConstant: grabberHandle.frame.width),
            grabberHandle.heightAnchor.constraint(equalToConstant: grabberHandle.frame.height),
            grabberHandle.centerXAnchor.constraint(equalTo: centerXAnchor),
            ])
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        updateShadowLayer()
        // Don't use `contentView.layer.mask` because of UIVisualEffectView issue on ios10, https://forums.developer.apple.com/thread/50854
        contentView.layer.cornerRadius = cornerRadius
        contentView.clipsToBounds = true
        contentView.layer.borderColor = borderColor?.cgColor
        contentView.layer.borderWidth = borderWidth
    }

    private func updateShadowLayer() {
        if shadowLayer != nil {
            shadowLayer.removeFromSuperlayer()
        }
        shadowLayer = makeShadowLayer()
        layer.insertSublayer(shadowLayer, at: 0)
    }

    private func makeShadowLayer() -> CAShapeLayer {
        log.debug("SurfaceView bounds", bounds)
        let shadowLayer = CAShapeLayer()
        let path = UIBezierPath(roundedRect: bounds,
                                byRoundingCorners: [.topLeft, .topRight],
                                cornerRadii: CGSize(width: cornerRadius, height: cornerRadius))
        shadowLayer.path = path.cgPath
        shadowLayer.fillColor = color?.cgColor
        if shadowHidden == false {
            shadowLayer.shadowPath = shadowLayer.path
            shadowLayer.shadowColor = shadowColor.cgColor
            shadowLayer.shadowOffset = shadowOffset
            shadowLayer.shadowOpacity = shadowOpacity
            shadowLayer.shadowRadius = shadowRadius
        }
        return shadowLayer
    }
}
