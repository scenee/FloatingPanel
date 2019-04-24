//
//  Copyright © 2018 Shin Yamamoto. All rights reserved.
//

import UIKit
import UIKit.UIGestureRecognizerSubclass // For Xcode 9.4.1

///
/// FloatingPanel presentation model
///
class FloatingPanel: NSObject, UIGestureRecognizerDelegate, UIScrollViewDelegate {
    // MUST be a weak reference to prevent UI freeze on the presentation modally
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

    private(set) var state: FloatingPanelPosition = .hidden {
        didSet { viewcontroller.delegate?.floatingPanelDidChangePosition(viewcontroller) }
    }

    private var isBottomState: Bool {
        let remains = layoutAdapter.supportedPositions.filter { $0.rawValue > state.rawValue }
        return remains.count == 0
    }

    let panGestureRecognizer: FloatingPanelPanGestureRecognizer
    var isRemovalInteractionEnabled: Bool = false

    fileprivate var animator: UIViewPropertyAnimator? {
        didSet {
            // This intends to avoid `tableView(_:didSelectRowAt:)` not being
            // called on first tap after the moving animation, but it doesn't
            // seem to be enough. The same issue happens on Apple Maps so it
            // might be an issue in `UITableView`.
            scrollView?.isUserInteractionEnabled = (animator == nil)
        }
    }

    private var initialFrame: CGRect = .zero
    private var initialTranslationY: CGFloat = 0
    private var initialLocation: CGPoint = .nan

    var interactionInProgress: Bool = false
    var isDecelerating: Bool = false

    // Scroll handling
    private var initialScrollOffset: CGPoint = .zero
    private var initialScrollFrame: CGRect = .zero
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

        panGestureRecognizer = FloatingPanelPanGestureRecognizer()

