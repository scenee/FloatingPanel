//
//  Copyright © 2018 Shin Yamamoto. All rights reserved.
//

import UIKit

///
/// FloatingPanel presentation model
///
class FloatingPanel: NSObject, UIGestureRecognizerDelegate, UIScrollViewDelegate {
    /* Cause 'terminating with uncaught exception of type NSException' error on Swift Playground
     unowned let view: UIView
     */
    let surfaceView: FloatingPanelSurfaceView
    let backdropView: FloatingPanelBackdropView
    var layoutAdapter: FloatingPanelLayoutAdapter
    var behavior: FloatingPanelBehavior

    weak var scrollView: UIScrollView? {
        didSet {
            guard let scrollView = scrollView else { return }
            scrollView.panGestureRecognizer.addTarget(self, action: #selector(handle(panGesture:)))
            scrollBouncable = scrollView.bounces
            scrollIndictorVisible = scrollView.showsVerticalScrollIndicator
        }
    }
    weak var userScrollViewDelegate: UIScrollViewDelegate?

    var safeAreaInsets: UIEdgeInsets! {
        get { return layoutAdapter.safeAreaInsets }
        set { layoutAdapter.safeAreaInsets = newValue }
    }

    unowned let viewcontroller: FloatingPanelController

    private(set) var state: FloatingPanelPosition = .tip

    private var animator: UIViewPropertyAnimator?
    private let panGesture: UIPanGestureRecognizer
    private var initialFrame: CGRect = .zero
    private var transOffsetY: CGFloat = 0
    private var interactionInProgress: Bool = false

    // Scroll handling
    private var stopScrollDeceleration: Bool = false
    private var scrollBouncable = false
    private var scrollIndictorVisible = false

    // MARK: - Interface

    init(_ vc: FloatingPanelController, layout: FloatingPanelLayout, behavior: FloatingPanelBehavior) {
        viewcontroller = vc
        surfaceView = vc.view as! FloatingPanelSurfaceView
        backdropView = FloatingPanelBackdropView()
        backdropView.backgroundColor = .black
        backdropView.alpha = 0.0

        self.layoutAdapter = FloatingPanelLayoutAdapter(surfaceView: surfaceView,
                                                        backdropView: backdropView,
                                                        layout: layout)
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
        if to != .full {
            lockScrollView()
        }

        if animated {
            let animator = behavior.presentAnimator(from: state, to: to)
            animator.addAnimations { [weak self] in
                guard let self = self else { return }

                self.updateLayout(to: to)
                self.state = to
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
                guard let self = self else { return }

                self.updateLayout(to: nil)
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

    // MARK: - Layout update

    private func updateLayout(to target: FloatingPanelPosition?) {
        self.layoutAdapter.activateLayout(of: target)
        self.setBackdropAlpha(of: target)
    }

    private func setBackdropAlpha(of target: FloatingPanelPosition?) {
        switch target {
        case .full?:
            self.backdropView.alpha = layoutAdapter.layout.backdropAlpha
        default:
            self.backdropView.alpha = 0.0
        }
    }

    private func getBackdropAlpha(with translation: CGPoint) -> CGFloat {
        let topY = layoutAdapter.topY
        let middleY = layoutAdapter.middleY
        let currentY = getCurrentY(from: initialFrame, with: translation)
        return (1 - (currentY - topY) / (middleY - topY)) * layoutAdapter.layout.backdropAlpha
    }

    // MARK: - UIGestureRecognizerDelegate

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                  shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer == panGesture else { return false }

        log.debug("shouldRecognizeSimultaneouslyWith", otherGestureRecognizer)

        return otherGestureRecognizer == scrollView?.panGestureRecognizer
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer == panGesture else { return false }

        // Do not begin any gestures excluding scrollView?.panGestureRecognizer until the pan gesture fails
        if otherGestureRecognizer == scrollView?.panGestureRecognizer {
            return false
        } else {
            return true
        }
    }

    // MARK: - Gesture handling

    @objc func handle(panGesture: UIPanGestureRecognizer) {
        log.debug("Gesture >>>>", panGesture)

        switch panGesture {
        case scrollView?.panGestureRecognizer:
            guard let scrollView = scrollView else { return }
            if surfaceView.frame.minY > layoutAdapter.topY {
                scrollView.contentOffset.y = scrollView.contentOffsetZero.y
            }
        case panGesture:
            let translation = panGesture.translation(in: panGesture.view!.superview)
            let velocity = panGesture.velocity(in: panGesture.view)
            let location = panGesture.location(in: panGesture.view)

            if let scrollView = scrollView, scrollView.frame.contains(location) {
                log.debug("ScrollView.contentOffset >>>", scrollView.contentOffset)
                if state == .full {
                    if scrollView.contentOffset.y - scrollView.contentOffsetZero.y > 0 {
                        return
                    }
                    if scrollView.isDecelerating {
                        return
                    }
                    if interactionInProgress == false, velocity.y < 0 {
                        return
                    }
                }
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
        default:
            return
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

        let currentY = getCurrentY(from: initialFrame, with: translation)

        var frame = initialFrame
        frame.origin.y = currentY
        surfaceView.frame = frame
        backdropView.alpha = getBackdropAlpha(with: translation)

        viewcontroller.delegate?.floatingPanelDidMove(viewcontroller)
    }

    private func panningEnd(with translation: CGPoint, velocity: CGPoint) {
        log.debug("panningEnd")
        if interactionInProgress == false {
            initialFrame = surfaceView.frame
        }

        stopScrollDeceleration = (surfaceView.frame.minY > layoutAdapter.topY) // Projecting the dragging to the scroll dragging

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

        lockScrollView()

        interactionInProgress = true
    }

    private func endInteraction(for targetPosition: FloatingPanelPosition) {
        log.debug("endInteraction for \(targetPosition)")
        if targetPosition != .full {
            lockScrollView(withBounce: true)
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

        if let scrollView = scrollView, scrollView.panGestureRecognizer.state == .changed {
            let preY = surfaceView.frame.origin.y
            if preY > 0 && preY > y {
                return max(topY, min(bottomY, y))
            }
        }
        return max(topY - topInset + topBuffer, min(bottomY + bottomBuffer, y))
    }

    private func startAnimation(to targetPosition: FloatingPanelPosition, at distance: CGFloat, with velocity: CGPoint) {
        let targetY = layoutAdapter.positionY(for: targetPosition)
        let velocityVector = (distance != 0) ? CGVector(dx: 0, dy: max(min(velocity.y/distance, 30.0), -30.0)) : .zero
        let animator = behavior.interactionAnimator(to: targetPosition, with: velocityVector)
        animator.isInterruptible = false // To prevent a backdrop color's punk
        animator.addAnimations { [weak self] in
            guard let self = self else { return }
            if self.state == targetPosition {
                self.surfaceView.frame.origin.y = targetY
                self.setBackdropAlpha(of: targetPosition)
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

        // Don't unlock scroll view in animating view when presentation layer != model layer
        unlockScrollView()
    }

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

    // MARK: - ScrollView handling

    func lockScrollView(withBounce bounce: Bool = false) {
        guard let scrollView = scrollView else { return }

        scrollView.isDirectionalLockEnabled = true
        if bounce {
            scrollView.bounces = false
        }
        scrollView.showsVerticalScrollIndicator = false
    }

    func unlockScrollView() {
        guard let scrollView = scrollView else { return }

        scrollView.isDirectionalLockEnabled = false
        scrollView.bounces = scrollBouncable
        scrollView.showsVerticalScrollIndicator = scrollIndictorVisible
    }


    // MARK: - UIScrollViewDelegate Intermediation
    override func responds(to aSelector: Selector!) -> Bool {
        return super.responds(to: aSelector) || userScrollViewDelegate?.responds(to: aSelector) == true
    }

    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        if userScrollViewDelegate?.responds(to: aSelector) == true {
            return userScrollViewDelegate
        } else {
            return super.forwardingTarget(for: aSelector)
        }
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if stopScrollDeceleration {
            targetContentOffset.pointee = scrollView.contentOffset
            stopScrollDeceleration = false
        } else {
            userScrollViewDelegate?.scrollViewWillEndDragging?(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
        }
    }
}
