// Copyright 2018-Present Shin Yamamoto. All rights reserved. MIT license.

import UIKit

// MARK: - CoreGraphics

extension CGFloat {
    /// Returns this value rounded to an logical pixel value by a display scale
    func rounded(by displayScale: CGFloat) -> CGFloat {
        return (self * displayScale).rounded(.toNearestOrAwayFromZero) / displayScale
    }
    func isEqual(to: CGFloat, on displayScale: CGFloat) -> Bool {
        return self.rounded(by: displayScale) == to.rounded(by: displayScale)
    }
}

extension CGPoint {
    static var leastNonzeroMagnitude: CGPoint {
        return CGPoint(x: CGFloat.leastNonzeroMagnitude, y: CGFloat.leastNonzeroMagnitude)
    }

    static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }

    static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }

    static prefix func - (point: CGPoint) -> CGPoint {
        return CGPoint(x: -point.x, y: -point.y)
    }
}

// MARK: - UIKit

protocol LayoutGuideProvider {
    var topAnchor: NSLayoutYAxisAnchor { get }
    var leftAnchor: NSLayoutXAxisAnchor { get }
    var bottomAnchor: NSLayoutYAxisAnchor { get }
    var rightAnchor: NSLayoutXAxisAnchor { get }
    var widthAnchor: NSLayoutDimension { get }
    var heightAnchor: NSLayoutDimension { get }
}
extension UILayoutGuide: LayoutGuideProvider {}
extension UIView: LayoutGuideProvider {}

private class CustomLayoutGuide: LayoutGuideProvider {
    let topAnchor: NSLayoutYAxisAnchor
    let leftAnchor: NSLayoutXAxisAnchor
    let bottomAnchor: NSLayoutYAxisAnchor
    let rightAnchor: NSLayoutXAxisAnchor
    let widthAnchor: NSLayoutDimension
    let heightAnchor: NSLayoutDimension
    init(topAnchor: NSLayoutYAxisAnchor,
         leftAnchor: NSLayoutXAxisAnchor,
         bottomAnchor: NSLayoutYAxisAnchor,
         rightAnchor: NSLayoutXAxisAnchor,
         widthAnchor: NSLayoutDimension,
         heightAnchor: NSLayoutDimension) {
        self.topAnchor = topAnchor
        self.leftAnchor = leftAnchor
        self.bottomAnchor = bottomAnchor
        self.rightAnchor = rightAnchor
        self.widthAnchor = widthAnchor
        self.heightAnchor = heightAnchor
    }
}

extension UIViewController {
    @objc var fp_safeAreaInsets: UIEdgeInsets {
        if #available(iOS 11.0, *) {
            return view.safeAreaInsets
        } else {
            return UIEdgeInsets(top: topLayoutGuide.length,
                                left: 0.0,
                                bottom: bottomLayoutGuide.length,
                                right: 0.0)
        }
    }

    var fp_safeAreaLayoutGuide: LayoutGuideProvider {
        if #available(iOS 11.0, *) {
            return view!.safeAreaLayoutGuide
        } else {
            return CustomLayoutGuide(topAnchor: topLayoutGuide.bottomAnchor,
                                     leftAnchor: view.leftAnchor,
                                     bottomAnchor: bottomLayoutGuide.topAnchor,
                                     rightAnchor: view.rightAnchor,
                                     widthAnchor: view.widthAnchor,
                                     heightAnchor: topLayoutGuide.bottomAnchor.anchorWithOffset(to: bottomLayoutGuide.topAnchor))
        }
    }
}

// The reason why UIView has no extensions of safe area insets and top/bottom guides
// is for iOS10 compatibility.
extension UIView {
    var fp_safeAreaLayoutGuide: LayoutGuideProvider {
        if #available(iOS 11.0, *) {
            return safeAreaLayoutGuide
        } else {
            return self
        }
    }

    var presentationFrame: CGRect {
        return layer.presentation()?.frame ?? frame
    }

    /// Returns non-zero displayScale
    ///
    /// On iOS 11 or earlier the `traitCollection.displayScale` of a view can be
    /// 0.0(indicating unspecified) when its view hasn't been added yet into a view tree in a window.
    /// So this method returns `UIScreen.main` scale if the scale value is zero, for testing mainly.
    var fp_displayScale: CGFloat {
        let ret = traitCollection.displayScale
        if ret == 0.0 {
            return UIScreen.main.scale
        }
        return ret
    }
}

extension UIView {
    func disableAutoLayout() {
        let frame = self.frame
        translatesAutoresizingMaskIntoConstraints = true
        self.frame = frame
    }
    func enableAutoLayout() {
        translatesAutoresizingMaskIntoConstraints = false
    }