        if #available(iOS 11.0, *) {
            panGestureRecognizer.name = "FloatingPanelSurface"
        }

        super.init()

        panGestureRecognizer.floatingPanel = self

        surfaceView.addGestureRecognizer(panGestureRecognizer)
        panGestureRecognizer.addTarget(self, action: #selector(handle(panGesture:)))
        panGestureRecognizer.delegate = self
    }

    func move(to: FloatingPanelPosition, animated: Bool, completion: (() -> Void)? = nil) {
        move(from: state, to: to, animated: animated, completion: completion)
    }

    private func move(from: FloatingPanelPosition, to: FloatingPanelPosition, animated: Bool, completion: (() -> Void)? = nil) {
        if state != layoutAdapter.topMostState {
            lockScrollView()
        }
        tearDownActiveInteraction()

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
                guard let `self` = self else { return }

                self.state = to
                self.updateLayout(to: to)
            }
            animator.addCompletion { [weak self] _ in
                guard let `self` = self else { return }
                self.animator = nil
                completion?()
            }
            self.animator = animator
            animator.startAnimation()
        } else {
            self.state = to
            self.updateLayout(to: to)
            completion?()
        }
    }

    // MARK: - Layout update

    private func updateLayout(to target: FloatingPanelPosition) {
        self.layoutAdapter.activateLayout(of: target)
    }

    private func getBackdropAlpha(with translation: CGPoint) -> CGFloat {
        let currentY = surfaceView.frame.minY

        let next = directionalPosition(at: currentY, with: translation)
        let pre = redirectionalPosition(at: currentY, with: translation)
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
        guard gestureRecognizer == panGestureRecognizer else { return false }

        /* log.debug("shouldRecognizeSimultaneouslyWith", otherGestureRecognizer) */

        if viewcontroller.delegate?.floatingPanel(viewcontroller, shouldRecognizeSimultaneouslyWith: otherGestureRecognizer) ?? false {
            return true
        }

        switch otherGestureRecognizer {
        case is UIPanGestureRecognizer,
             is UISwipeGestureRecognizer,
             is UIRotationGestureRecognizer,
             is UIScreenEdgePanGestureRecognizer,
             is UIPinchGestureRecognizer:
            // all gestures of the tracking scroll view should be recognized in parallel
            // and handle them in self.handle(panGesture:)
            return scrollView?.gestureRecognizers?.contains(otherGestureRecognizer) ?? false
        default:
            // Should always recognize tap/long press gestures in parallel
            return true
        }
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer == panGestureRecognizer else { return false }
        /* log.debug("shouldBeRequiredToFailBy", otherGestureRecognizer) */
        return false
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer == panGestureRecognizer else { return false }

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
            // Should begin the pan gesture without waiting tap/long press gestures fail
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
    @objc func handle(panGesture: UIPanGestureRecognizer) {
        let velocity = panGesture.velocity(in: panGesture.view)

        switch panGesture {
        case scrollView?.panGestureRecognizer:
            guard let scrollView = scrollView else { return }

            let location = panGesture.location(in: surfaceView)

            let belowTop = surfaceView.frame.minY > layoutAdapter.topY

            log.debug("scroll gesture(\(state):\(panGesture.state)) --",
                "belowTop = \(belowTop),",
                "interactionInProgress = \(interactionInProgress),",
                "scroll offset = \(scrollView.contentOffset.y),",
                "location = \(location.y), velocity = \(velocity.y)")

            if belowTop {
                // Scroll offset pinning
                if state == layoutAdapter.topMostState {
                    if interactionInProgress {
                        log.debug("settle offset --", initialScrollOffset.y)
                        scrollView.setContentOffset(initialScrollOffset, animated: false)
                    } else {
                        if grabberAreaFrame.contains(location) {
                            // Preserve the current content offset in moving from full.
                            scrollView.setContentOffset(initialScrollOffset, animated: false)
                        } else {
                            let offset = scrollView.contentOffset.y - scrollView.contentOffsetZero.y
                            if offset < 0 {
                                fitToBounds(scrollView: scrollView)
                                let translation = panGesture.translation(in: panGestureRecognizer.view!.superview)
                                startInteraction(with: translation, at: location)
                            }
                        }
                    }
                } else {
                    scrollView.setContentOffset(initialScrollOffset, animated: false)
                }

                // Always hide a scroll indicator at the non-top.
                if interactionInProgress {
                    lockScrollView()
                }
            } else {
                // Always show a scroll indicator at the top.
                if interactionInProgress {
                    unlockScrollView()
                } else {
                    let offset = scrollView.contentOffset.y - scrollView.contentOffsetZero.y
                    if state == layoutAdapter.topMostState, offset < 0, velocity.y > 0 {
                        fitToBounds(scrollView: scrollView)
                        let translation = panGesture.translation(in: panGestureRecognizer.view!.superview)
                        startInteraction(with: translation, at: location)
                    }
                }
            }
        case panGestureRecognizer:
            let translation = panGesture.translation(in: panGestureRecognizer.view!.superview)
            let location = panGesture.location(in: panGesture.view)

            log.debug("panel gesture(\(state):\(panGesture.state)) --",
                "translation =  \(translation.y), location = \(location.y), velocity = \(velocity.y)")

            if let animator = self.animator {
                log.debug("panel animation interrupted!!!")
                // Prevent aborting touch events when the current animator is
                // released almost at a target position. Because any tap gestures
                // shouldn't be disturbed at the position.
                if fabs(surfaceView.frame.minY - layoutAdapter.topY) > 40.0 {
                    if animator.isInterruptible {
                        animator.stopAnimation(false)
                        animator.finishAnimation(at: .current)
                    }
                    self.animator = nil
                }

                // A user can stop a panel at the nearest Y of a target position
                if abs(surfaceView.frame.minY - layoutAdapter.topY) < 1.0 {
                    surfaceView.frame.origin.y = layoutAdapter.topY
                }
            }

            if interactionInProgress == false,
                viewcontroller.delegate?.floatingPanelShouldBeginDragging(viewcontroller) == false {
                return
            }

            if panGesture.state == .began {
                panningBegan(at: location)
                return
            }

            if shouldScrollViewHandleTouch(scrollView, point: location, velocity: velocity) {
                return
            }

            switch panGesture.state {
            case .changed:
                if interactionInProgress == false {
                    startInteraction(with: translation, at: location)
                }
                panningChange(with: translation)
            case .ended, .cancelled, .failed:
                panningEnd(with: translation, velocity: velocity)
            default:
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
            state == layoutAdapter.topMostState,   // When not top most(i.e. .full), don't scroll.
            interactionInProgress == false,        // When interaction already in progress, don't scroll.
            surfaceView.frame.minY == layoutAdapter.topY
        else {
            return false
        }

        // When the current and initial point within grabber area, do scroll.
        if grabberAreaFrame.contains(point), !grabberAreaFrame.contains(initialLocation) {
            return true
        }

        guard
            scrollView.frame.contains(initialLocation), // When initialLocation not in scrollView, don't scroll.
            !grabberAreaFrame.contains(point)           // When point within grabber area, don't scroll.
        else {
            return false
        }

        let offset = scrollView.contentOffset.y - scrollView.contentOffsetZero.y
        // The zero offset must be excluded because the offset is usually zero
        // after a panel moves from half/tip to full.
        if  offset > 0.0 {
            return true
        }
        if scrollView.isDecelerating {
            return true
        }
        if velocity.y <= 0 {
            return true
        }

        return false
    }

    private func panningBegan(at location: CGPoint) {
        // A user interaction does not always start from Began state of the pan gesture
        // because it can be recognized in scrolling a content in a content view controller.
        // So here just preserve the current state if needed.
        log.debug("panningBegan -- location = \(location.y)")
        initialLocation = location
        if state == layoutAdapter.topMostState {
            if let scrollView = scrollView {
                initialScrollFrame = scrollView.frame
            }
        } else {
            if let scrollView = scrollView {
                initialScrollOffset = scrollView.contentOffset
            }
        }
    }

    private func panningChange(with translation: CGPoint) {
        log.debug("panningChange -- translation = \(translation.y)")
        let pre = surfaceView.frame.minY
        let dy = translation.y - initialTranslationY

        layoutAdapter.updateInteractiveTopConstraint(diff: dy,
                                                     allowsTopBuffer: allowsTopBuffer(for: dy))

        backdropView.alpha = getBackdropAlpha(with: translation)
        preserveContentVCLayoutIfNeeded()

        let didMove = (pre != surfaceView.frame.minY)
        guard didMove else { return }

        viewcontroller.delegate?.floatingPanelDidMove(viewcontroller)
    }

    private func allowsTopBuffer(for translationY: CGFloat) -> Bool {
        let preY = surfaceView.frame.minY
        let nextY = initialFrame.offsetBy(dx: 0.0, dy: translationY).minY
        if let scrollView = scrollView, scrollView.panGestureRecognizer.state == .changed,
            preY > 0 && preY > nextY {
            return false
        } else {
            return true
        }
    }

    private var disabledBottomAutoLayout = false
    // Prevent stretching a view having a constraint to SafeArea.bottom in an overflow
    // from the full position because SafeArea is global in a screen.
    private func preserveContentVCLayoutIfNeeded() {
        // Must include topY
        if (surfaceView.frame.minY <= layoutAdapter.topY) {
            if !disabledBottomAutoLayout {
                viewcontroller.contentViewController?.view?.constraints.forEach({ (const) in
                    switch viewcontroller.contentViewController?.layoutGuide.bottomAnchor {
                    case const.firstAnchor:
                        (const.secondItem as? UIView)?.disableAutoLayout()
                        const.isActive = false
                    case const.secondAnchor:
                        (const.firstItem as? UIView)?.disableAutoLayout()
                        const.isActive = false
                    default:
                        break
                    }
                })
            }
            disabledBottomAutoLayout = true
        } else {
            if disabledBottomAutoLayout {
                viewcontroller.contentViewController?.view?.constraints.forEach({ (const) in
                    switch viewcontroller.contentViewController?.layoutGuide.bottomAnchor {
                    case const.firstAnchor:
                        (const.secondItem as? UIView)?.enableAutoLayout()
                        const.isActive = true
                    case const.secondAnchor:
                        (const.firstItem as? UIView)?.enableAutoLayout()
                        const.isActive = true
                    default:
                        break
                    }
                })
            }
            disabledBottomAutoLayout = false
        }
    }

    private func panningEnd(with translation: CGPoint, velocity: CGPoint) {
        log.debug("panningEnd -- translation = \(translation.y), velocity = \(velocity.y)")

        if state == .hidden {
            log.debug("Already hidden")
            return
        }

        stopScrollDeceleration = (surfaceView.frame.minY > layoutAdapter.topY) // Projecting the dragging to the scroll dragging or not
        if stopScrollDeceleration {
            DispatchQueue.main.async { [weak self] in
                guard let `self` = self else { return }
                self.stopScrollingWithDeceleration(at: self.initialScrollOffset)
            }
        }

        let targetPosition = self.targetPosition(with: velocity)
        let distance = self.distance(to: targetPosition)

        endInteraction(for: targetPosition)

        if isRemovalInteractionEnabled, isBottomState {
            let velocityVector = (distance != 0) ? CGVector(dx: 0,
                                                            dy: min(abs(velocity.y)/distance, behavior.removalVelocity)) : .zero

            if shouldStartRemovalAnimation(with: velocityVector) {

                viewcontroller.delegate?.floatingPanelDidEndDraggingToRemove(viewcontroller, withVelocity: velocity)
                self.startRemovalAnimation(with: velocityVector) { [weak self] in
                    guard let `self` = self else { return }
                    self.viewcontroller.dismiss(animated: false, completion: { [weak self] in
                        guard let `self` = self else { return }
                        self.viewcontroller.delegate?.floatingPanelDidEndRemove(self.viewcontroller)
                    })
                }
                return
            }
        }

        viewcontroller.delegate?.floatingPanelDidEndDragging(viewcontroller, withVelocity: velocity, targetPosition: targetPosition)

        // Workaround: Disable a tracking scroll to prevent bouncing a scroll content in a panel animating
        let isScrollEnabled = scrollView?.isScrollEnabled
        if let scrollView = scrollView, targetPosition != .full {
            scrollView.isScrollEnabled = false
        }

        startAnimation(to: targetPosition, at: distance, with: velocity)

        // Workaround: Reset `self.scrollView.isScrollEnabled`
        if let scrollView = scrollView, targetPosition != .full,
            let isScrollEnabled = isScrollEnabled {
            scrollView.isScrollEnabled = isScrollEnabled
        }
    }

    private func shouldStartRemovalAnimation(with velocityVector: CGVector) -> Bool {
        let posY = layoutAdapter.positionY(for: state)
        let currentY = surfaceView.frame.minY
        let bottomMaxY = layoutAdapter.bottomMaxY
        let vth = behavior.removalVelocity
        let pth = max(min(behavior.removalProgress, 1.0), 0.0)

        let num = (currentY - posY)
        let den = (bottomMaxY - posY)

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
            self.animator = nil
            completion?()
        })
        self.animator = animator
        animator.startAnimation()
    }

    private func startInteraction(with translation: CGPoint, at location: CGPoint) {
        /* Don't lock a scroll view to show a scroll indicator after hitting the top */
        log.debug("startInteraction  -- translation = \(translation.y), location = \(location.y)")
        guard interactionInProgress == false else { return }

        initialFrame = surfaceView.frame
        if state == layoutAdapter.topMostState, let scrollView = scrollView {
            if grabberAreaFrame.contains(location) {
                initialScrollOffset = scrollView.contentOffset
            } else {
                settle(scrollView: scrollView)
                initialScrollOffset = scrollView.contentOffsetZero
            }
            log.debug("initial scroll offset --", initialScrollOffset)
        }

        initialTranslationY = translation.y

        viewcontroller.delegate?.floatingPanelWillBeginDragging(viewcontroller)

        layoutAdapter.startInteraction(at: state)

        interactionInProgress = true
    }

    private func endInteraction(for targetPosition: FloatingPanelPosition) {
        log.debug("endInteraction to \(targetPosition)")

        if let scrollView = scrollView {
            log.debug("endInteraction -- scroll offset = \(scrollView.contentOffset)")
        }

        interactionInProgress = false

        // Prevent to keep a scroll view indicator visible at the half/tip position
        if state != layoutAdapter.topMostState {
            lockScrollView()
        }

        layoutAdapter.endInteraction(at: targetPosition)
    }

    private func tearDownActiveInteraction() {
        // Cancel the pan gesture so that panningEnd(with:velocity:) is called
        panGestureRecognizer.isEnabled = false
        panGestureRecognizer.isEnabled = true
    }

    private func startAnimation(to targetPosition: FloatingPanelPosition, at distance: CGFloat, with velocity: CGPoint) {
        log.debug("startAnimation to \(targetPosition) -- distance = \(distance), velocity = \(velocity.y)")

        isDecelerating = true
        viewcontroller.delegate?.floatingPanelWillBeginDecelerating(viewcontroller)

        let velocityVector = (distance != 0) ? CGVector(dx: 0, dy: min(abs(velocity.y)/distance, 30.0)) : .zero
        let animator = behavior.interactionAnimator(self.viewcontroller, to: targetPosition, with: velocityVector)
        animator.addAnimations { [weak self] in
            guard let `self` = self else { return }
            self.state = targetPosition
            self.updateLayout(to: targetPosition)
        }
        animator.addCompletion { [weak self] pos in
            guard let `self` = self else { return }
            self.finishAnimation(at: targetPosition)
        }
        self.animator = animator
        animator.startAnimation()
    }

    private func finishAnimation(at targetPosition: FloatingPanelPosition) {
        log.debug("finishAnimation to \(targetPosition)")

        self.isDecelerating = false
        self.animator = nil

        self.viewcontroller.delegate?.floatingPanelDidEndDecelerating(self.viewcontroller)

        if let scrollView = scrollView {
            log.debug("finishAnimation -- scroll offset = \(scrollView.contentOffset)")
        }

        stopScrollDeceleration = false
        // Don't unlock scroll view in animating view when presentation layer != model layer
        if state == layoutAdapter.topMostState {
            unlockScrollView()
        }
    }

    private func distance(to targetPosition: FloatingPanelPosition) -> CGFloat {
        let topY = layoutAdapter.topY
        let middleY = layoutAdapter.middleY
        let bottomY = layoutAdapter.bottomY
        let currentY = surfaceView.frame.minY

        switch targetPosition {
        case .full:
            return CGFloat(abs(currentY - topY))
        case .half:
            return CGFloat(abs(currentY - middleY))
        case .tip:
            return CGFloat(abs(currentY - bottomY))
        case .hidden:
            fatalError("Now .hidden must not be used for a user interaction")
        }
    }

    private func directionalPosition(at currentY: CGFloat, with translation: CGPoint) -> FloatingPanelPosition {
        return getPosition(at: currentY, with: translation, directional: true)
    }

    private func redirectionalPosition(at currentY: CGFloat, with translation: CGPoint) -> FloatingPanelPosition {
        return getPosition(at: currentY, with: translation, directional: false)
    }

    private func getPosition(at currentY: CGFloat, with translation: CGPoint, directional: Bool) -> FloatingPanelPosition {
        let supportedPositions: Set = layoutAdapter.supportedPositions
        if supportedPositions.count == 1 {
            return state
        }
        let isForwardYAxis = (translation.y >= 0)
        switch supportedPositions {
        case [.full, .half]:
            return (isForwardYAxis == directional) ? .half : .full
        case [.half, .tip]:
            return (isForwardYAxis == directional) ? .tip : .half
        case [.full, .tip]:
            return (isForwardYAxis == directional) ? .tip : .full
        default:
            let middleY = layoutAdapter.middleY
            if currentY > middleY {
                return (isForwardYAxis == directional) ? .tip : .half
            } else {
                return (isForwardYAxis == directional) ? .half : .full
            }
        }
    }

    // Distance travelled after decelerating to zero velocity at a constant rate.
    // Refer to the slides p176 of [Designing Fluid Interfaces](https://developer.apple.com/videos/play/wwdc2018/803/)
    private func project(initialVelocity: CGFloat, decelerationRate: CGFloat) -> CGFloat {
        return (initialVelocity / 1000.0) * decelerationRate / (1.0 - decelerationRate)
    }

    private func targetPosition(with velocity: CGPoint) -> (FloatingPanelPosition) {
        let currentY = surfaceView.frame.minY
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

            let nextState: FloatingPanelPosition
            let forwardYDirection: Bool

            /*
             full <-> half <-> tip
             */
            switch state {
            case .full:
                nextState = .half
                forwardYDirection = true
            case .half:
                nextState = (currentY > middleY) ? .tip : .full
                forwardYDirection = (currentY > middleY)
            case .tip:
                nextState = .half
                forwardYDirection = false
            case .hidden:
                fatalError("Now .hidden must not be used for a user interaction")
            }

            let redirectionalProgress = max(min(behavior.redirectionalProgress(viewcontroller, from: state, to: nextState), 1.0), 0.0)

            let th1: CGFloat
            let th2: CGFloat

            if forwardYDirection {
                th1 = topY + (middleY - topY) * redirectionalProgress
                th2 = middleY + (bottomY - middleY) * redirectionalProgress
            } else {
                th1 = middleY - (middleY - topY) * redirectionalProgress
                th2 = bottomY - (bottomY - middleY) * redirectionalProgress
            }

            let decelerationRate = behavior.momentumProjectionRate(viewcontroller)

            let baseY = abs(bottomY - topY)
            let vecY = velocity.y / baseY
            let pY = project(initialVelocity: vecY, decelerationRate: decelerationRate) * baseY + currentY

            switch currentY {
            case ..<th1:
                switch pY {
                case bottomY...:
                    return behavior.shouldProjectMomentum(viewcontroller, for: .tip) ? .tip : .half
                case middleY...:
                    return .half
                case topY...:
                    return .full
                default:
                    return .full
                }
            case ...middleY:
                switch pY {
                case bottomY...:
                    return behavior.shouldProjectMomentum(viewcontroller, for: .tip) ? .tip : .half
                case middleY...:
                    return .half
                case topY...:
                    return .half
                default:
                    return .full
                }
            case ..<th2:
                switch pY {
                case bottomY...:
                    return .tip
                case middleY...:
                    return .half
                case topY...:
                    return .half
                default:
                    return behavior.shouldProjectMomentum(viewcontroller, for: .full) ? .full : .half
                }
            default:
                switch pY {
                case bottomY...:
                    return .tip
                case middleY...:
                    return .tip
                case topY...:
                    return .half
                default:
                    return behavior.shouldProjectMomentum(viewcontroller, for: .full) ? .full : .half
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

        let decelerationRate = behavior.momentumProjectionRate(viewcontroller)
        let pY = project(initialVelocity: velocity.y, decelerationRate: decelerationRate) + currentY

        switch currentY {
        case ..<th:
            if pY >= bottomY {
                return bottom
            } else {
                return top
            }
        default:
            if pY <= topY {
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

    private func fitToBounds(scrollView: UIScrollView) {
        log.debug("fit scroll view to bounds -- scroll offset =", scrollView.contentOffset.y)

        surfaceView.frame.origin.y = layoutAdapter.topY - scrollView.contentOffset.y
        scrollView.transform = CGAffineTransform.identity.translatedBy(x: 0.0,
                                                                       y: scrollView.contentOffset.y)
        scrollView.scrollIndicatorInsets = UIEdgeInsets(top: -scrollView.contentOffset.y,
                                                        left: 0.0,
                                                        bottom: 0.0,
                                                        right: 0.0)
    }

    private func settle(scrollView: UIScrollView) {
        log.debug("settle scroll view")
        let frame = surfaceView.layer.presentation()?.frame ?? surfaceView.frame
        surfaceView.transform = .identity
        surfaceView.frame = frame
        scrollView.transform = .identity
        scrollView.frame = initialScrollFrame
        scrollView.contentOffset = scrollView.contentOffsetZero
        scrollView.scrollIndicatorInsets = .zero
    }


    private func stopScrollingWithDeceleration(at contentOffset: CGPoint) {
        // Must use setContentOffset(_:animated) to force-stop deceleration
        scrollView?.setContentOffset(contentOffset, animated: false)
    }
}

class FloatingPanelPanGestureRecognizer: UIPanGestureRecognizer {
    fileprivate weak var floatingPanel: FloatingPanel?
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        if floatingPanel?.animator != nil {
            self.state = .began
        }
    }
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
