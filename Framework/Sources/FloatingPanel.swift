//
//  Copyright © 2018 Shin Yamamoto. All rights reserved.
//

import UIKit

///
/// FloatingPanel presentation model
///
class FloatingPanel: NSObject, UIGestureRecognizerDelegate, UIScrollViewDelegate {
    // MUST be a weak reference to prevent UI freeze on the presentaion modally
    weak var viewcontroller: FloatingPanelController!

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

    private(set) var state: FloatingPanelPosition = .hidden {
        didSet { viewcontroller.delegate?.floatingPanelDidChangePosition(viewcontroller) }
    }

    private var isBottomState: Bool {
        let remains = layoutAdapter.supportedPositions.filter { $0.rawValue > state.rawValue }
        return remains.count == 0
    }

    let panGesture: FloatingPanelPanGestureRecognizer
    var isRemovalInteractionEnabled: Bool = false

    private var animator: UIViewPropertyAnimator?
    private var initialFrame: CGRect = .zero
    private var initialScrollOffset: CGPoint = .zero
    private var initialScrollInset: UIEdgeInsets = .zero
    private var transOffsetY: CGFloat = 0

    var interactionInProgress: Bool = false

    // Scroll handling
    private var stopScrollDeceleration: Bool = false
    private var scrollBouncable = false
    private var scrollIndictorVisible = false

    // MARK: - Interface

    init(_ vc: FloatingPanelController, layout: FloatingPanelLayout, behavior: FloatingPanelBehavior) {
        viewcontroller = vc

        surfaceView = FloatingPanelSurfaceView()
        surfaceView.backgroundColor = .white

        backdropView = FloatingPanelBackdropView()
        backdropView.backgroundColor = .black
        backdropView.alpha = 0.0

        self.layoutAdapter = FloatingPanelLayoutAdapter(surfaceView: surfaceView,
                                                        backdropView: backdropView,
                                                        layout: layout)
        self.behavior = behavior

        panGesture = FloatingPanelPanGestureRecognizer()

        if #available(iOS 11.0, *) {
            panGesture.name = "FloatingPanelSurface"
        }

        super.init()

        surfaceView.addGestureRecognizer(panGesture)
        panGesture.addTarget(self, action: #selector(handle(panGesture:)))
        panGesture.delegate = self
    }

    func move(to: FloatingPanelPosition, animated: Bool, completion: (() -> Void)? = nil) {
        move(from: state, to: to, animated: animated, completion: completion)
    }

