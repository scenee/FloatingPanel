[![Version](https://img.shields.io/cocoapods/v/FloatingPanel.svg)](https://cocoapods.org/pods/FloatingPanel)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Platform](https://img.shields.io/cocoapods/p/FloatingPanel.svg)](https://cocoapods.org/pods/FloatingPanel)
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
- [Usage](#usage)
  - [Customize the layout of a floating panel with  `FloatingPanelLayout` protocol](#customize-the-layout-of-a-floating-panel-with--floatingpanellayout-protocol)
    - [Change the initial position, supported positions and height](#change-the-initial-position-supported-positions-and-height)
    - [Support your landscape layout](#support-your-landscape-layout)
  - [Customize the behavior with `FloatingPanelBehavior` protocol](#customize-the-behavior-with-floatingpanelbehavior-protocol)
    - [Modify your floating panel's interaction](#modify-your-floating-panels-interaction)
  - [Create an additional floating panel for a detail](#create-an-additional-floating-panel-for-a-detail)
  - [Move a positon with an animation](#move-a-positon-with-an-animation)
  - [Make your contents correspond with a floating panel behavior](#make-your-contents-correspond-with-a-floating-panel-behavior)
- [Notes](#notes)
  - [FloatingPanelSurfaceView's issue on iOS 10](#floatingpanelsurfaceviews-issue-on-ios-10)
- [Author](#author)
- [License](#license)

<!-- /TOC -->

## Features

- [x] Simple container view controller
- [x] Fluid animation and gesture handling
- [x] Scroll view tracking
- [x] Common UI elements: Grabber handle, Backdrop and Surface rounding corners
- [x] 2 or 3 anchor positions(full, half, tip)
- [x] Layout customization for all trait environments(i.e. Landscape orientation support)
- [x] Behavior customization
- [x] Free from common issues of Auto Layout and gesture handling

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

        // Add a content view controller.
        let contentVC = ContentViewController()
        fpc.show(contentVC, sender: nil)

        // Track a scroll view(or the siblings) in the content view controller.
        fpc.track(scrollView: contentVC.tableView)

        // Add the views managed by the `FloatingPanelController` object to self.view.
        fpc.addPanel(toParent: self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Remove the views managed by the `FloatingPanelController` object from self.view.
        fpc.removePanelFromParent()
    }
    ...
}
```

## Usage

### Customize the layout of a floating panel with  `FloatingPanelLayout` protocol

#### Change the initial position, supported positions and height

```swift
class ViewController: UIViewController, FloatingPanelControllerDelegate {
    ...
    func floatingPanel(_ vc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout? {
        return MyFloatingPanelLayout()
    }
    ...
}

class MyFloatingPanelLayout: FloatingPanelLayout {
    public var initialPosition: FloatingPanelPosition {
        return .tip
    }
    public var supportedPositions: [FloatingPanelPosition] {
        return [.full, .half, .tip]
    }

    public func insetFor(position: FloatingPanelPosition) -> CGFloat? {
        switch position {
            case .full: return 16.0 # A top inset from safe area
            case .half: return 216.0 # A bottom inset from the safe area
            case .tip: return 44.0 # A bottom inset from the safe area
            default: return nil
        }
    }
}
```

#### Support your landscape layout

```swift
class ViewController: UIViewController, FloatingPanelControllerDelegate {
    ...
    func floatingPanel(_ vc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout? {
        return (newCollection.verticalSizeClass == .compact) ? FloatingPanelLandscapeLayout() : nil
    }
    ...
}

class FloatingPanelLandscapeLayout: FloatingPanelLayout {
    public var initialPosition: FloatingPanelPosition {
        return .tip
    }
    public var supportedPositions: [FloatingPanelPosition] {
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

### Customize the behavior with `FloatingPanelBehavior` protocol

#### Modify your floating panel's interaction

```swift
class ViewController: UIViewController, FloatingPanelControllerDelegate {
    ...
    func floatingPanel(_ vc: FloatingPanelController, behaviorFor newCollection: UITraitCollection) -> FloatingPanelBehavior? {
        return FloatingPanelStocksBehavior()
    }
    ...
}
...

class FloatingPanelStocksBehavior: FloatingPanelBehavior {
    var velocityThreshold: CGFloat {
        return 15.0
    }

    func interactionAnimator(_ fpc: FloatingPanelController, to targetPosition: FloatingPanelPosition, with velocity: CGVector) -> UIViewPropertyAnimator {
        let damping = self.damping(with: velocity)
        let springTiming = UISpringTimingParameters(dampingRatio: damping, initialVelocity: velocity)
        return UIViewPropertyAnimator(duration: 0.5, timingParameters: springTiming)
    }
    ...
}
```

### Create an additional floating panel for a detail

```swift
class ViewController: UIViewController, FloatingPanelControllerDelegate {
    var searchPanelVC: FloatingPanelController!
    var detailPanelVC: FloatingPanelController!

    override func viewDidLoad() {
        // Setup Search panel
        self.searchPanelVC = FloatingPanelController()

        let searchVC = SearchViewController()
        self.searchPanelVC.show(searchVC, sender: nil)
        self.searchPanelVC.track(scrollView: contentVC.tableView)

        self.searchPanelVC.addPanel(toParent: self)

        // Setup Detail panel
        self.detailPanelVC = FloatingPanelController()

        let contentVC = ContentViewController()
        self.detailPanelVC.show(contentVC, sender: nil)
        self.detailPanelVC.track(scrollView: contentVC.scrollView)

        self.detailPanelVC.addPanel(toParent: self)
    }
    ...
}
```

### Move a positon with an animation

In the following example, I move a floating panel to full or half position while opening or closeing a search bar like Apple Maps.

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

### Make your contents correspond with a floating panel behavior

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
    ...
}
```

## Notes

###  FloatingPanelSurfaceView's issue on iOS 10

* On iOS 10,   `FloatingPanelSurfaceView.cornerRadius` isn't not automatically masked with the top rounded corners  because of UIVisualEffectView issue. See https://forums.developer.apple.com/thread/50854. 
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
* If you sets clear color to `FloatingPanelSurfaceView.backgrounColor`, please note the bottom overflow of your content on bouncing at full position. To prevent it, you need to expand your content. For example, See Example/Maps's Auto Layout settings of UIVisualEffectView in Main.storyborad.

## Author

Shin Yamamoto <shin@scenee.com>

## License

FloatingPanel is available under the MIT license. See the LICENSE file for more info.
