# Floating Panel API Guide

## Table of Contents

<details>
<summary>Click here</summary>

- [Table of Contents](#table-of-contents)
- [View hierarchy](#view-hierarchy)
- [Usage](#usage)
  - [Show/Hiding a floating panel in a view with your view hierarchy](#showhiding-a-floating-panel-in-a-view-with-your-view-hierarchy)
  - [Scaling the content view when the surface position changes](#scaling-the-content-view-when-the-surface-position-changes)
  - [Customizing the layout with `FloatingPanelLayout` protocol](#customizing-the-layout-with-floatingpanellayout-protocol)
    - [Changing the initial layout](#changing-the-initial-layout)
  - [Updating your panel layout](#updating-your-panel-layout)
    - [Supporting your landscape layout](#supporting-your-landscape-layout)
    - [Using the intrinsic size of a content in your panel layout](#using-the-intrinsic-size-of-a-content-in-your-panel-layout)
    - [Specifying an anchor for each state by an inset of the `FloatingPanelController.view` frame](#specifying-an-anchor-for-each-state-by-an-inset-of-the-floatingpanelcontrollerview-frame)
    - [Changing the backdrop alpha](#changing-the-backdrop-alpha)
    - [Using custom panel states](#using-custom-panel-states)
  - [Customizing the behavior with `FloatingPanelBehavior` protocol](#customizing-the-behavior-with-floatingpanelbehavior-protocol)
    - [Modifying your floating panel's interaction](#modifying-your-floating-panels-interaction)
    - [Activating the rubber-band effect on panel edges](#activating-the-rubber-band-effect-on-panel-edges)
    - [Managing the projection of a pan gesture momentum](#managing-the-projection-of-a-pan-gesture-momentum)
  - [Specifying the panel move's boundary](#specifying-the-panel-moves-boundary)
  - [Customizing the surface design](#customizing-the-surface-design)
    - [Modifying your surface appearance](#modifying-your-surface-appearance)
    - [Use a custom grabber handle](#use-a-custom-grabber-handle)
    - [Customizing layout of the grabber handle](#customizing-layout-of-the-grabber-handle)
    - [Customizing content padding from surface edges](#customizing-content-padding-from-surface-edges)
    - [Customizing margins of the surface edges](#customizing-margins-of-the-surface-edges)
  - [Customizing gestures](#customizing-gestures)
    - [Suppressing the panel interaction](#suppressing-the-panel-interaction)
    - [Adding tap gestures to the surface view](#adding-tap-gestures-to-the-surface-view)
    - [Interrupting the delegate methods of `FloatingPanelController.panGestureRecognizer`](#interrupting-the-delegate-methods-of-floatingpanelcontrollerpangesturerecognizer)
  - [Creating an additional floating panel for a detail](#creating-an-additional-floating-panel-for-a-detail)
  - [Moving a position with an animation](#moving-a-position-with-an-animation)
  - [Working your contents together with a floating panel behavior](#working-your-contents-together-with-a-floating-panel-behavior)
  - [Enabling the tap-to-dismiss action of the backdrop view](#enabling-the-tap-to-dismiss-action-of-the-backdrop-view)
  - [Allowing to scroll content of the tracking scroll view in addition to the most expanded state](#allowing-to-scroll-content-of-the-tracking-scroll-view-in-addition-to-the-most-expanded-state)
- [Notes](#notes)
  - ['Show' or 'Show Detail' Segues from `FloatingPanelController`'s content view controller](#show-or-show-detail-segues-from-floatingpanelcontrollers-content-view-controller)
  - [UISearchController issue](#uisearchcontroller-issue)

</details>

## View hierarchy

`FloatingPanelController` manages the views as the following view hierarchy.

```text
FloatingPanelController.view (FloatingPanelPassThroughView)
 ├─ .backdropView (FloatingPanelBackdropView)
 └─ .surfaceView (FloatingPanelSurfaceView)
    ├─ .containerView (UIView)
    │  └─ .contentView (FloatingPanelController.contentViewController.view)
    └─ .grabber (FloatingPanelGrabberView)
```

## Usage

### Show/Hiding a floating panel in a view with your view hierarchy

If you need more control over showing and hiding the floating panel, you can forgo the `addPanel` and `removePanelFromParent` methods. These methods are a convenience wrapper for **FloatingPanel**'s `show` and `hide` methods along with some required setup.

There are two ways to work with the `FloatingPanelController`:

1. Add it to the hierarchy once and then call `show` and `hide` methods to make it appear/disappear.
2. Add it to the hierarchy when needed and remove afterwards.

The following example shows how to add the controller to your `UIViewController` and how to remove it. Make sure that you never add the same `FloatingPanelController` to the hierarchy before removing it.

**NOTE**: `self.` prefix is not required, nor recommended. It's used here to make it clearer where do the functions used come from. `self` is an instance of a custom UIViewController in your code.

```swift
// Add the floating panel view to the controller's view on top of other views.
self.view.addSubview(fpc.view)

// REQUIRED. It makes the floating panel view have the same size as the controller's view.
fpc.view.frame = self.view.bounds

// In addition, Auto Layout constraints are highly recommended.
// Constraint the fpc.view to all four edges of your controller's view.
// It makes the layout more robust on trait collection change.
fpc.view.translatesAutoresizingMaskIntoConstraints = false
NSLayoutConstraint.activate([
  fpc.view.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 0.0),
  fpc.view.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 0.0),
  fpc.view.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: 0.0),
  fpc.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: 0.0),
])

// Add the floating panel controller to the controller hierarchy.
self.addChild(fpc)

// Show the floating panel at the initial position defined in your `FloatingPanelLayout` object.
fpc.show(animated: true) {
    // Inform the floating panel controller that the transition to the controller hierarchy has completed.
    fpc.didMove(toParent: self)
}
```

After you add the `FloatingPanelController` as seen above, you can call `fpc.show(animated: true) { }` to show the panel and `fpc.hide(animated: true) { }` to hide it.

To remove the `FloatingPanelController` from the hierarchy, follow the example below.

```swift
// Inform the panel controller that it will be removed from the hierarchy.
fpc.willMove(toParent: nil)
    
// Hide the floating panel.
fpc.hide(animated: true) {
    // Remove the floating panel view from your controller's view.
    fpc.view.removeFromSuperview()
    // Remove the floating panel controller from the controller hierarchy.
    fpc.removeFromParent()
}
```

### Scaling the content view when the surface position changes

Specify the `contentMode` to `.fitToBounds` if the surface height fits the bounds of `FloatingPanelController.view` when the surface position changes

```swift
fpc.contentMode = .fitToBounds
```

Otherwise, `FloatingPanelController` fixes the content by the height of the top most position.

> [!NOTE]
> In `.fitToBounds` mode, the surface height changes as following a user interaction so that you have a responsibility to configure Auto Layout constrains not to break the layout of a content view by the elastic surface height.

### Customizing the layout with `FloatingPanelLayout` protocol

#### Changing the initial layout

```swift
class ViewController: UIViewController, FloatingPanelControllerDelegate {
    ... {
        fpc = FloatingPanelController(delegate: self)
        fpc.layout = MyFloatingPanelLayout()
    }
}

class MyFloatingPanelLayout: FloatingPanelLayout {
    let position: FloatingPanelPosition = .bottom
    let initialState: FloatingPanelState = .tip
    let anchors: [FloatingPanelState: FloatingPanelLayoutAnchoring] = [
        .full: FloatingPanelLayoutAnchor(absoluteInset: 16.0, edge: .top, referenceGuide: .safeArea),
        .half: FloatingPanelLayoutAnchor(fractionalInset: 0.5, edge: .bottom, referenceGuide: .safeArea),
        .tip: FloatingPanelLayoutAnchor(absoluteInset: 44.0, edge: .bottom, referenceGuide: .safeArea),
    ]
}
```

### Updating your panel layout

There are 2 ways to update the panel layout.

1. Manually set `FloatingPanelController.layout` to the new layout object directly.

```swift
fpc.layout = MyPanelLayout()
fpc.invalidateLayout() // If needed
```

Note: If you already set the `delegate` property of your `FloatingPanelController` instance, `invalidateLayout()` overrides the layout object of `FloatingPanelController` with one returned by the delegate object.

2. Returns an appropriate layout object in one of 2 `floatingPanel(_:layoutFor:)` delegates.

```swift
class ViewController: UIViewController, FloatingPanelControllerDelegate {
    ...
    func floatingPanel(_ vc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout {
        return MyFloatingPanelLayout()
    }

    // OR
    func floatingPanel(_ vc: FloatingPanelController, layoutFor size: CGSize) -> FloatingPanelLayout {
        return MyFloatingPanelLayout()
    } 
}
```

#### Supporting your landscape layout

```swift
class ViewController: UIViewController, FloatingPanelControllerDelegate {
    ...
    func floatingPanel(_ vc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout {
        return (newCollection.verticalSizeClass == .compact) ? LandscapePanelLayout() : FloatingPanelBottomLayout()
    }
}

class LandscapePanelLayout: FloatingPanelLayout {
    let position: FloatingPanelPosition = .bottom
    let initialState: FloatingPanelState = .tip
    let anchors: [FloatingPanelState: FloatingPanelLayoutAnchoring] = [
        .full: FloatingPanelLayoutAnchor(absoluteInset: 16.0, edge: .top, referenceGuide: .safeArea),
        .tip: FloatingPanelLayoutAnchor(absoluteInset: 69.0, edge: .bottom, referenceGuide: .safeArea),
    ]
    
    func prepareLayout(surfaceView: UIView, in view: UIView) -> [NSLayoutConstraint] {
        return [
            surfaceView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 8.0),
            surfaceView.widthAnchor.constraint(equalToConstant: 291),
        ]
    }
}
```

#### Using the intrinsic size of a content in your panel layout

1. Lay out your content View with the intrinsic height size. For example, see "Detail View Controller scene"/"Intrinsic View Controller scene" of [Main.storyboard](Examples/Samples/Sources/Base.lproj/Main.storyboard). The 'Stack View.bottom' constraint determines the intrinsic height.
2. Specify layout anchors using `FloatingPanelIntrinsicLayoutAnchor`.

```swift
class IntrinsicPanelLayout: FloatingPanelLayout {
    let position: FloatingPanelPosition = .bottom
    let initialState: FloatingPanelState = .full
    let anchors: [FloatingPanelState: FloatingPanelLayoutAnchoring] = [
        .full: FloatingPanelIntrinsicLayoutAnchor(absoluteOffset: 0, referenceGuide: .safeArea),
        .half: FloatingPanelIntrinsicLayoutAnchor(fractionalOffset: 0.5, referenceGuide: .safeArea),
    ]
    ...
}
```

> [!WARNING]
> `FloatingPanelIntrinsicLayout` is deprecated on v1.

#### Specifying an anchor for each state by an inset of the `FloatingPanelController.view` frame

Use `.superview` reference guide in your anchors.

```swift
class MyFullScreenLayout: FloatingPanelLayout {
    ...
    let anchors: [FloatingPanelState: FloatingPanelLayoutAnchoring] = [
        .full: FloatingPanelLayoutAnchor(absoluteInset: 16.0, edge: .top, referenceGuide: .superview),
        .half: FloatingPanelLayoutAnchor(fractionalInset: 0.5, edge: .bottom, referenceGuide: .superview),
        .tip: FloatingPanelLayoutAnchor(absoluteInset: 44.0, edge: .bottom, referenceGuide: .superview),
    ]
}
```

> [!WARNING]
> `FloatingPanelFullScreenLayout` is deprecated on v1.

#### Changing the backdrop alpha

You can change the backdrop alpha by `FloatingPanelLayout.backdropAlpha(for:)` for each state(`.full`, `.half` and `.tip`).

For instance, if a panel seems like the backdrop view isn't there on `.half` state, it's time to implement the backdropAlpha API and return a value for the state as below.

```swift
class MyPanelLayout: FloatingPanelLayout {
    func backdropAlpha(for state: FloatingPanelState) -> CGFloat {
        switch state {
        case .full, .half: return 0.3
        default: return 0.0
        }
    }
}
```

#### Using custom panel states

You're able to define custom panel states and use them as the following example.

```swift
extension FloatingPanelState {
    static let lastQuart: FloatingPanelState = FloatingPanelState(rawValue: "lastQuart", order: 750)
    static let firstQuart: FloatingPanelState = FloatingPanelState(rawValue: "firstQuart", order: 250)
}

class FloatingPanelLayoutWithCustomState: FloatingPanelBottomLayout {
    override var anchors: [FloatingPanelState: FloatingPanelLayoutAnchoring] {
        return [
            .full: FloatingPanelLayoutAnchor(absoluteInset: 0.0, edge: .top, referenceGuide: .safeArea),
            .lastQuart: FloatingPanelLayoutAnchor(fractionalInset: 0.75, edge: .bottom, referenceGuide: .safeArea),
            .half: FloatingPanelLayoutAnchor(fractionalInset: 0.5, edge: .bottom, referenceGuide: .safeArea),
            .firstQuart: FloatingPanelLayoutAnchor(fractionalInset: 0.25, edge: .bottom, referenceGuide: .safeArea),
            .tip: FloatingPanelLayoutAnchor(absoluteInset: 20.0, edge: .bottom, referenceGuide: .safeArea),
        ]
    }
}
```

### Customizing the behavior with `FloatingPanelBehavior` protocol

#### Modifying your floating panel's interaction

```swift
class ViewController: UIViewController, FloatingPanelControllerDelegate {
    ...
    func viewDidLoad() {
        ...
        fpc.behavior =  CustomPanelBehavior()
    }
}

class CustomPanelBehavior: FloatingPanelBehavior {
    let springDecelerationRate = UIScrollView.DecelerationRate.fast.rawValue + 0.02
    let springResponseTime = 0.4
    func shouldProjectMomentum(_ fpc: FloatingPanelController, to proposedState: FloatingPanelState) -> Bool {
        return true
    }
}
```

> [!WARNING]
> `floatingPanel(_ vc:behaviorFor:)` is deprecated on v1.

#### Activating the rubber-band effect on panel edges

```swift
class MyPanelBehavior: FloatingPanelBehavior {
    ...
    func allowsRubberBanding(for edge: UIRectEdge) -> Bool {
        return true
    }
}
```

#### Managing the projection of a pan gesture momentum

This allows full projectional panel behavior. For example, a user can swipe up a panel from tip to full nearby the tip position.

```swift
class MyPanelBehavior: FloatingPanelBehavior {
    ...
    func shouldProjectMomentum(_ fpc: FloatingPanelController, to proposedState: FloatingPanelState) -> Bool {
        return true
    }
}
```

### Specifying the panel move's boundary

`FloatingPanelController.surfaceLocation` in `floatingPanelDidMove(_:)` delegate method behaves like `UIScrollView.contentOffset` in `scrollViewDidScroll(_:)`.
As a result, you can specify the boundary of a panel move as below.

```swift
func floatingPanelDidMove(_ vc: FloatingPanelController) {
    if vc.isAttracting == false {
        let loc = vc.surfaceLocation
        let minY = vc.surfaceLocation(for: .full).y - 6.0
        let maxY = vc.surfaceLocation(for: .tip).y + 6.0
        vc.surfaceLocation = CGPoint(x: loc.x, y: min(max(loc.y, minY), maxY))
    }
}
```

> [!WARNING]
> `{top,bottom}InteractionBuffer` property is removed from `FloatingPanelLayout` since v2.

### Customizing the surface design

#### Modifying your surface appearance

```swift
// Create a new appearance.
let appearance = SurfaceAppearance()

// Define shadows
let shadow = SurfaceAppearance.Shadow()
shadow.color = UIColor.black
shadow.offset = CGSize(width: 0, height: 16)
shadow.radius = 16
shadow.spread = 8
appearance.shadows = [shadow]

// Define corner radius and background color
appearance.cornerRadius = 8.0
appearance.backgroundColor = .clear

// Set the new appearance
fpc.surfaceView.appearance = appearance
````

#### Use a custom grabber handle

```swift
let myGrabberHandleView = MyGrabberHandleView()
fpc.surfaceView.grabberHandle.isHidden = true
fpc.surfaceView.addSubview(myGrabberHandleView)
```

#### Customizing layout of the grabber handle

```swift
fpc.surfaceView.grabberHandlePadding = 10.0
fpc.surfaceView.grabberHandleSize = .init(width: 44.0, height: 12.0)
```

> [!NOTE]
> `grabberHandleSize` width and height are reversed in the left/right position.

#### Customizing content padding from surface edges

```swift
fpc.surfaceView.contentPadding = .init(top: 20, left: 20, bottom: 20, right: 20)
```

#### Customizing margins of the surface edges

```swift
fpc.surfaceView.containerMargins = .init(top: 20.0, left: 16.0, bottom: 16.0, right: 16.0)
```

The feature can be used for these 2 kind panels

- Facebook/Slack-like panel whose surface top edge is separated from the grabber handle.
- iOS native panel to display AirPods information, for example.

### Customizing gestures

#### Suppressing the panel interaction

You can disable the pan gesture recognizer directly

```swift
fpc.panGestureRecognizer.isEnabled = false
```

Or use this `FloatingPanelControllerDelegate` method.

```swift
func floatingPanelShouldBeginDragging(_ vc: FloatingPanelController) -> Bool {
    return aCondition ?  false : true
}
```

#### Adding tap gestures to the surface view

```swift
override func viewDidLoad() {
    ...
    let surfaceTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleSurface(tapGesture:)))
    fpc.surfaceView.addGestureRecognizer(surfaceTapGesture)
    surfaceTapGesture.isEnabled = (fpc.position == .tip)
}

// Enable `surfaceTapGesture` only at `tip` state
func floatingPanelDidChangeState(_ vc: FloatingPanelController) {
    surfaceTapGesture.isEnabled = (vc.position == .tip)
}
```

#### Interrupting the delegate methods of `FloatingPanelController.panGestureRecognizer`

If you are set `FloatingPanelController.panGestureRecognizer.delegateProxy` to an object adopting `UIGestureRecognizerDelegate`, it overrides delegate methods of the pan gesture recognizer.

```swift
class MyGestureRecognizerDelegate: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
}

class ViewController: UIViewController {
    let myGestureDelegate = MyGestureRecognizerDelegate()

    func setUpFpc() {
        ....
        fpc.panGestureRecognizer.delegateProxy = myGestureDelegate
    }
```

### Creating an additional floating panel for a detail

```swift
override func viewDidLoad() {
    // Setup Search panel
    self.searchPanelVC = FloatingPanelController()

    let searchVC = SearchViewController()
    self.searchPanelVC.set(contentViewController: searchVC)
    self.searchPanelVC.track(scrollView: contentVC.tableView)

    self.searchPanelVC.addPanel(toParent: self)

    // Setup Detail panel
    self.detailPanelVC = FloatingPanelController()

    let contentVC = ContentViewController()
    self.detailPanelVC.set(contentViewController: contentVC)
    self.detailPanelVC.track(scrollView: contentVC.scrollView)

    self.detailPanelVC.addPanel(toParent: self)
}
```

### Moving a position with an animation

In the following example, I move a floating panel to full or half position while opening or closing a search bar like Apple Maps.

```swift
func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    ...
    fpc.move(to: .half, animated: true)
}

func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
    ...
    fpc.move(to: .full, animated: true)
}
```

You can also use a view animation to move a panel.

```swift
UIView.animate(withDuration: 0.25) {
    self.fpc.move(to: .half, animated: false)
}
```

### Working your contents together with a floating panel behavior

```swift
class ViewController: UIViewController, FloatingPanelControllerDelegate {
    ...
    func floatingPanelWillBeginDragging(_ vc: FloatingPanelController) {
        if vc.position == .full {
            searchVC.searchBar.showsCancelButton = false
            searchVC.searchBar.resignFirstResponder()
        }
    }

    func floatingPanelWillEndDragging(_ vc: FloatingPanelController, withVelocity velocity: CGPoint, targetState: UnsafeMutablePointer<FloatingPanelState>) {
        if targetState.pointee != .full {
            searchVC.hideHeader()
        }
    }
}
```

### Enabling the tap-to-dismiss action of the backdrop view

The tap-to-dismiss action is disabled by default. So it needs to be enabled as below.

```swift
fpc.backdropView.dismissalTapGestureRecognizer.isEnabled = true
```

### Allowing to scroll content of the tracking scroll view in addition to the most expanded state

Just define conditions to allow content scrolling in `floatingPanel(:_:shouldAllowToScroll:in)` delegate method. If the returned value is true, the scroll content scrolls when its scroll position is not at the top of the content.

```swift
class MyViewController: FloatingPanelControllerDelegate {
    ... 

    func floatingPanel(
        _ fpc: FloatingPanelController,
        shouldAllowToScroll trackingScrollView: UIScrollView,
        in state: FloatingPanelState
    ) -> Bool {
        return state == .full || state == .half
    }
}
```

## Notes

### 'Show' or 'Show Detail' Segues from `FloatingPanelController`'s content view controller

'Show' or 'Show Detail' segues from a content view controller will be managed by a view controller(hereinafter called 'master VC') adding a floating panel. Because a floating panel is just a subview of the master VC(except for modality).

`FloatingPanelController` has no way to manage a stack of view controllers like `UINavigationController`. If so, it would be so complicated and the interface will become `UINavigationController`. This component should not have the responsibility to manage the stack.

By the way, a content view controller can present a view controller modally with `present(_:animated:completion:)` or 'Present Modally' segue.

However, sometimes you want to show a destination view controller of 'Show' or 'Show Detail' segue with another floating panel. It's possible to override `show(_:sender)` of the master VC!

Here is an example.

```swift
class ViewController: UIViewController {
    var fpc: FloatingPanelController!
    var secondFpc: FloatingPanelController!

    ...
    override func show(_ vc: UIViewController, sender: Any?) {
        secondFpc = FloatingPanelController()

        secondFpc.set(contentViewController: vc)

        secondFpc.addPanel(toParent: self)
    }
}
```

A `FloatingPanelController` object proxies an action for `show(_:sender)` to the master VC. That's why the master VC can handle a destination view controller of a 'Show' or 'Show Detail' segue and you can hook `show(_:sender)` to show a secondary floating panel set the destination view controller to the content.

It's a great way to decouple between a floating panel and the content VC.

### UISearchController issue

`UISearchController` isn't able to be used with `FloatingPanelController` by the system design.

Because `UISearchController` automatically presents itself modally when a user interacts with the search bar, and then it swaps the superview of the search bar to the view managed by itself while it displays. As a result, `FloatingPanelController` can't control the search bar when it's active, as you can see from [the screen shot](https://github.com/SCENEE/FloatingPanel/issues/248#issuecomment-521263831).