    private func move(from: FloatingPanelPosition, to: FloatingPanelPosition, animated: Bool, completion: (() -> Void)? = nil) {
        if to != .full {
            lockScrollView()
        }

        if animated {
            let animator: UIViewPropertyAnimator
            switch (from, to) {
            case (.hidden, let to):
                animator = behavior.addAnimator(self.viewcontroller, to: to)
            case (let from, .hidden):
                animator = behavior.removeAnimator(self.viewcontroller, from: from)
            case (let from, let to):
                animator = behavior.moveAnimator(self.viewcontroller, from: from, to: to)
            }

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

    // MARK: - Layout update

    private func updateLayout(to target: FloatingPanelPosition) {
        self.layoutAdapter.activateLayout(of: target)
    }

    private func getBackdropAlpha(with translation: CGPoint) -> CGFloat {
        let currentY = getCurrentY(from: initialFrame, with: translation)

        let next = directionalPosition(with: translation)
        let pre = redirectionalPosition(with: translation)
        let nextY = layoutAdapter.positionY(for: next)
        let preY = layoutAdapter.positionY(for: pre)

        let nextAlpha = layoutAdapter.layout.backdropAlphaFor(position: next)
        let preAlpha = layoutAdapter.layout.backdropAlphaFor(position: pre)

        if preY == nextY {
            return preAlpha
        } else {
            return preAlpha + max(min(1.0, 1.0 - (nextY - currentY) / (nextY - preY) ), 0.0) * (nextAlpha - preAlpha)
        }
    }

    // MARK: - UIGestureRecognizerDelegate

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                  shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer == panGesture else { return false }

        /* log.debug("shouldRecognizeSimultaneouslyWith", otherGestureRecognizer) */

        if viewcontroller.delegate?.floatingPanel(viewcontroller, shouldRecognizeSimultaneouslyWith: otherGestureRecognizer) ?? false {
            return true
        }

        // all gestures of the tracking scroll view should be recognized in parallel
        // and handle them in self.handle(panGesture:)
        return scrollView?.gestureRecognizers?.contains(otherGestureRecognizer) ?? false
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer == panGesture else { return false }
        /* log.debug("shouldBeRequiredToFailBy", otherGestureRecognizer) */
        return false
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer == panGesture else { return false }

        /* log.debug("shouldRequireFailureOf", otherGestureRecognizer) */

        // Should begin the pan gesture without waiting for the tracking scroll view's gestures.
        // `scrollView.gestureRecognizers` can contains the following gestures
        // * UIScrollViewDelayedTouchesBeganGestureRecognizer
        // * UIScrollViewPanGestureRecognizer (scrollView.panGestureRecognizer)
        // * _UIDragAutoScrollGestureRecognizer
        // * _UISwipeActionPanGestureRecognizer
        // * UISwipeDismissalGestureRecognizer
        if let scrollView = scrollView {
            // On short contents scroll, `_UISwipeActionPanGestureRecognizer` blocks
            // the panel's pan gesture if not returns false
            if let scrollGestureRecognizers = scrollView.gestureRecognizers,
                scrollGestureRecognizers.contains(otherGestureRecognizer) {
                return false
            }
        }

        if viewcontroller.delegate?.floatingPanel(viewcontroller, shouldRecognizeSimultaneouslyWith: otherGestureRecognizer) ?? false {
            return false
        }


        switch otherGestureRecognizer {
        case is UIPanGestureRecognizer,
             is UISwipeGestureRecognizer,
             is UIRotationGestureRecognizer,
             is UIScreenEdgePanGestureRecognizer,
             is UIPinchGestureRecognizer:
            // Do not begin the pan gesture until these gestures fail
            return true
        default:
            // Should begin the pan gesture witout waiting tap/long press gestures fail
            return false
        }
    }

    var grabberAreaFrame: CGRect {
        let grabberAreaFrame = CGRect(x: surfaceView.bounds.origin.x,
                                     y: surfaceView.bounds.origin.y,
                                     width: surfaceView.bounds.width,
                                     height: FloatingPanelSurfaceView.topGrabberBarHeight * 2)
        return grabberAreaFrame
    }

    // MARK: - Gesture handling
    private let offsetThreshold: CGFloat = 5.0 // Optimal value from testing
    @objc func handle(panGesture: UIPanGestureRecognizer) {
        log.debug("Gesture >>>>", panGesture)
        let velocity = panGesture.velocity(in: panGesture.view)

        switch panGesture {
        case scrollView?.panGestureRecognizer:
            guard let scrollView = scrollView else { return }

            log.debug("SrollPanGesture ScrollView.contentOffset >>>", scrollView.contentOffset.y, scrollView.contentSize, scrollView.bounds.size)

            // Prevent scoll slip by the top bounce when the scroll view's height is
            // less than the content's height
            if scrollView.isDecelerating == false, scrollView.contentSize.height > scrollView.bounds.height {
                scrollView.bounces = (scrollView.contentOffset.y > offsetThreshold)
            }

            if surfaceView.frame.minY > layoutAdapter.topY {
                switch state {
                case .full:
                    let point = panGesture.location(in: surfaceView)
                    if grabberAreaFrame.contains(point) {
                        // Preserve the current content offset in moving from full.
                        scrollView.contentOffset.y = initialScrollOffset.y
                    } else {
                        // Prevent over scrolling in moving from full.
                        scrollView.contentOffset.y = scrollView.contentOffsetZero.y
                    }
                case .half, .tip:
                    guard scrollView.isDecelerating == false else {
                        // Don't fix the scroll offset in animating the panel to half and tip.
                        // It causes a buggy scrolling deceleration because `state` becomes
                        // a target position in animating the panel on the interaction from full.
                        return
                    }
                    // Fix the scroll offset in moving the panel from half and tip.
                    scrollView.contentOffset.y = initialScrollOffset.y + (initialScrollInset.top - scrollView.contentInset.top)
                case .hidden:
                    fatalError("A floating panel hidden must not be used by a user")
                }

                // Always hide a scroll indicator at the non-top.
                if interactionInProgress {
                    lockScrollView()
                }
            } else {
                // Always show a scroll indicator at the top.
                if interactionInProgress {
                    unlockScrollView()
                }
            }
        case panGesture:
            let translation = panGesture.translation(in: panGesture.view!.superview)
            let location = panGesture.location(in: panGesture.view)

            log.debug(panGesture.state, ">>>", "translation: \(translation.y), velocity: \(velocity.y)")

            if shouldScrollViewHandleTouch(scrollView, point: location, velocity: velocity) {
                return
            }

            if let animator = self.animator, animator.isInterruptible {
                animator.stopAnimation(true)
                self.animator = nil
            }

            switch panGesture.state {
            case .began:
                panningBegan()
            case .changed:
                if interactionInProgress == false {
                    startInteraction(with: translation)
                }
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

    private func shouldScrollViewHandleTouch(_ scrollView: UIScrollView?, point: CGPoint, velocity: CGPoint) -> Bool {
        // When no scrollView, nothing to handle.
        guard let scrollView = scrollView else { return false }

        // For _UISwipeActionPanGestureRecognizer
        if let scrollGestureRecognizers = scrollView.gestureRecognizers {
            for gesture in scrollGestureRecognizers {
                guard gesture.state == .began || gesture.state == .changed
                else { continue }

                if gesture !=  scrollView.panGestureRecognizer {
                    return true
                }
            }
        }

        guard
            state == .full,                   // When not .full, don't scroll.
            interactionInProgress == false,   // When interaction already in progress, don't scroll.
            scrollView.frame.contains(point), // When point not in scrollView, don't scroll.
            !grabberAreaFrame.contains(point) // When point within grabber area, don't scroll.
        else {
            return false
        }

        log.debug("ScrollView.contentOffset >>>", scrollView.contentOffset.y)

        let offset = scrollView.contentOffset.y - scrollView.contentOffsetZero.y
        if  abs(offset) > offsetThreshold {
            return true
        }
        if scrollView.isDecelerating {
            return true
        }
        if velocity.y < 0 {
            return true
        }

        return false
    }

    private func panningBegan() {
        // A user interaction does not always start from Began state of the pan gesture
        // because it can be recognized in scrolling a content in a content view controller.
        // So do nothing here.
        log.debug("panningBegan")
    }

    private func panningChange(with translation: CGPoint) {
        log.debug("panningChange")

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

        stopScrollDeceleration = (surfaceView.frame.minY > layoutAdapter.topY) // Projecting the dragging to the scroll dragging or not

        let targetPosition = self.targetPosition(with: translation, velocity: velocity)
        let distance = self.distance(to: targetPosition, with: translation)

        endInteraction(for: targetPosition)

        if isRemovalInteractionEnabled, isBottomState {
            let velocityVector = (distance != 0) ? CGVector(dx: 0,
                                                            dy: max(min(velocity.y/distance, behavior.removalVelocity), 0.0)) : .zero



            if shouldStartRemovalAnimation(with: translation, velocityVector: velocityVector) {

                viewcontroller.delegate?.floatingPanelDidEndDraggingToRemove(viewcontroller, withVelocity: velocity)
                self.startRemovalAnimation(with: velocityVector) { [weak self] in
                    guard let self = self else { return }
                    self.viewcontroller.dismiss(animated: false, completion: { [weak self] in
                        guard let self = self else { return }
                        self.viewcontroller.delegate?.floatingPanelDidEndRemove(self.viewcontroller)
                    })
                }
                return
            }
        }

        viewcontroller.delegate?.floatingPanelDidEndDragging(viewcontroller, withVelocity: velocity, targetPosition: targetPosition)
        viewcontroller.delegate?.floatingPanelWillBeginDecelerating(viewcontroller)

        startAnimation(to: targetPosition, at: distance, with: velocity)
    }

    private func shouldStartRemovalAnimation(with translation: CGPoint, velocityVector: CGVector) -> Bool {
        let posY = layoutAdapter.positionY(for: state)
        let currentY = getCurrentY(from: initialFrame, with: translation)
        let safeAreaBottomY = layoutAdapter.safeAreaBottomY
        let vth = behavior.removalVelocity
        let pth = max(min(behavior.removalProgress, 1.0), 0.0)

        let num = (currentY - posY)
        let den = (safeAreaBottomY - posY)

        guard num >= 0, den != 0, (num / den >= pth || velocityVector.dy == vth)
        else { return false }

        return true
    }

    private func startRemovalAnimation(with velocityVector: CGVector, completion: (() -> Void)?) {
        let animator = self.behavior.removalInteractionAnimator(self.viewcontroller, with: velocityVector)

        animator.addAnimations { [weak self] in
            self?.updateLayout(to: .hidden)
        }
        animator.addCompletion({ _ in
            completion?()
        })
        animator.startAnimation()
    }

    private func startInteraction(with translation: CGPoint) {
        /* Don't lock a scroll view to show a scroll indicator after hitting the top */
        log.debug("startInteraction")
        initialFrame = surfaceView.frame
        if let scrollView = scrollView {
            initialScrollOffset = scrollView.contentOffset
            initialScrollInset = scrollView.contentInset
        }
        transOffsetY = translation.y

        viewcontroller.delegate?.floatingPanelWillBeginDragging(viewcontroller)

        viewcontroller.contentViewController?.view?.constraints.forEach({ (const) in
            switch viewcontroller.contentViewController?.layoutGuide.bottomAnchor {
            case const.firstAnchor:
                (const.secondItem as? UIView)?.disableAutoLayout()
            case const.secondAnchor:
                (const.firstItem as? UIView)?.disableAutoLayout()
            default:
                break
            }
        })

        interactionInProgress = true
    }

    private func endInteraction(for targetPosition: FloatingPanelPosition) {
        log.debug("endInteraction for \(targetPosition)")
        interactionInProgress = false

        // Prevent to keep a scoll view indicator visible at the half/tip position
        if targetPosition != .full {
            lockScrollView()
        }

        viewcontroller.contentViewController?.view?.constraints.forEach({ (const) in
            switch viewcontroller.contentViewController?.layoutGuide.bottomAnchor {
            case const.firstAnchor:
                (const.secondItem as? UIView)?.enableAutoLayout()
            case const.secondAnchor:
                (const.firstItem as? UIView)?.enableAutoLayout()
            default:
                break
            }
        })
    }

    private func getCurrentY(from rect: CGRect, with translation: CGPoint) -> CGFloat {
        let dy = translation.y - transOffsetY
        let y = rect.offsetBy(dx: 0.0, dy: dy).origin.y

        let topY = layoutAdapter.topY
        let topBuffer = layoutAdapter.layout.topInteractionBuffer
        let bottomY = layoutAdapter.bottomY
        let bottomBuffer = layoutAdapter.layout.bottomInteractionBuffer

        if let scrollView = scrollView, scrollView.panGestureRecognizer.state == .changed {
            let preY = surfaceView.frame.origin.y
            if preY > 0 && preY > y {
                return max(topY, min(bottomY, y))
            }
        }
        let topMax = layoutAdapter.topMaxY
        let bottomMax = layoutAdapter.bottomMaxY
        return max(max(topY - topBuffer, topMax), min(min(bottomY + bottomBuffer, bottomMax), y))
    }

    private func startAnimation(to targetPosition: FloatingPanelPosition, at distance: CGFloat, with velocity: CGPoint) {
        log.debug("startAnimation", targetPosition, distance, velocity)
        let targetY = layoutAdapter.positionY(for: targetPosition)
        let velocityVector = (distance != 0) ? CGVector(dx: 0, dy: max(min(velocity.y/distance, 30.0), -30.0)) : .zero
        let animator = behavior.interactionAnimator(self.viewcontroller, to: targetPosition, with: velocityVector)
        animator.addAnimations { [weak self] in
            guard let self = self else { return }
            if self.state == targetPosition {
                self.surfaceView.frame.origin.y = targetY
                self.layoutAdapter.setBackdropAlpha(of: targetPosition)
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

        stopScrollDeceleration = false
        // Don't unlock scroll view in animating view when presentation layer != model layer
        if targetPosition == .full {
            unlockScrollView()
        }
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
        case .hidden:
            fatalError("A floating panel hidden must not be used by a user")
        }
    }

    private func directionalPosition(with translation: CGPoint) -> FloatingPanelPosition {
        let currentY = getCurrentY(from: initialFrame, with: translation)

        let supportedPositions = layoutAdapter.supportedPositions

        if supportedPositions.count == 1 {
            return state
        }

        switch supportedPositions {
        case [.full, .half]: return translation.y >= 0 ? .half : .full
        case [.half, .tip]: return translation.y >= 0 ? .tip : .half
        case [.full, .tip]: return translation.y >= 0 ? .tip : .full
        default:
            let middleY = layoutAdapter.middleY

            switch state {
            case .full:
                if translation.y <= 0 {
                    return .full
                }
                return currentY > middleY ? .tip : .half
            case .half:
                return currentY > middleY ? .tip : .full
            case .tip:
                if translation.y >= 0 {
                    return .tip
                }
                return currentY > middleY ? .half : .full
            case .hidden:
                fatalError("A floating panel hidden must not be used by a user")
            }
        }
    }

    private func redirectionalPosition(with translation: CGPoint) -> FloatingPanelPosition {
        let currentY = getCurrentY(from: initialFrame, with: translation)

        let supportedPositions = layoutAdapter.supportedPositions

        if supportedPositions.count == 1 {
            return state
        }

        switch supportedPositions {
        case [.full, .half]: return translation.y >= 0 ? .full : .half
        case [.half, .tip]: return translation.y >= 0 ? .half : .tip
        case [.full, .tip]: return translation.y >= 0 ? .full : .tip
        default:
            let middleY = layoutAdapter.middleY

            switch state {
            case .full:
                return currentY > middleY ? .half : .full
            case .half:
                return .half
            case .tip:
                return currentY > middleY ? .tip : .half
            case .hidden:
                fatalError("A floating panel hidden must not be used by a user")
            }
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
        let supportedPositions = layoutAdapter.supportedPositions

        if supportedPositions.count == 1 {
            return state
        }

        switch supportedPositions {
        case [.full, .half]:
            return targetPosition(from: [.full, .half], at: currentY, velocity: velocity)
        case [.half, .tip]:
            return targetPosition(from: [.half, .tip], at: currentY, velocity: velocity)
        case [.full, .tip]:
            return targetPosition(from: [.full, .tip], at: currentY, velocity: velocity)
        default:
            /*
             [topY|full]---[th1]---[middleY|half]---[th2]---[bottomY|tip]
             */
            let topY = layoutAdapter.topY
            let middleY = layoutAdapter.middleY
            let bottomY = layoutAdapter.bottomY

            let target: FloatingPanelPosition
            let forwardYDirection: Bool

            switch state {
            case .full:
                target = .half
                forwardYDirection = true
            case .half:
                if (currentY < middleY) {
                    target = .full
                    forwardYDirection = false
                } else {
                    target = .tip
                    forwardYDirection = true
                }
            case .tip:
                target = .half
                forwardYDirection = false
            case .hidden:
                fatalError("A floating panel hidden must not be used by a user")
            }

            let redirectionalProgress = max(min(behavior.redirectionalProgress(viewcontroller, from: state, to: target), 1.0), 0.0)

            let th1: CGFloat
            let th2: CGFloat

            if forwardYDirection {
                th1 = topY + (middleY - topY) * redirectionalProgress
                th2 = middleY + (bottomY - middleY) * redirectionalProgress
            } else {
                th1 = middleY - (middleY - topY) * redirectionalProgress
                th2 = bottomY - (bottomY - middleY) * redirectionalProgress
            }

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

        let target = top == state ? bottom : top
        let redirectionalProgress = max(min(behavior.redirectionalProgress(viewcontroller, from: state, to: target), 1.0), 0.0)

        let th = topY + (bottomY - topY) * redirectionalProgress

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

    private func lockScrollView() {
        guard let scrollView = scrollView else { return }

        scrollView.isDirectionalLockEnabled = true
        scrollView.bounces = false
        scrollView.showsVerticalScrollIndicator = false
    }

    private func unlockScrollView() {
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

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        if state != .full {
            initialScrollOffset = scrollView.contentOffset
        }
        userScrollViewDelegate?.scrollViewDidEndScrollingAnimation?(scrollView)
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

class FloatingPanelPanGestureRecognizer: UIPanGestureRecognizer {
    override weak var delegate: UIGestureRecognizerDelegate? {
        get {
            return super.delegate
        }
        set {
            guard newValue is FloatingPanel else {
                let exception = NSException(name: .invalidArgumentException,
                                            reason: "FloatingPanelController's built-in pan gesture recognizer must have its controller as its delegate.",
                                            userInfo: nil)
                exception.raise()
                return
            }
            super.delegate = newValue
        }
    }
}
