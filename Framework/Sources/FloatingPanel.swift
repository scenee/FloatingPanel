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

    // Animation handling
    private var alreadyMovedTranslationOfPan: CGPoint = CGPoint.zero
    private var totalYTranslation: CGFloat = CGFloat(0)
    private var nextState: FloatingPanelPosition = .tip

    // Scroll handling
    private var initialScrollOffset: CGPoint = .zero
    private var initialScrollFrame: CGRect = .zero
    private var stopScrollDeceleration: Bool = false
    private var scrollBouncable = false
    private var scrollIndictorVisible = false

    private var isScrollLocked: Bool = false

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
                self.unlockScrollView()
                completion?()
            }
            self.animator = animator
            animator.startAnimation()
        } else {
            self.state = to
            self.updateLayout(to: to)
            self.unlockScrollView()
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
            // Should recognize tap/long press gestures in parallel when the surface view is at an anchor position.
            let surfaceFrame = surfaceView.layer.presentation()?.frame ?? surfaceView.frame
            return surfaceFrame.minY == layoutAdapter.positionY(for: state)
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
                                     height: surfaceView.topGrabberBarHeight * 2)
        return grabberAreaFrame
    }

    // MARK: - Gesture handling
    @objc func handle(panGesture: UIPanGestureRecognizer) {
        // Direction of drag
        let velocity = panGesture.velocity(in: panGesture.view)
        // Vector of starting point of drag and current finger position on screen
        let translation = panGesture.translation(in: panGestureRecognizer.view!.superview)

        switch panGesture {
        case scrollView?.panGestureRecognizer:
            guard let scrollView = scrollView else { return }

            // Location of finger in surfaceView -> on the FloatingPanel
            let location = panGesture.location(in: surfaceView)

            log.debug("scroll gesture(\(state):\(panGesture.state)) --",
                "belowTop = \(!self.isFloatingPanelAtTopMostPosition()),",
                "interactionInProgress = \(interactionInProgress),",
                "scroll offset = \(scrollView.contentOffset.y),",
                "location = \(location.y), velocity = \(velocity.y)")

            if !self.isFloatingPanelAtTopMostPosition() {
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
                        startInteraction(with: translation, at: location)
                    }
                }
            }

        case panGestureRecognizer:
            let location = panGesture.location(in: panGesture.view)

            log.debug("panel gesture(\(state):\(panGesture.state)) --",
                "translation =  \(translation.y), location = \(location.y), velocity = \(velocity.y)")

            if interactionInProgress == false,
                viewcontroller.delegate?.floatingPanelShouldBeginDragging(viewcontroller) == false {
                return
            }

            if panGesture.state == .began {
                panningBegan(at: location, translation: translation, velocity: velocity)

                if self.state != self.layoutAdapter.topMostState {
                    self.animateFloatingPanel(with: velocity, translation: translation)
                }
                self.alreadyMovedTranslationOfPan = .zero

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

                if let scrollView = self.scrollView {
                    // Check the scrollView's contentOffset in order to determine whether or not to start a new animation
                    // This is necessary to ensure a new animation is not started when the floating panel is at the
                    // top but the scrollView is not.
                    if interactionInProgress && scrollView.contentOffset.y < CGFloat(0) && self.animator == nil {
                        self.alreadyMovedTranslationOfPan = translation
                        self.animateFloatingPanel(with: velocity, translation: translation)
                    }
                }

                panningChange(translation: translation, velocity: velocity)
            case .ended, .cancelled, .failed:
                panningEnd(with: translation, velocity: velocity)
            default:
                break
            }
        default:
            return
        }
    }

    private func animateFloatingPanel(with velocity: CGPoint, translation: CGPoint) {
        let targetPosition = self.nextPosition(with: velocity)
        let distance = self.distance(to: targetPosition)

        log.debug("startAnimation to \(targetPosition) -- distance = \(distance), velocity = \(velocity.y)")

        isDecelerating = true
        viewcontroller.delegate?.floatingPanelWillBeginDecelerating(viewcontroller)

        self.startNewAnimator(for: distance, with: velocity, movingTo: targetPosition)
    }

    private func isFloatingPanelAtTopMostPosition() -> Bool {
        guard let animator = self.animator else {
            return self.state == self.layoutAdapter.topMostState
        }

        return (
            // Moving panel to topMostState
            (self.nextState == self.layoutAdapter.topMostState && animator.fractionComplete >= 1)
            // Moving panel from topMostState
            || (self.state == self.layoutAdapter.topMostState && animator.fractionComplete <= 0)
        )
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

        guard self.isFloatingPanelAtTopMostPosition(), self.interactionInProgress else {
            return false
        }

        // When the current and initial point within grabber area, do scroll.
        if grabberAreaFrame.contains(point) && !grabberAreaFrame.contains(initialLocation) {
            return true
        }

        if !scrollView.frame.contains(initialLocation) && // When initialLocation not in scrollView, don't scroll.
             grabberAreaFrame.contains(point)            // When point within grabber area, don't scroll.
        {
            return false
        }

        let offset = scrollView.contentOffset.y - scrollView.contentOffsetZero.y
        // The zero offset must be excluded because the offset is usually zero
        // after a panel moves from half/tip to full.
        if  offset > 0.0 || scrollView.isDecelerating || velocity.y <= 0 {
            return true
        }

        return false
    }

    private func nextPosition(with velocity: CGPoint) -> FloatingPanelPosition {
        let isPanelMovingUpwards = velocity.y < CGFloat(0)

        switch self.state {
        case .full:
            return isPanelMovingUpwards ? .full : .half
        case .half:
            return isPanelMovingUpwards ? .full : .tip
        case .tip:
            if isPanelMovingUpwards {
                return .half
            }
            if self.layoutAdapter.supportedPositions.contains(.hidden) {
                return .hidden
            }

            return .tip
        case .hidden:
            guard isPanelMovingUpwards else {
                fatalError("Cannot move pannel downwards if already hidden!")
            }

            return .tip
        }
    }

    private func panningBegan(at location: CGPoint, translation: CGPoint, velocity: CGPoint) {
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

    private func panningChange(translation: CGPoint, velocity: CGPoint) {
        log.debug("panningChange -- translation = \(translation.y)")

        guard let animator = self.animator else {
            return
        }

        // Moving the finger upwards on the screen results in a negative Y translation. But since the animations are
        // defined to progress when moving from bottom to top, we have to negate the gesture recognizer translation
        // to get a positive animation completion fraction.
        var fraction = (-1 * (translation.y - self.alreadyMovedTranslationOfPan.y)) / self.totalYTranslation

        // In order to still use the correct value for the fraction (-> value between 0 and 1) when the panel is moved
        // downwards we need to multiply it by -1.
        if (self.state == .full && self.nextState == .half) || (self.state == .half && self.nextState == .tip) {
            fraction *= -1
        }

        // In order to still use the correct value for the fraction (-> value between 0 and 1) we need to multiply it
        // by -1 when the animator is reversed
        if animator.isReversed {
            fraction *= -1
        }

        let previousFractionComplete = animator.fractionComplete

        // Manually set the fractionComplete value of the animator so the progress of animator corresponds with the
        // drag on the floating panel as well as its current position on the screen.
        animator.fractionComplete = fraction

        // When the floating panel transitions from one state to another we need to also start a new animation.
        // Therefor, we need to check whether the currenlty running animator is either finished OR got back to its
        // starting point.
        // There are two cases here since the user could drag the panel eg. from .tip over .half to .full but change
        // directions midway between .half and .full and drag the panel back downards.
        if (animator.fractionComplete == 1) || (fraction < 0 && self.nextState != self.state) {
            self.state = (fraction < 0) ? self.state : self.nextState
            let newTargetState = self.nextPosition(with: velocity)
            let distance = self.distance(to: newTargetState)

            self.startNewAnimator(for: distance, with: velocity, movingTo: newTargetState)
            // Since the drag is already in progress we need 'save' the already travelled distance on the screen in
            // order to calculate the correct translation when calcualting the fraction (-> progress) of the animator.
            // Otherwise the panel 'jumps' from its current position to the finger's position on the screen.
            self.alreadyMovedTranslationOfPan = translation
        }

        self.preserveContentVCLayoutIfNeeded()
        // Determine whether or not the panel has actually moved.
        if animator.fractionComplete != previousFractionComplete {
            viewcontroller.delegate?.floatingPanelDidMove(viewcontroller)
        }
    }

    private func startNewAnimator(for distance: CGFloat, with velocity: CGPoint, movingTo targetState: FloatingPanelPosition) {
        let velocityVector = (distance != CGFloat(0)) ? CGVector(dx: 0, dy: min(abs(velocity.y)/distance, 30.0)) : .zero

        let animator = behavior.interactionAnimator(self.viewcontroller, between: self.state, and: targetState, with: velocityVector)
        animator.addAnimations { [weak self] in
            guard let `self` = self else { return }
            // Set layout (-> therefor the top constraint of the FloatingPanel) to the next upcoming state in order to
            // be able to move the panel during a drag
            self.updateLayout(to: targetState)
        }
        animator.addCompletion { [weak self] pos in
            guard let `self` = self else { return }
            if pos == .end && self.animator?.isReversed == false {
                self.state = self.nextState
            }
            // Set layout again to ensure that the panel's top constraint corresponds with the desired state.
            self.updateLayout(to: self.state)
            self.animationDidComplete(at: self.state)
        }

        self.animator = animator
        self.nextState = targetState

        // In order to make animators drag-dynamic we need to start and immediatly pause the animator aftwards.
        animator.startAnimation()
        animator.pauseAnimation()

        // Calculate the total distance the floating panel has to move between its current state and its next state.
        // Depending on the direction of the drag we need turn the calcualtion around in order to still get a positive
        // value for totalYTranslation.
        if velocity.y < CGFloat(0) {
            self.totalYTranslation = abs(self.layoutAdapter.positionY(for: self.state) - self.layoutAdapter.positionY(for: nextState))
        } else if velocity.y > CGFloat(0) {
            self.totalYTranslation = abs(self.layoutAdapter.positionY(for: nextState) - self.layoutAdapter.positionY(for: self.state))
        }
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
                    self?.finishRemovalAnimation()
                }
            }
        }

        viewcontroller.delegate?.floatingPanelDidEndDragging(viewcontroller, withVelocity: velocity, targetPosition: targetPosition)

        guard let animator = self.animator else {
            return
        }

        // Workaround: Disable a tracking scroll to prevent bouncing a scroll content in a panel animating
        let wasScrollEnabled = self.scrollView?.isScrollEnabled
        if let scrollView = scrollView, targetPosition != .full {
            scrollView.isScrollEnabled = false
        }

        if velocity.y != 0 {
            // Since we assume that the threshold for changing the panel's state is the halfway point between two
            // states, we can also assume that when the user stopped dragging the panel before reaching this halfway
            // point the panel moves back to its original state which means that the animation needs to be reversed aka
            // played backwards.
            animator.isReversed = animator.fractionComplete < 0.5
        }
        // Since the user stopped moving the panel, we need to let the animator finish the animation completely.
        animator.continueAnimation(withTimingParameters: nil, durationFactor: 0)

        // Workaround: Reset `self.scrollView.isScrollEnabled`
        if let wasScrollEnabled = wasScrollEnabled {
            self.scrollView?.isScrollEnabled = wasScrollEnabled
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

    private func finishRemovalAnimation() {
        viewcontroller?.dismiss(animated: false) { [weak self] in
            guard let vc = self?.viewcontroller else { return }
            vc.delegate?.floatingPanelDidEndRemove(vc)
        }
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

    private func animationDidComplete(at targetPosition: FloatingPanelPosition) {
        log.debug("animationDidComplete to \(targetPosition)")

        self.isDecelerating = false
        self.animator = nil

        self.viewcontroller.delegate?.floatingPanelDidEndDecelerating(self.viewcontroller)

        if let scrollView = scrollView {
            log.debug("animationDidComplete -- scroll offset = \(scrollView.contentOffset)")
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

            let th1: CGFloat = topY + (middleY - topY) * redirectionalProgress
            let th2: CGFloat = middleY + (bottomY - middleY) * redirectionalProgress

            let decelerationRate = behavior.momentumProjectionRate(viewcontroller)

            let baseY = abs(bottomY - topY)
            let velocityY = velocity.y / baseY
            let pY = project(initialVelocity: velocityY, decelerationRate: decelerationRate) * baseY + currentY

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

        if isScrollLocked {
            log.debug("Already scroll locked.")
            return
        }
        isScrollLocked = true

        scrollBouncable = scrollView.bounces
        scrollIndictorVisible = scrollView.showsVerticalScrollIndicator

        scrollView.isDirectionalLockEnabled = true
        scrollView.bounces = false
        scrollView.showsVerticalScrollIndicator = false
    }

    private func unlockScrollView() {
        guard let scrollView = scrollView else { return }

        isScrollLocked = false

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
