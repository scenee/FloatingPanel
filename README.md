[![Build Status](https://travis-ci.org/SCENEE/FloatingPanel.svg?branch=master)](https://travis-ci.org/SCENEE/FloatingPanel)
[![Version](https://img.shields.io/cocoapods/v/FloatingPanel.svg)](https://cocoapods.org/pods/FloatingPanel)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Platform](https://img.shields.io/cocoapods/p/FloatingPanel.svg)](https://cocoapods.org/pods/FloatingPanel)
[![Swift 4.1](https://img.shields.io/badge/Swift-4.1-orange.svg?style=flat)](https://swift.org/)
[![Swift 4.2](https://img.shields.io/badge/Swift-4.2-orange.svg?style=flat)](https://swift.org/)

#  FloatingPanel


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
- [Getting Started](#getting-started)
  - [Add a floating panel as a child view controller](#add-a-floating-panel-as-a-child-view-controller)
  - [Present a floating panel as a modality](#present-a-floating-panel-as-a-modality)
- [View hierarchy](#view-hierarchy)
- [Usage](#usage)
  - [Show/Hide a floating panel in a view with your view hierarchy](#showhide-a-floating-panel-in-a-view-with-your-view-hierarchy)
  - [Customize the layout with `FloatingPanelLayout` protocol](#customize-the-layout-with-floatingpanellayout-protocol)
    - [Change the initial position and height](#change-the-initial-position-and-height)
    - [Support your landscape layout](#support-your-landscape-layout)
    - [Use Intrinsic height layout](#use-intrinsic-height-layout)
  - [Customize the behavior with `FloatingPanelBehavior` protocol](#customize-the-behavior-with-floatingpanelbehavior-protocol)
    - [Modify your floating panel's interaction](#modify-your-floating-panels-interaction)
  - [Use a custom grabber handle](#use-a-custom-grabber-handle)
  - [Add tap gestures to the surface or backdrop views](#add-tap-gestures-to-the-surface-or-backdrop-views)
  - [Create an additional floating panel for a detail](#create-an-additional-floating-panel-for-a-detail)
  - [Move a position with an animation](#move-a-position-with-an-animation)
  - [Work your contents together with a floating panel behavior](#work-your-contents-together-with-a-floating-panel-behavior)
- [Notes](#notes)
  - ['Show' or 'Show Detail' Segues from `FloatingPanelController`'s content view controller](#show-or-show-detail-segues-from-floatingpanelcontrollers-content-view-controller)
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

FloatingPanel is written in Swift 4.2. Compatible with iOS 10.0+

## Installation

### CocoaPods

FloatingPanel is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'FloatingPanel'
```

### Carthage

For [Carthage](https://github.com/Carthage/Carthage), add the following to your `Cartfile`:

```ogdl
github "scenee/FloatingPanel"
```

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

You can show a floating panel over UINavigationController from the containnee view controllers as a modality of `.overCurrentContext` style.

NOTE: FloatingPanelController has the custom presentation controller. If you would like to customize the presentation/dismissal, please see [FloatingPanelTransitioning](https://github.com/SCENEE/FloatingPanel/blob/feat-modality/Framework/Sources/FloatingPanelTransitioning.swift).

## View hierarchy

`FloatingPanelController` manages the views as the following view hierarchy.

```
FloatingPanelController.view (FloatingPanelPassThroughView)
 ├─ .backdropView (FloatingPanelBackdropView)
 └─ .surfaceView (FloatingPanelSurfaceView)
          ├─ .contentView  == FloatingPanelController.contentViewController.view
          └─ .grabberHandle (GrabberHandleView)
```

## Usage

### Show/Hide a floating panel in a view with your view hierarchy

```swift
// Add the controller and the managed views to a view controller.
// From the second time, just call `show(animated:completion)`.
view.addSubview(fpc.view)

fpc.view.frame = view.bounds // MUST
// In addition, Auto Layout constraints are highly recommended.
// Because it makes the layout more robust on trait collection change.
//
//     fpc.view.translatesAutoresizingMaskIntoConstraints = false
//     NSLayoutConstraint.activate([...])
// 

parent.addChild(fpc)

// Show a floating panel to the initial position defined in your `FloatingPanelLayout` object.
fpc.show(animated: true) {

    // Only for the first time
    self.didMove(toParent: self)
}

...

// Hide it
fpc.hide(animated: true) {

    // Remove it if needed
    self.willMove(toParent: nil)
    self.view.removeFromSuperview()
    self.removeFromParent()
}
```

NOTE: `FloatingPanelController` wraps `show`/`hide` with `addPanel`/`removePanelFromParent` for easy-to-use. But `show`/`hide` are more convenience for your app.

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
            surfaceView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuid.leftAnchor, constant: 8.0),
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

### Use a custom grabber handle

```swift
let myGrabberHandleView = MyGrabberHandleView()
fpc.surfaceView.grabberHandle.isHidden = true
fpc.surfaceView.addSubview(myGrabberHandleView)
```

### Add tap gestures to the surface or backdrop views

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