    static func performWithLinear(startTime: Double = 0.0, relativeDuration: Double = 1.0, _ animations: @escaping (() -> Void)) {
        UIView.animateKeyframes(withDuration: 0.0, delay: 0.0, options: [.calculationModeCubic], animations: {
            UIView.addKeyframe(withRelativeStartTime: startTime, relativeDuration: relativeDuration, animations: animations)
        }, completion: nil)
    }
}

#if __FP_LOG
extension UIGestureRecognizer.State: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .began: return "began"
        case .changed: return "changed"
        case .failed: return "failed"
        case .cancelled: return "cancelled"
        case .ended: return "ended"
        case .possible: return "possible"
        @unknown default: return ""
        }
    }
}
#endif

extension UIScrollView {
    var isLocked: Bool {
        return !showsVerticalScrollIndicator && !bounces &&  isDirectionalLockEnabled
    }
    var fp_contentInset: UIEdgeInsets {
        if #available(iOS 11.0, *) {
            return adjustedContentInset
        } else {
            return contentInset
        }
    }
    var fp_contentOffsetMax: CGPoint {
        return CGPoint(x: max((contentSize.width + fp_contentInset.right) - bounds.width, 0.0),
                       y: max((contentSize.height + fp_contentInset.bottom) - bounds.height, 0.0))
    }
}

extension UISpringTimingParameters {
    public convenience init(decelerationRate: CGFloat, frequencyResponse: CGFloat, initialVelocity: CGVector = .zero) {
        let dampingRatio = CoreGraphics.log(decelerationRate) / (-4 * .pi * 0.001)
        self.init(dampingRatio: dampingRatio, frequencyResponse: frequencyResponse, initialVelocity: initialVelocity)
    }

    public convenience init(dampingRatio: CGFloat, frequencyResponse: CGFloat, initialVelocity: CGVector = .zero) {
        let mass = 1 as CGFloat
        let stiffness = pow(2 * .pi / frequencyResponse, 2) * mass
        let damp = 4 * .pi * dampingRatio * mass / frequencyResponse
        self.init(mass: mass, stiffness: stiffness, damping: damp, initialVelocity: initialVelocity)
    }
}

extension NSLayoutConstraint {
    static func activate(constraint: NSLayoutConstraint?) {
        guard let constraint = constraint else { return }
        self.activate([constraint])
    }
    static func deactivate(constraint: NSLayoutConstraint?) {
        guard let constraint = constraint else { return }
        self.deactivate([constraint])
    }
}

extension UIEdgeInsets {
    var horizontalInset: CGFloat {
        return self.left + self.right
    }
    var verticalInset: CGFloat {
        return self.top + self.bottom
    }
}

extension UIBezierPath {
    static func path(roundedRect rect: CGRect, appearance: SurfaceAppearance) -> UIBezierPath {
        let cornerRadius = appearance.cornerRadius;
        if #available(iOS 13.0, *) {
            if appearance.cornerCurve == .circular {
                let path = UIBezierPath()
                let start = CGPoint(x: rect.minX + cornerRadius, y: rect.minY)

                path.move(to: start)

                path.addLine(to: CGPoint(x: rect.maxX - cornerRadius, y: rect.minY))
                if cornerRadius > 0 {
                    path .addArc(withCenter: CGPoint(x: rect.maxX - cornerRadius,
                                                     y: rect.minY + cornerRadius),
                                 radius: cornerRadius,
                                 startAngle: -0.5 * .pi,
                                 endAngle: 0,
                                 clockwise: true)
                }

                path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cornerRadius))

                if cornerRadius > 0 {
                    path.addArc(withCenter: CGPoint(x: rect.maxX - cornerRadius,
                                                    y: rect.maxY - cornerRadius),
                                radius: cornerRadius,
                                startAngle: 0,
                                endAngle: .pi * 0.5,
                                clockwise: true)
                }

                path.addLine(to: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY))

                if cornerRadius > 0 {
                    path.addArc(withCenter: CGPoint(x: rect.minX + cornerRadius,
                                                    y: rect.maxY - cornerRadius),
                                radius: cornerRadius,
                                startAngle: .pi * 0.5,
                                endAngle: .pi,
                                clockwise: true)
                }

                path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + cornerRadius))

                if cornerRadius > 0 {
                    path.addArc(withCenter: CGPoint(x: rect.minX + cornerRadius,
                                                    y: rect.minY + cornerRadius),
                                radius: cornerRadius,
                                startAngle: .pi,
                                endAngle: .pi * 1.5,
                                clockwise: true)
                }

                path.addLine(to: start)

                path.close()

                return path
            }
        }
        return UIBezierPath(roundedRect: rect,
                            byRoundingCorners: [.allCorners],
                            cornerRadii: CGSize(width: cornerRadius,
                                                height: cornerRadius))
    }
}
