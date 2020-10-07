# FloatingPanel 2.0 Migration Guide

FloatingPanel 2.0 is the latest major release of FloatingPanel. As a major release, following Semantic Versioning conventions, 2.0 introduces API-breaking changes.

This guide is provided in order to ease the transition of existing applications using FloatingPanel 1.x to the latest APIs, as well as explain the design and structure of new and updated functionality.

## Updated Minimum Requirements

* Swift 5.0
* iOS 11 (iOS 10 is still the deployment target, but not tested well)
* Xcode 11.0

## Benefits of Upgrading

* __Top, left and right positioned panel__
  * FloatingPanel is not just a library for a bottom positioned panel, but also top, left and right positioned ones.
* __Objective-C compatibility__
  * The entire APIs are exposed in Objective-C. So you can use them in Objective-C directly.
* __Flexible and explicit layout customization__
  * `FloatingPanelLayout` is redesigned. There is no implicit rules to lay out a panel anymore.
* __New spring animation without UIViewPropertyAnimator__
  * The new spring animation uses [Numeric springing](http://allenchou.net/2015/04/game-math-precise-control-over-numeric-springing/) which is a very powerful tool for procedural animation. Therefore a library consumer is easy to modify a panel behavior by 2 paramters of the deceleration rate and response time.
* __Handle the panel position anytime__
  * `floatingPanelDidMove(_:)` delegate method is also called while a panel is moving. The method behavior becomes same as `scrollViewDidScroll(_:)` in `UIScrollViewDelegate`. And in the method a library consumer is able to change a panel location.
* __Update the removal interaction's invocation__
  * Now you can invoke the removal interaction at any time where you want. There is no restrictions in the library.
* __Fix many issues depending on API design__
  * See the following sections for details.

## API Name Changes

* `FloatingPanelPosition` is now `FloatingPanelState`.
  * `FloatingPanelPosition` in v2 is used to specify a panel position(top, left, bottom and right) in a screen.
* `FloatingPanelSurfaceView` is `SurfaceView` only in Swift.
* `FloatingPanelBackdropView` is `BackdropView` only in Swift.
* `FloatingPanelGrabberHandleView` is `GrabberView` only in Swift.
* "decelerate" term is replaced with "attract" because the panel's behavior is not unidirectional, but going back and forth so that it is settled to a location.

## `FloatingPanelController`

* `layout` and `behavior` properties can be changed directly without using the delegate methods.

```swift
fpc.behavior = SearchPaneliPadBehavior()
fpc.layout = SearchPaneliPadLayout()
fpc.invalidateLayout() // If needed
```

* The second argument of `addPanel(toParent:)` changes to specify an index of subviews of a view in which a panel is added.

```diff
- public func addPanel(toParent parent: UIViewController, belowView: UIView? = nil, animated: Bool = false) {
+ public func addPanel(toParent parent: UIViewController, at viewIndex: Int = -1, animated: Bool = false) {
```

* `surfaceOriginY` is now `surfaceLocation`.
* `updateLayout` is now `invalidateLayout`.
* The scroll tracking API is changed a bit to support multiple scroll view tracking in the future.
  * Now `untrack(scrollView:)` is used to disable the scroll tracking.

## `FloatingPanelControllerDelegate`

* `floatingPanelDidEndDragging(_ vc:willAttract:)` is added to check whether a panel will continue to move after dragging.
* `floatingPanelDidMove(_:)` behavior changes. The method is also called in the spring animation.
* The removal interaction delegate is updated.
  * `floatingPanel(_:shouldRemoveAt:with:)` is added to determine whether it invokes the removal interaction in any state.
  * `floatingPanelWillRemove(_:)` is added.
* `floatingPanel(_: FloatingPanelController, layoutFor size: CGSize)` is added to respond to a layout change in regular size classes on iPad.

```swift
func floatingPanel(_ fpc: FloatingPanelController, layoutFor size: CGSize) -> FloatingPanelLayout {
    if aCondition(for: size) {
        return SearchPanelLayout()
    }
    return SearchPanel2Layout()
}
```

* The `targetState` argument type of `floatingPanelWillEndDragging(_:withVelocity:targetState:)` is changed from `FloatingPanelState` to  `UnsafeMutablePointer<FloatingPanelState>` to modify a target state on demand.

```swift
func floatingPanelWillEndDragging(_ vc: FloatingPanelController, withVelocity velocity: CGPoint, targetState: UnsafeMutablePointer<FloatingPanelState>) {
    switch targetState.pointee {
        case .full:
          // do something...
        case .half:
            if aCondition {
                targetState.pointee = .tip
            }
        default:
            break
    }
}
```

### Deprecated APIs

* `floatingPanel(_:behaviorFor:)`
  * Please update `FloatingPanelController.behavior` directly.
* `floatingPanel(_:shouldRecognizeSimultaneouslyWith:)`
  * Please use `FloatingPanelController.panGestureRecognizer.delegateProxy`.

## `FloatingPanelLayout`

* `position` property is added to determine a panel position.
* `initialPosition` is now `initialState`.
* `supportedPositions` and `insetFor(position:)` are replaced with `anchors` property.
* `backdropAlphaFor(position:)` is now `backdropAlpha(for:)`.

```swift
class SearchPanelPadLayout: FloatingPanelLayout {
    let position: FloatingPanelPosition  = .top
    let initialState: FloatingPanelState = .tip
    var anchors: [FloatingPanelState : FloatingPanelLayoutAnchoring] {
        return [
            ...
        ]
    }
    func backdropAlpha(for state: FloatingPanelState) -> CGFloat {
        return 0.3
    }
    ...
}
```

### New `FloatingPanelLayoutAnchoring` classes

The following objects adopting `FloatingPanelLayoutAnchoring` protocol are added to configure the flexible and explicit layout.

#### `FloatingPanelLayoutAnchor`

This class is used to specify a panel layout using insets from a rectangle area of the superview or safe area.

* `FloatingPanelFullScreenLayout` is replaced with anchors using `.superview` reference guide.
* `FloatingPanelLayoutAnchor(fractionalInset:edge:referenceGuide:)` lets you lay out a panel at a relative position in a reference rectangle area.

```swift
// Before:
class MyPanelLayout: FloatingPanelLayout {
    var initialPosition: FloatingPanelPosition {
        return .half
    }

    func insetFor(position: FloatingPanelPosition) -> CGFloat? {
        switch position {
        case .full: return 16.0
        case .half: return 262.0
        case .tip: return 44.0
        case .hidden: return nil
        }
    }
}

// After:
class MyPanelLayout: FloatingPanelLayout {
    var position: FloatingPanelPosition = .bottom
    var initialState: FloatingPanelState { .half }
    var anchors: [FloatingPanelState : FloatingPanelLayoutAnchoring] {
        return [
            .full: FloatingPanelLayoutAnchor(absoluteInset: 16.0, edge: .top, referenceGuide: .safeArea),
            .half: FloatingPanelLayoutAnchor(fractionalInset: 0.5, edge: .bottom, referenceGuide: .superview),
            .tip: FloatingPanelLayoutAnchor(absoluteInset: 44.0, edge: .bottom, referenceGuide: .safeArea)
        ]
    }
}
```

#### `FloatingPanelIntrinsicLayoutAnchor`

This class is used to specify a panel layout using offsets from the intrinsic size layout.

* This replaces `FloatingPanelIntrinsicLayout`.
* This is also able to configure a fractional layout in the intrinsic size.

```swift
// Before:
class MyPanelIntrinsicLayout: FloatingPanelIntrinsicLayout {
    var initialPosition: FloatingPanelPosition {
        return .half
    }
    func insetFor(position: FloatingPanelPosition) -> CGFloat? {
        switch position {
        case .full: return 16.0
        case .half: return 262.0
        case .tip: return 44.0
        case .hidden: return nil
        }
    }
}

// After:
class MyPanelIntrinsicLayout: FloatingPanelLayout {
    var position: FloatingPanelPosition = .bottom
    var initialState: FloatingPanelState { .full }
    var anchors: [FloatingPanelState : FloatingPanelLayoutAnchoring] {
        return [
            .full: FloatingPanelIntrinsicLayoutAnchor(absoluteOffset: 16.0, referenceGuide: .safeArea),
            .half: FloatingPanelIntrinsicLayoutAnchor(fractionalOffset: 0.5, referenceGuide: .safeArea),
            .tip: FloatingPanelLayoutAnchor(absoluteInset: 44.0, edge: .bottom, referenceGuide: .safeArea)
        ]
    }
}
```

### Deprecated APIs

* `.topInteractionBuffer` and `.bottomInteractionBuffer`.
  * Please control the max/min range of the motion in `floatingPanelDidMove(_:)` delegate method as below.

```swift
func floatingPanelDidMove(_ fpc: FloatingPanelController) {
    if fpc.isAttracting == false {
        let loc = fpc.surfaceLocation
        let minY = fpc.surfaceLocation(for: .full).y - 6.0
        let maxY = fpc.surfaceLocation(for: .tip).y + 6.0
        fpc.surfaceLocation = CGPoint(x: loc.x, y: min(max(loc.y, minY), maxY))
    }
}
```

## `FloatingPanelBehavior`

* `.springDecelerationRate` and `.springResponseTime` properties are added to control the new spring effect of Numeric springing.

### Deprecated APIs

* `addAnimator(_:to:)`, `removeAnimator(_:from:)`
  * They are moved into `floatingPanel(_:animatorForPresentingTo:)` and  `floatingPanel(_:animatorForDismissingWith:)` of `FloatingPanelControllerDelegate` because they are used for view transitions.
* `interactionAnimator(_:to:with:)`, `moveAnimator(_:from:to:)`
  * They are removed because the animators are replaced with the new spring effect.
* `removalVelocity`, `removalProgress`
  * They are replaced with `floatingPanel(_:shouldRemoveAt:with:)` of `FloatingPanelControllerDelegate`
* `removalInteractionAnimator(_:with:)`
  * It is integrated with `floatingPanel(_:animatorForDismissingWith:)` of `FloatingPanelControllerDelegate`.

## `SurfaceView`

* `SurfaceAppearance` class and `SurfaceView.appearance` property are added to specify the rounding corners, shadows and background color.
  * `SurfaceView.appearance` property avoids `Ambiguous use of 'cornerRadius'` error, for instance.
  * `SurfaceAppearance` enables to apply layered box shadows into a surface to materialize it.

```swift
// Before:
fpc.surfaceView.cornerRadius = 6.0
fpc.surfaceView.backgroundColor = .clear
fpc.surfaceView.shadowHidden = false
fpc.surfaceView.shadowColor = .black
fpc.surfaceView.shadowOffset = CGSize(width: 0, height: 16)
fpc.surfaceView.shadowRadius = 16.0

// After:
let appearance = SurfaceAppearance()
appearance.cornerRadius = 8.0
appearance.backgroundColor = .clear

let shadow = SurfaceAppearance.Shadow()
shadow.color = .black
shadow.offset = CGSize(width: 0, height: 16)
shadow.radius = 16
shadow.spread = 8
appearance.shadows = [shadow]

fpc.surfaceView.appearance = appearance
```

* These properties are changed for the top, left and right positioned panel.
  * `grabberTopPadding` is now `grabberHandlePadding`.
  * `topGrabberBarHeight` is now `grabberAreaOffset`.
  * `grabberHandleWidth` and `grabberHandleHeight` are replaced with `grabberHandleSize`.

## `BackdropView`

* The dismissal action of the backdrop is disabled by default.
  * You can enable it to set `BackdropView.dismissalTapGestureRecognizer.isEnabled` to `true`.

## `FloatingPanelPanGestureRecognizer`

* `delegateProxy` property is added to intercept the gesture recognizer delegate.

```swift
func layoutPanelForPad() {
    fpc.behavior = SearchPaneliPadBehavior()
    fpc.panGestureRecognizer.delegateProxy = self
}

func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    return false
}
```

## Miscellaneous

* `UISpringTimingParameters(decelerationRate:frequencyResponse:initialVelocity:)` initializer is added.
* The directory structure and file names in the Xcode project changes.
