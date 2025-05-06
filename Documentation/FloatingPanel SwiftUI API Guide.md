# FloatingPanel SwiftUI API Guide

## Table of Contents

<details>
<summary>
Click here
</summary>

- [Table of Contents](#table-of-contents)
- [Requirements](#requirements)
- [Goals](#goals)
- [Non-Goals](#non-goals)
- [Design Principles](#design-principles)
- [Development and compatibility](#development-and-compatibility)
- [API implementation considerations](#api-implementation-considerations)
- [Supplemental view approach rather than modal presentation](#supplemental-view-approach-rather-than-modal-presentation)
- [Leveraging the view modifiers](#leveraging-the-view-modifiers)
- [`FloatingPanelCoordinator`: The key component](#floatingpanelcoordinator-the-key-component)
  - [Core Responsibilities](#core-responsibilities)
  - [Default Implementation](#default-implementation)
  - [Use Cases](#use-cases)
    - [1. Custom Event Handling](#1-custom-event-handling)
    - [2. Responding to Environment Changes](#2-responding-to-environment-changes)
    - [3. Modal Presentation](#3-modal-presentation)
  - [Best Practices](#best-practices)
    - [Define Meaningful Events](#define-meaningful-events)
    - [Use Lazy Delegate Initialization](#use-lazy-delegate-initialization)
    - [Handle Environment Changes Efficiently](#handle-environment-changes-efficiently)
    - [Coordinate with SwiftUI Animations](#coordinate-with-swiftui-animations)

</details>

## Requirements

- iOS 15 or later
- Xcode 16 or later

> [!NOTE]
> The SwiftUI API can be used on iOS 14, but it's out of the supported versions.

## Goals

1. Build SwiftUI APIs on top of our battle-tested UIKit implementation
2. Enable smooth interoperability between UIKit and SwiftUI components
3. Provide an idiomatic SwiftUI developer experience

## Non-Goals

1. Complete reimplementation of FloatingPanel solely using SwiftUI APIs
2. Cover all UIKit-specific customization options through SwiftUI APIs

## Design Principles

- APIs designed to maximize user control and flexibility
- FloatingPanel designed as a supplemental view rather than a modal presentation as the same as UIKit implementation.
- Declarative modifiers that follow SwiftUI conventions
- Environment-based configuration patterns
- Seamless integration with SwiftUI's view hierarchy
- Implementation of essential APIs only, with plans to expand based on user requests -- we welcome your feedback!

## Development and compatibility

- Built targeting Xcode 16 as the primary development environment
  - Maintains backward compatibility with Xcode 14/15 for UIKit support but gradually migrates to full Xcode 16+ features
- iOS version compatibility:
  - Our SwiftUI integration builds for iOS 14 or later, but has been primarily tested on iOS 15+

## API implementation considerations

- We've determined that providing an integration API is the optimal approach with enhanced UIKit integration (as of iOS 18)
- Currently not using `@Entry` due to compatibility constraints

## Supplemental view approach rather than modal presentation

FloatingPanel has been designed as a supplemental view rather than a modal presentation since its first release in the UIKit implementation. The SwiftUI APIs follow this same principle, allowing users to leverage this library for use cases not covered by Apple's built-in APIs.

For instance, the SwiftUI API deliberately doesn't provide an `isPresented` binding argument in the `floatingPanel(coordinator:onEvent:content:)` modifier. If you want to hide a floating panel, use the `.hidden` anchor state instead, which enables you to hide a floating panel while keeping the content pre-rendered outside the visible screen area.

## Leveraging the view modifiers

The SwiftUI APIs provide a variety of view modifiers. Consider using these modifiers before implementing custom logic in your `FloatingPanelCoordinator` object.

## `FloatingPanelCoordinator`: The key component

The `FloatingPanelCoordinator` protocol is a key component in the FloatingPanel's SwiftUI integration, serving as the bridge between SwiftUI's declarative UI framework and FloatingPanel's UIKit-based implementation.

It manages the connection between the SwiftUI view hierarchy and the underlying `FloatingPanelController`, handling setup, configuration, and event dispatching for floating panels within SwiftUI applications.

This secion explains the `FloatingPanelCoordinator` protocol in detail, including its purpose, implementation patterns, and common use cases to help you effectively integrate floating panels into your SwiftUI applications.

### Core Responsibilities

A `FloatingPanelCoordinator` implementation handles the following key responsibilities:

1. **Creation and Configuration**: Initializing and configuring the underlying `FloatingPanelController` instance
2. **View Hierarchy Management**: Setting up the relationship between the main SwiftUI view and the panel content view
3. **State Management**: Handling panel state transitions and position changes
4. **Event Handling**: Capturing panel events and dispatching them back to SwiftUI
5. **Environment Changes**: Responding to SwiftUI environment changes and updating the panel accordingly

### Default Implementation

The library provides [`FloatingPanelDefaultCoordinator`](Sources/SwiftUI/FloatingPanelCoordinator.swift) as a standard implementation for basic panel integration.

`FloatingPanelCoordinator` intentionally does not provide default implementations for its required methods. This design choice avoids implicit behavior when handling the `FloatingPanelController`. When implementing a custom coordinator instead of using `FloatingPanelDefaultCoordinator`, users can clearly understand the requirements of the `FloatingPanelCoordinator` protocol and how the `FloatingPanelController` should be managed in their custom implementation.

### Use Cases

#### 1. Custom Event Handling

Define a custom coordinator to handle panel events:

```swift
struct ContentView: View {
    var body: some View {
        Color.blue
            .ignoresSafeArea()
            .floatingPanel(
                coordinator: MyPanelCoordinator.self,
                onEvent: handlePanelEvent
            ) { proxy in
                PanelContent(proxy: proxy)
            }
    }
    
    func handlePanelEvent(_ event: MyPanelCoordinator.Event) {
        switch event {
        case .willChangeState(let state):
            print("Panel will change to \(state)")
        case .didChangeState(let state):
            print("Panel changed to \(state)")
        }
    }
}

class MyPanelCoordinator: FloatingPanelCoordinator {
    enum Event {
        case willChangeState(FloatingPanelState)
        case didChangeState(FloatingPanelState)
    }
    
    let action: (Event) -> Void
    lazy var delegate: FloatingPanelControllerDelegate? = self
    let proxy: FloatingPanelProxy
    
    ...
}

extension MyPanelCoordinator: FloatingPanelControllerDelegate {
    func floatingPanelWillBeginDragging(_ fpc: FloatingPanelController) {
        action(.willChangeState(fpc.state))
    }
    
    func floatingPanelDidChangeState(_ fpc: FloatingPanelController) {
        action(.didChangeState(fpc.state))
    }
}
```

#### 2. Responding to Environment Changes

Create a coordinator that responds to SwiftUI environment changes:

```swift
class EnvironmentAwarePanelCoordinator: FloatingPanelCoordinator {
    ...
    func onUpdate<Representable>(
        context: UIViewControllerRepresentableContext<Representable>
    ) where Representable: UIViewControllerRepresentable {
        // Access environment values and update the panel
        let shouldMoveToFullState = context.environment.someCustomValue
        if shouldMoveToFullState {
            proxy.move(to: .full, animated: true)
        }
    }
}
```

#### 3. Modal Presentation

Implement a coordinator that presents the panel modally:

```swift
class ModalPanelCoordinator: FloatingPanelCoordinator {
    enum Event {
        case dismissed
    }
    
    let action: (Event) -> Void
    let proxy: FloatingPanelProxy
    lazy var delegate: FloatingPanelControllerDelegate? = nil
    
    ...
    func setupFloatingPanel<Main, Content>(
        mainHostingController: UIHostingController<Main>,
        contentHostingController: UIHostingController<Content>
    ) where Main: View, Content: View {
        // Set up the content
        contentHostingController.view.backgroundColor = .clear
        controller.set(contentViewController: contentHostingController)
        
        // Present the panel modally
        Task { @MainActor in
            controller.isRemovalInteractionEnabled = true
            controller.delegate = self
            mainHostingController.present(controller, animated: true)
        }
    }
    
    ...
}

extension ModalPanelCoordinator: FloatingPanelControllerDelegate {
    func floatingPanelDidEndRemove(_ fpc: FloatingPanelController) {
        action(.dismissed)
    }
}
```

### Best Practices

#### Define Meaningful Events

Design your `Event` type to capture meaningful panel interactions that SwiftUI views need to respond to, but avoid over-engineering with too many event types.

#### Use Lazy Delegate Initialization

Initialize `delegate` lazily when you want your coordinator to implement `FloatingPanelControllerDelegate`:

```swift
lazy var delegate: FloatingPanelControllerDelegate? = self
```

#### Handle Environment Changes Efficiently

In your `onUpdate` method, compare environment values with current panel state before making changes to avoid unnecessary updates.

#### Coordinate with SwiftUI Animations

Respect SwiftUI's animation context when moving the panel on iOS 18 or later:

```swift
func onUpdate<Representable>(
    context: UIViewControllerRepresentableContext<Representable>
) where Representable: UIViewControllerRepresentable {
    if #available(iOS 18.0, *) {
        let animation = context.transaction.animation ?? .spring(response: 0.25, dampingFraction: 0.9)
        UIView.animate(animation) {
            proxy.move(to: .full, animated: false)
        }
    } else {
        ...
    }
}
```
