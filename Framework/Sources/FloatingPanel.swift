//
//  Copyright © 2018 scenee. All rights reserved.
//

import UIKit

///
/// FloatingPanel presentation model
///
class FloatingPanel: NSObject, UIGestureRecognizerDelegate {
    /* Cause 'terminating with uncaught exception of type NSException' error on Swift Playground
     unowned let view: UIView
     */
    let surfaceView: FloatingPanelSurfaceView
    let backdropView: FloatingPanelBackdropView

    private unowned let viewcontroller: FloatingPanelController

    weak var scrollView: UIScrollView? {
        didSet {
            configureScrollable()
        }
    }

    var safeAreaInsets: UIEdgeInsets! {
        get {
            return layoutAdapter.safeAreaInsets
        }
        set {
            layoutAdapter.safeAreaInsets = newValue
        }
    }

    private(set) var state: FloatingPanelPosition = .tip {
        didSet {
            switch state {
            case .full:
                backdropView.alpha = layoutAdapter.layout.backdropAlpha
            default:
                backdropView.alpha = 0.0
            }
            configureScrollable()
        }
    }

    var layoutAdapter: FloatingPanelLayoutAdapter
    var behavior: FloatingPanelBehavior
    private var animator: UIViewPropertyAnimator?
    private let panGesture: UIPanGestureRecognizer
    private var initialFrame: CGRect = .zero
    private var transOffsetY: CGFloat = 0
    private var interactionInProgress: Bool = false

    init(_ vc: FloatingPanelController, layout: FloatingPanelLayout, behavior: FloatingPanelBehavior) {
        viewcontroller = vc
        surfaceView = vc.view as! FloatingPanelSurfaceView
        backdropView = FloatingPanelBackdropView()
        backdropView.backgroundColor = .black
        backdropView.alpha = 0.0

        self.layoutAdapter = FloatingPanelLayoutAdapter(surfaceView: surfaceView, layout: layout)
        self.behavior = behavior

        panGesture = UIPanGestureRecognizer()

        if #available(iOS 11.0, *) {
            panGesture.name = "FloatingPanelSurface"
        }

        super.init()

        surfaceView.addGestureRecognizer(panGesture)
        panGesture.addTarget(self, action: #selector(handle(panGesture:)))
        panGesture.delegate = self
    }

    func layoutViews(in vc: UIViewController) {
        unowned let view = vc.view!

        view.insertSubview(backdropView, belowSubview: surfaceView)
        backdropView.frame = view.bounds

        layoutAdapter.prepareLayout(toParent: vc)
    }

    func move(to: FloatingPanelPosition, animated: Bool, completion: (() -> Void)? = nil) {
        if animated {
            let animator = behavior.presentAnimator(from: state, to: to)
            animator.addAnimations { [weak self] in
                self?.updateLayout(to: to)
                self?.state = to
            }
            animator.addCompletion { _ in
                completion?()
            }
            animator.startAnimation()
        } else {
            self.updateLayout(to: to)
            self.state = to
            completion?()
        }
    }

    func present(animated: Bool, completion: (() -> Void)? = nil) {
        self.layoutAdapter.activateLayout(of: nil)
        move(to: layoutAdapter.layout.initialPosition, animated: animated, completion: completion)
    }

    func dismiss(animated: Bool, completion: (() -> Void)? = nil) {
        if animated {
            let animator = behavior.dismissAnimator(from: state)
            animator.addAnimations { [weak self] in
                self?.updateLayout(to: nil)
            }
            animator.addCompletion { _ in
                completion?()
            }
            animator.startAnimation()
        } else {
            self.updateLayout(to: nil)
            completion?()
        }
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                  shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        log.debug("gestureRecognizer", gestureRecognizer,
              "shouldRecognizeSimultaneouslyWith", otherGestureRecognizer)
        if #available(iOS 11.0, *) {
            log.debug("gestureRecognizer",
                  String(describing: gestureRecognizer.name),
                  "shouldRecognizeSimultaneouslyWith",
                  String(describing: otherGestureRecognizer.name))
        }

        switch (gestureRecognizer, otherGestureRecognizer) {
        case (panGesture, scrollView?.panGestureRecognizer):
            return state == .full
        case (panGesture, is UIPanGestureRecognizer):
            return false
        default:
            return true
        }
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Do not begin any gestures until the pan gesture fails at non-full position.
        return gestureRecognizer == panGesture && state != .full
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    private func configureScrollable() {
        switch state {
        case .full:
            scrollView?.isScrollEnabled = true
        default:
            scrollView?.isScrollEnabled = false
        }
    }

