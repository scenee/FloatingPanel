# ChangeLog

## [3.2.0](https://github.com/scenee/FloatingPanel/releases/tag/3.2.0)

### Added

- Added support for dynamic content updates in SwiftUI (#675).

### Fixed

- Fixed shadow rendering issues on iOS 26.
- Fixed animation glitches in example apps on iOS 26.

### Changed

- Updated CI to use Xcode 26.0.1 for all builds.
- Improved SamplesSwiftUI example app.

## [3.1.0](https://github.com/scenee/FloatingPanel/releases/tag/3.1.0)

### Added

- Added support for configuring `UICornerConfiguration` when running on iOS 26 so surfaces can adopt the latest corner styles (#664).
- Expanded Core test coverage with new cases for scroll offset resets and `statePublisher` delivery to guard against regressions.

### Changed

- **Restored compatibility with iOS 12** by lowering the deployment target across the project, Swift Package manifest, and CocoaPods spec, and by making Combine usage conditional (#674).

## [3.0.1](https://github.com/scenee/FloatingPanel/releases/tag/3.0.1)

### Changed

- Refined the DocC documentation landing page for the new SwiftUI APIs.

### Fixed

- Corrected the CocoaPods spec so the SwiftUI sources are packaged properly.

## [3.0.0](https://github.com/scenee/FloatingPanel/releases/tag/3.0.0)

### Breaking Changes

- The minimum deployment target is now **iOS 13.0**.
- Dropped support for building with **Xcode 13.4.1**.

### Added

- Introduced new SwiftUI APIs.
- Added `Documentation/FloatingPanel SwiftUI API Guide.md`.
- Added `Documentation/FloatingPanel API Guide.md`, migrating from `README.md`.
- Added `Examples/SamplesSwiftUI` example app.
- Added `FloatingPanelControllerDelegate/floatingPanel(_:animatorForMovingTo:)`.
- Added partial `swift-format` support via the BuildTools plugin package.  
  **Limitation:** Formatting currently applies only to the source code for the
  new SwiftUI API and the `SamplesSwiftUI` example app.
- Enabled README preview mode in Xcode via `.xcodesamplecode.plist`.

### Changed

- Updated `README.md` to cover the new SwiftUI APIs.
- Moved UIKit-specific details to `Documentation/FloatingPanel API Guide.md`.
- Updated DocC documentation for the new SwiftUI APIs.
- Moved the `assets` folder.

## [2.8.8](https://github.com/scenee/FloatingPanel/releases/tag/2.8.8)

### Bugfixes

- Allowed slight deviation when checking for anchor position.
- Addressed #661 issue since v2.8.0  (#662)

## [2.8.7](https://github.com/scenee/FloatingPanel/releases/tag/2.8.7)

:warning: [NOTICE] This release contains a regression. Please use v2.8.8 instead.

### Bugfixes

- Disallow interrupting the panel interaction while bouncing over the most
  expanded state (#652)
- Reset initialScrollOffset after the attracting animation ends (#659)

## [2.8.6](https://github.com/scenee/FloatingPanel/releases/tag/2.8.6)

### Bugfixes

- Fix doc comment errors (#643)

## [2.8.5](https://github.com/scenee/FloatingPanel/releases/tag/2.8.5)

### Bugfixes

- Replaced fatal errors in transitionDuration delegate methods (#642)

## [2.8.4](https://github.com/scenee/FloatingPanel/releases/tag/2.8.4)

### Bugfixes

- Fixed an inappropriate condition to determine scrolling content (#633)

## [2.8.3](https://github.com/scenee/FloatingPanel/releases/tag/2.8.3)

### Bugfixes

- Fix the scroll tracking of WKWebView on iOS 17.4 (#630)
- Fix a broken panel layout with a compositional collection view (#634)
- Fix a compilation error in Xcode 16 by @WillBishop (#636)

## [2.8.2](https://github.com/scenee/FloatingPanel/releases/tag/2.8.2)

### New features

- Enabled to define and use a subclass object of BackdropView (#617)

### Improvements

- Fixed the scroll locking behavior by @futuretap (#615)
- Supported Xcode 15.2 on the GitHub Actions (#619)

### Bugfixes

- Added a possible fix for #586
- Fixed a bug that state was not changed property after v2.8.1

## [2.8.1](https://github.com/scenee/FloatingPanel/releases/tag/2.8.1)

- Fixed an invalid behavior after switching to a new layout object (#611)

## [2.8.0](https://github.com/scenee/FloatingPanel/releases/tag/2.8.0)

### Breaking changes

- The minimum deployment target of this library became iOS 11.0 on this release.

### New features

- Added the new delegate method, `floatingPanel(_:shouldAllowToScroll:in:)`.

### Improvements

- Enabled content scrolling in non-expanded states (#455)

### Bugfixes

- Fixed CGFloat.rounded(by:) for a floating point error
- Fixed scroll offset reset when moving in grabber area
- Fixed a panel not moving when picked up in certain area
- Fixed errors of offset value from a state position

## [2.7.0](https://github.com/scenee/FloatingPanel/releases/tag/2.7.0)

### Breaking changes

- Calls the `floatingPanelDidMove` delegate method at the end of the move
  interaction.
- Calls the `floatingPanelDidEndDragging` delegate method after
  `FloatingPanelController.state` changes when `willAttract` is `false`.
- Sets `isAttracting` to `true` even when moving between states by
  `FloatingPanelController.move(to:animated:completion)` except for moves from
  or to `.hidden`.
- Do not reset the scroll offset of its tracking scroll view when a user moves a
  panel outside its scroll view or on the navigation bar above it.

## Improvements

- Added `FloatingPanelPanGestureRecognizer.delegateOrigin`  to allow to access
  the default delegate implementations (It's useful when using `delegateProxy`).

## Bugfixes

- Retains scroll view position while moving between states (#587)
- Fixed invalid scroll offsets after moving between states
- Calls `floatingPanelWillRemove` delegate method when a panel is removed from a
  window

