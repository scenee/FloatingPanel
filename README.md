#  FloatingPanel

FloatingPanel is a simple and easy-to-use UI component for a new interface introduced in Apple Maps, Shortcuts and Stocks app.
The new interface displays the related contents and utilities in parallel as a user wants.

![Maps](https://github.com/SCENEE/FloatingPanel/blob/master/assets/maps.gif)
![Stocks](https://github.com/SCENEE/FloatingPanel/blob/master/assets/stocks.gif)

![Maps(Landscape)](https://github.com/SCENEE/FloatingPanel/blob/master/assets/maps-landscape.gif)

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

### Move a positon with an animation

Move a floating panel to the top and middle of a view while opening and closeing a search bar like Apple Maps.

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

### Make your contents correspond with FloatingPanel behavior

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

### Support your landscape layout with a `FloatingPanelLayout` object

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

### Modify your floating panel's interaction with a `FloatingPanelBehavior` object

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

    func interactionAnimator(to targetPosition: FloatingPanelPosition, with velocity: CGVector) -> UIViewPropertyAnimator {
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

## Author

Shin Yamamoto <shin@scenee.com>

## License

FloatingPanel is available under the MIT license. See the LICENSE file for more info.
