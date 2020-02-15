[![Build Status](https://travis-ci.org/SCENEE/FloatingPanel.svg?branch=master)](https://travis-ci.org/SCENEE/FloatingPanel)
[![Version](https://img.shields.io/cocoapods/v/FloatingPanel.svg)](https://cocoapods.org/pods/FloatingPanel)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Platform](https://img.shields.io/cocoapods/p/FloatingPanel.svg)](https://cocoapods.org/pods/FloatingPanel)
[![Swift 4.1](https://img.shields.io/badge/Swift-4.1-orange.svg?style=flat)](https://swift.org/)
[![Swift 4.2](https://img.shields.io/badge/Swift-4.2-orange.svg?style=flat)](https://swift.org/)
[![Swift 5.0](https://img.shields.io/badge/Swift-5.0-orange.svg?style=flat)](https://swift.org/)
[![Swift 5.1](https://img.shields.io/badge/Swift-5.1-orange.svg?style=flat)](https://swift.org/)

# FloatingPanel

FloatingPanel is a simple and easy-to-use UI component for a new interface introduced in Apple Maps, Shortcuts and Stocks app.
The new interface displays the related contents and utilities in parallel as a user wants.

![Maps](https://github.com/SCENEE/FloatingPanel/blob/master/assets/maps.gif)
![Stocks](https://github.com/SCENEE/FloatingPanel/blob/master/assets/stocks.gif)

![Maps(Landscape)](https://github.com/SCENEE/FloatingPanel/blob/master/assets/maps-landscape.gif)

<!-- TOC -->

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
  - [CocoaPods](#cocoapods)
  - [Carthage](#carthage)
  - [Swift Package Manager with Xcode 11](#swift-package-manager-with-xcode-11)
- [Getting Started](#getting-started)
  - [Add a floating panel as a child view controller](#add-a-floating-panel-as-a-child-view-controller)
  - [Present a floating panel as a modality](#present-a-floating-panel-as-a-modality)
- [View hierarchy](#view-hierarchy)
- [Usage](#usage)
  - [Show/Hide a floating panel in a view with your view hierarchy](#showhide-a-floating-panel-in-a-view-with-your-view-hierarchy)
  - [Scale the content view when the surface position changes](#scale-the-content-view-when-the-surface-position-changes)
  - [Customize the layout with `FloatingPanelLayout` protocol](#customize-the-layout-with-floatingpanellayout-protocol)
    - [Change the initial position and height](#change-the-initial-position-and-height)
    - [Support your landscape layout](#support-your-landscape-layout)
    - [Use Intrinsic height layout](#use-intrinsic-height-layout)
    - [Specify position insets from the frame of `FloatingPanelController.view`, not the SafeArea](#specify-position-insets-from-the-frame-of-floatingpanelcontrollerview-not-the-safearea)
  - [Customize the behavior with `FloatingPanelBehavior` protocol](#customize-the-behavior-with-floatingpanelbehavior-protocol)
    - [Modify your floating panel's interaction](#modify-your-floating-panels-interaction)
    - [Activate the rubber-band effect on the top/bottom edges](#activate-the-rubber-band-effect-on-the-topbottom-edges)
    - [Manage the projection of a pan gesture momentum](#manage-the-projection-of-a-pan-gesture-momentum)
  - [Customize the surface design](#customize-the-surface-design)
    - [Use a custom grabber handle](#use-a-custom-grabber-handle)
    - [Customize layout of the grabber handle](#customize-layout-of-the-grabber-handle)
    - [Customize content padding from surface edges](#customize-content-padding-from-surface-edges)
    - [Customize margins of the surface edges](#customize-margins-of-the-surface-edges)
  - [Customize gestures](#customize-gestures)
    - [Suppress the panel interaction](#suppress-the-panel-interaction)
    - [Add tap gestures to the surface or backdrop views](#add-tap-gestures-to-the-surface-or-backdrop-views)
  - [Create an additional floating panel for a detail](#create-an-additional-floating-panel-for-a-detail)
  - [Move a position with an animation](#move-a-position-with-an-animation)
  - [Work your contents together with a floating panel behavior](#work-your-contents-together-with-a-floating-panel-behavior)
- [Notes](#notes)
  - ['Show' or 'Show Detail' Segues from `FloatingPanelController`'s content view controller](#show-or-show-detail-segues-from-floatingpanelcontrollers-content-view-controller)
  - [UISearchController issue](#uisearchcontroller-issue)
  - [FloatingPanelSurfaceView's issue on iOS 10](#floatingpanelsurfaceviews-issue-on-ios-10)
- [Author](#author)
- [License](#license)

<!-- /TOC -->

## Features

- [x] Simple container view controller
- [x] Fluid animation and gesture handling
- [x] Scroll view tracking
- [x] Common UI elements: Grabber handle, Backdrop and Surface rounding corners
- [x] 1~3 anchor positions(full, half, tip)
- [x] Layout customization for all trait environments(i.e. Landscape orientation support)
- [x] Behavior customization
- [x] Free from common issues of Auto Layout and gesture handling
- [x] Modal presentation

Examples are here.

- [Examples/Maps](https://github.com/SCENEE/FloatingPanel/tree/master/Examples/Maps) like Apple Maps.app.
- [Examples/Stocks](https://github.com/SCENEE/FloatingPanel/tree/master/Examples/Stocks) like Apple Stocks.app.

## Requirements

FloatingPanel is written in Swift 4.0+. It can be built by Xcode 9.4.1 or later. Compatible with iOS 10.0+.

✏️ The default Swift version is 4.0 because it avoids build errors with Carthage on each Xcode version from the source compatibility between Swift 4.0, 4.2 and 5.0.

## Installation

### CocoaPods

FloatingPanel is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'FloatingPanel'
```

✏️FloatingPanel v1.7.0 or later requires CocoaPods v1.7.0+ for `swift_versions` support.

### Carthage

For [Carthage](https://github.com/Carthage/Carthage), add the following to your `Cartfile`:

```ogdl
github "scenee/FloatingPanel"
```

### Swift Package Manager with Xcode 11

Follow [this doc](https://developer.apple.com/documentation/swift_packages/adding_package_dependencies_to_your_app).

## Getting Started

### Add a floating panel as a child view controller

```swift
import UIKit
import FloatingPanel

class ViewController: UIViewController, FloatingPanelControllerDelegate {
    var fpc: FloatingPanelController!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Initialize a `FloatingPanelController` object.
        fpc = FloatingPanelController()

        // Assign self as the delegate of the controller.
        fpc.delegate = self // Optional

        // Set a content view controller.
        let contentVC = ContentViewController()
        fpc.set(contentViewController: contentVC)

        // Track a scroll view(or the siblings) in the content view controller.
        fpc.track(scrollView: contentVC.tableView)

        // Add and show the views managed by the `FloatingPanelController` object to self.view.
        fpc.addPanel(toParent: self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Remove the views managed by the `FloatingPanelController` object from self.view.
        fpc.removePanelFromParent()
    }
}
```

### Present a floating panel as a modality

```swift
let fpc = FloatingPanelController()
let contentVC = ...
fpc.set(contentViewController: contentVC)

fpc.isRemovalInteractionEnabled = true // Optional: Let it removable by a swipe-down

self.present(fpc, animated: true, completion: nil)
```

You can show a floating panel over UINavigationController from the container view controllers as a modality of `.overCurrentContext` style.

✏️ FloatingPanelController has the custom presentation controller. If you would like to customize the presentation/dismissal, please see [FloatingPanelTransitioning](https://github.com/SCENEE/FloatingPanel/blob/master/Framework/Sources/FloatingPanelTransitioning.swift).

## View hierarchy

`FloatingPanelController` manages the views as the following view hierarchy.

```
FloatingPanelController.view (FloatingPanelPassThroughView)
 ├─ .backdropView (FloatingPanelBackdropView)
 └─ .surfaceView (FloatingPanelSurfaceView)
    ├─ .containerView (UIView)
    │  └─ .contentView (FloatingPanelController.contentViewController.view)
    └─ .grabberHandle (GrabberHandleView)
```

## Usage

### Show/Hide a floating panel in a view with your view hierarchy

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

### Scale the content view when the surface position changes

Specify the `contentMode` to `.fitToBounds` if the surface height fits the bounds of `FloatingPanelController.view` when the surface position changes

```swift
fpc.contentMode = .fitToBounds
```

Otherwise, `FloatingPanelController` fixes the content by the height of the top most position.

✏️ In `.fitToBounds` mode, the surface height changes as following a user interaction so that you have a responsibility to configure Auto Layout constrains not to break the layout of a content view by the elastic surface height.

### Customize the layout with `FloatingPanelLayout` protocol

#### Change the initial position and height

```swift
class ViewController: UIViewController, FloatingPanelControllerDelegate {
    ...
    func floatingPanel(_ vc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout? {
        return MyFloatingPanelLayout()
    }
}

class MyFloatingPanelLayout: FloatingPanelLayout {
    public var initialPosition: FloatingPanelPosition {
        return .tip
    }

    public func insetFor(position: FloatingPanelPosition) -> CGFloat? {
        switch position {
            case .full: return 16.0 // A top inset from safe area
            case .half: return 216.0 // A bottom inset from the safe area
            case .tip: return 44.0 // A bottom inset from the safe area
            default: return nil // Or `case .hidden: return nil`
        }
    }
}
```

#### Support your landscape layout

```swift
class ViewController: UIViewController, FloatingPanelControllerDelegate {
    ...
    func floatingPanel(_ vc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout? {
        return (newCollection.verticalSizeClass == .compact) ? FloatingPanelLandscapeLayout() : nil // Returning nil indicates to use the default layout
    }
}

class FloatingPanelLandscapeLayout: FloatingPanelLayout {
    public var initialPosition: FloatingPanelPosition {
        return .tip
    }
    public var supportedPositions: Set<FloatingPanelPosition> {
        return [.full, .tip]
    }

    public func insetFor(position: FloatingPanelPosition) -> CGFloat? {
        switch position {
            case .full: return 16.0
            case .tip: return 69.0
            default: return nil
        }
    }

    public func prepareLayout(surfaceView: UIView, in view: UIView) -> [NSLayoutConstraint] {
        return [
            surfaceView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 8.0),
            surfaceView.widthAnchor.constraint(equalToConstant: 291),
        ]
    }
}
```

#### Use Intrinsic height layout

1. Lay out your content View with the intrinsic height size. For example, see "Detail View Controller scene"/"Intrinsic View Controller scene" of [Main.storyboard](https://github.com/SCENEE/FloatingPanel/blob/master/Examples/Samples/Sources/Base.lproj/Main.storyboard). The 'Stack View.bottom' constraint determines the intrinsic height.
2. Create a layout that adopts and conforms to `FloatingPanelIntrinsicLayout` and use it.

```swift
class ViewController: UIViewController, FloatingPanelControllerDelegate {
    ...
    func floatingPanel(_ vc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout? {
        return RemovablePanelLayout()
    }
}

class RemovablePanelLayout: FloatingPanelIntrinsicLayout {
    var supportedPositions: Set<FloatingPanelPosition> {
        return [.full, .half]
    }
    func insetFor(position: FloatingPanelPosition) -> CGFloat? {
        switch position {
        case .half: return 130.0
        default: return nil  // Must return nil for .full
        }
    }
    ...
}
```

#### Specify position insets from the frame of `FloatingPanelController.view`, not the SafeArea

There are 2 ways. One is returning `.fromSuperview` for `FloatingPanelLayout.positionReference` in your layout.

```swift
class MyFullScreenLayout: FloatingPanelLayout {
    ...
    var positionReference: FloatingPanelLayoutReference {
        return .fromSuperview
    }
}
```

Another is using `FloatingPanelFullScreenLayout` protocol.

```swift
class MyFullScreenLayout: FloatingPanelFullScreenLayout {
    ...
}
```

### Customize the behavior with `FloatingPanelBehavior` protocol

#### Modify your floating panel's interaction

```swift
class ViewController: UIViewController, FloatingPanelControllerDelegate {
    ...
    func floatingPanel(_ vc: FloatingPanelController, behaviorFor newCollection: UITraitCollection) -> FloatingPanelBehavior? {
        return FloatingPanelStocksBehavior()
    }
}

class FloatingPanelStocksBehavior: FloatingPanelBehavior {
    ...
    func interactionAnimator(_ fpc: FloatingPanelController, to targetPosition: FloatingPanelPosition, with velocity: CGVector) -> UIViewPropertyAnimator {
        let damping = self.damping(with: velocity)
        let springTiming = UISpringTimingParameters(dampingRatio: damping, initialVelocity: velocity)
        return UIViewPropertyAnimator(duration: 0.5, timingParameters: springTiming)
    }
}
```

#### Activate the rubber-band effect on the top/bottom edges

```swift
class FloatingPanelBehavior: FloatingPanelBehavior {
    ...
    func allowsRubberBanding(for edge: UIRectEdge) -> Bool {
        return true
    }
}
```

#### Manage the projection of a pan gesture momentum

This allows full projectional panel behavior. For example, a user can swipe up a panel from tip to full nearby the tip position.

```swift
class FloatingPanelBehavior: FloatingPanelBehavior {
    ...
    func shouldProjectMomentum(_ fpc: FloatingPanelController, for proposedTargetPosition: FloatingPanelPosition) -> Bool {
        return true
    }
}
```

### Customize the surface design

#### Use a custom grabber handle

```swift
let myGrabberHandleView = MyGrabberHandleView()
fpc.surfaceView.grabberHandle.isHidden = true
fpc.surfaceView.addSubview(myGrabberHandleView)
```

#### Customize layout of the grabber handle

```swift
fpc.surfaceView.grabberTopPadding = 10.0
fpc.surfaceView.grabberHandleWidth = 44.0
fpc.surfaceView.grabberHandleHeight = 12.0
```

#### Customize content padding from surface edges

```swift
fpc.surfaceView.contentInsets = .init(top: 20, left: 20, bottom: 20, right: 20)
```

#### Customize margins of the surface edges

```swift
fpc.surfaceView.containerMargins = .init(top: 20.0, left: 16.0, bottom: 16.0, right: 16.0)
```

The feature can be used for these 2 kind panels

* Facebook/Slack-like panel whose surface top edge is separated from the grabber handle.
* iOS native panel to display AirPods information, for example.

### Customize gestures

#### Suppress the panel interaction

You can disable the pan gesture recognizer directly

```swift
fpc.panGestureRecognizer.isEnable = false
```

Or use this `FloatingPanelControllerDelegate` method.

```swift
func floatingPanelShouldBeginDragging(_ vc: FloatingPanelController) -> Bool {
    return aCondition ?  false : true
}
```

#### Add tap gestures to the surface or backdrop views

```swift
override func viewDidLoad() {
    ...
    surfaceTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleSurface(tapGesture:)))
    fpc.surfaceView.addGestureRecognizer(surfaceTapGesture)

    backdropTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleBackdrop(tapGesture:)))
    fpc.backdropView.addGestureRecognizer(backdropTapGesture)

    surfaceTapGesture.isEnabled = (fpc.position == .tip)
}

// Enable `surfaceTapGesture` only at `tip` position
func floatingPanelDidChangePosition(_ vc: FloatingPanelController) {
    surfaceTapGesture.isEnabled = (vc.position == .tip)
}
```

### Create an additional floating panel for a detail

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

### Move a position with an animation

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

### Work your contents together with a floating panel behavior

```swift
class ViewController: UIViewController, FloatingPanelControllerDelegate {
    ...
    func floatingPanelWillBeginDragging(_ vc: FloatingPanelController) {
        if vc.position == .full {
            searchVC.searchBar.showsCancelButton = false
            searchVC.searchBar.resignFirstResponder()
        }
    }

    func floatingPanelDidEndDragging(_ vc: FloatingPanelController, withVelocity velocity: CGPoint, targetPosition: FloatingPanelPosition) {
        if targetPosition != .full {
            searchVC.hideHeader()
        }
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

### FloatingPanelSurfaceView's issue on iOS 10

* On iOS 10, `FloatingPanelSurfaceView.cornerRadius` isn't not automatically masked with the top rounded corners  because of `UIVisualEffectView` issue. See https://forums.developer.apple.com/thread/50854. 
So you need to draw top rounding corners of your content.  Here is an example in Examples/Maps.
```swift
override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    if #available(iOS 10, *) {
        visualEffectView.layer.cornerRadius = 9.0
        visualEffectView.clipsToBounds = true
    }
}
```
* If you sets clear color to `FloatingPanelSurfaceView.backgroundColor`, please note the bottom overflow of your content on bouncing at full position. To prevent it, you need to expand your content. For example, See Example/Maps App's Auto Layout settings of `UIVisualEffectView` in Main.storyboard.

## Author

Shin Yamamoto <shin@scenee.com> | [@scenee](https://twitter.com/scenee)

## License

FloatingPanel is available under the MIT license. See the LICENSE file for more info.