    @objc func handle(panGesture: UIPanGestureRecognizer) {
        let translation = panGesture.translation(in: panGesture.view!.superview)
        let velocity = panGesture.velocity(in: panGesture.view)
        let location = panGesture.location(in: panGesture.view)

        if #available(iOS 11.0, *) {
            log.debug("Gesture >>>>", panGesture.name!)
        }
        if let scrollView = scrollView, scrollView.frame.contains(location), interactionInProgress == false {
            log.debug("ScrollView.contentOffset >>>", scrollView.contentOffset)
            if state == .full {
                if scrollView.contentOffset.y > scrollView.contentOffsetZero.y {
                    return
                }
                if scrollView.isDecelerating {
                    return
                }
                if interactionInProgress == false, velocity.y < 0 {
                    return
                }
            }
            scrollView.contentOffset.y = scrollView.contentOffsetZero.y
        }
        log.debug(panGesture.state, ">>>", "{ translation: \(translation), velocity: \(velocity) }")
        switch panGesture.state {
        case .began:
            panningBegan()
        case .changed:
            panningChange(with: translation)
        case .ended, .cancelled, .failed:
            panningEnd(with: translation, velocity: velocity)
        case .possible:
            break
        }
    }

    private func panningBegan() {
        // A user interaction does not always start from Began state of the pan gesture
        // because it can be recognized in scrolling a content in a content view controller.
        // So I don't nothing here.
        log.debug("panningBegan \(initialFrame)")
    }

    private func panningChange(with translation: CGPoint) {
        log.debug("panningChange")
        if interactionInProgress == false {
            startInteraction(with: translation)
        }
        var frame = initialFrame
        frame.origin.y = getCurrentY(from: initialFrame, with: translation)
        surfaceView.frame = frame
        viewcontroller.delegate?.floatingPanelDidMove(viewcontroller)
        backdropView.alpha = updateBackdropAlpha(with: translation)
    }

    private func panningEnd(with translation: CGPoint, velocity: CGPoint) {
        log.debug("panningEnd")
        if interactionInProgress == false {
            initialFrame = surfaceView.frame
        }

        let targetPosition = self.targetPosition(with: translation, velocity: velocity)
        let distance = self.distance(to: targetPosition, with: translation)

        endInteraction(for: targetPosition)
        viewcontroller.delegate?.floatingPanelDidEndDragging(viewcontroller, withVelocity: velocity, targetPosition: targetPosition)
        viewcontroller.delegate?.floatingPanelWillBeginDecelerating(viewcontroller)
        startAnimation(to: targetPosition, at: distance, with: velocity)
    }

    private func startInteraction(with translation: CGPoint) {
        log.debug("startInteraction")
        initialFrame = surfaceView.frame
        transOffsetY = translation.y
        viewcontroller.delegate?.floatingPanelWillBeginDragging(viewcontroller)
        if let scrollView = scrollView {
            scrollView.isScrollEnabled = false
        }

        interactionInProgress = true
    }

    private func endInteraction(for targetPosition: FloatingPanelPosition) {
        log.debug("endInteraction for \(targetPosition)")
        if let scrollView = scrollView {
            if targetPosition == .full {
                scrollView.isScrollEnabled = true
            }
        }
        interactionInProgress = false
    }

    private func getCurrentY(from rect: CGRect, with translation: CGPoint) -> CGFloat {
        let dy = translation.y - transOffsetY
        let y = rect.offsetBy(dx: 0.0, dy: dy).origin.y

        let topY = layoutAdapter.topY
        let topInset = layoutAdapter.topInset
        let topBuffer = layoutAdapter.layout.topInteractionBuffer

        let bottomY = layoutAdapter.bottomY
        let bottomBuffer = layoutAdapter.layout.bottomInteractionBuffer

        return max(topY - topInset + topBuffer,  min(bottomY + bottomBuffer, y))
    }

    private func startAnimation(to targetPosition: FloatingPanelPosition, at distance: CGFloat, with velocity: CGPoint) {
        let targetY = layoutAdapter.positionY(for: targetPosition)
        let velocityVector = (distance != 0) ? CGVector(dx: 0, dy: velocity.y/distance) : .zero
        let animator = behavior.interactionAnimator(to: targetPosition, with: velocityVector)
        animator.addAnimations { [weak self] in
            guard let self = self else { return }
            if self.state == targetPosition {
                self.surfaceView.frame.origin.y = targetY
            } else {
                self.updateLayout(to: targetPosition)
            }
            self.state = targetPosition
        }
        animator.addCompletion { [weak self] pos in
            guard let self = self else { return }
            guard
                self.interactionInProgress == false,
                animator == self.animator,
                pos == .end
                else { return }
            self.finishAnimation(at: targetPosition)
        }
        animator.startAnimation()
        self.animator = animator
    }

    private func finishAnimation(at targetPosition: FloatingPanelPosition) {
        log.debug("finishAnimation \(targetPosition)")
        self.animator = nil
        self.viewcontroller.delegate?.floatingPanelDidEndDecelerating(self.viewcontroller)
    }

    private func updateLayout(to target: FloatingPanelPosition?) {
        self.layoutAdapter.activateLayout(of: target)
    }

    private func updateBackdropAlpha(with translation: CGPoint) -> CGFloat {
        let topY = layoutAdapter.topY
        let middleY = layoutAdapter.middleY
        let currentY = getCurrentY(from: initialFrame, with: translation)
        return (1 - (currentY - topY) / (middleY - topY)) * layoutAdapter.layout.backdropAlpha
    }

    // Animation handling
    private func distance(to targetPosition: FloatingPanelPosition, with translation: CGPoint) -> CGFloat {
        let topY = layoutAdapter.topY
        let middleY = layoutAdapter.middleY
        let bottomY = layoutAdapter.bottomY
        let currentY = getCurrentY(from: initialFrame, with: translation)
        switch targetPosition {
        case .full:
            return CGFloat(fabs(Double(currentY - topY)))
        case .half:
            return CGFloat(fabs(Double(currentY - middleY)))
        case .tip:
            return CGFloat(fabs(Double(currentY - bottomY)))
        }
    }

    // Distance travelled after decelerating to zero velocity at a constant rate.
    // Refer to the slides p176 of [Designing Fluid Interfaces](https://developer.apple.com/videos/play/wwdc2018/803/)
    private func project(initialVelocity: CGFloat) -> CGFloat {
        let decelerationRate = UIScrollView.DecelerationRate.normal.rawValue
        return (initialVelocity / 1000.0) * decelerationRate / (1.0 - decelerationRate)
    }

    private func targetPosition(with translation: CGPoint, velocity: CGPoint) -> (FloatingPanelPosition) {
        let currentY = getCurrentY(from: initialFrame, with: translation)
        let supportedPositions = Set(layoutAdapter.layout.supportedPositions)

        assert(supportedPositions.count > 1)

        switch supportedPositions {
        case Set([.full, .half]):
            return targetPosition(from: [.half, .tip], at: currentY, velocity: velocity)
        case Set([.half, .tip]):
            return targetPosition(from: [.half, .tip], at: currentY, velocity: velocity)
        case Set([.full, .tip]):
            return targetPosition(from: [.full, .tip], at: currentY, velocity: velocity)
        default:
            /*
             [topY|full]---[th1]---[middleY|default]---[th2]---[bottomY|collapsed]
             */
            let topY = layoutAdapter.topY
            let middleY = layoutAdapter.middleY
            let bottomY = layoutAdapter.bottomY

            let th1 = (topY + middleY) / 2
            let th2 = (middleY + bottomY) / 2

            switch currentY {
            case ..<th1:
                if project(initialVelocity: velocity.y) >= (middleY - currentY) {
                    return .half
                } else {
                    return .full
                }
            case ...middleY:
                if project(initialVelocity: velocity.y) <= (topY - currentY) {
                    return .full
                } else {
                    return .half
                }
            case ..<th2:
                if project(initialVelocity: velocity.y) >= (bottomY - currentY) {
                    return .tip
                } else {
                    return .half
                }
            default:
                if project(initialVelocity: velocity.y) <= (middleY - currentY) {
                    return .half
                } else {
                    return .tip
                }
            }
        }
    }

    private func targetPosition(from positions: [FloatingPanelPosition], at currentY: CGFloat, velocity: CGPoint) -> FloatingPanelPosition {
        assert(positions.count == 2)

        let top = positions[0]
        let bottom = positions[1]

        let topY = layoutAdapter.positionY(for: top)
        let bottomY = layoutAdapter.positionY(for: bottom)

        let th = (topY + bottomY) / 2

        switch currentY {
        case ..<th:
            if project(initialVelocity: velocity.y) >= (bottomY - currentY) {
                return bottom
            } else {
                return top
            }
        default:
            if project(initialVelocity: velocity.y) <= (topY - currentY) {
                return top
            } else {
                return bottom
            }
        }
    }
}
