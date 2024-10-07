// Copyright 2021 the FloatingPanel authors. All rights reserved. MIT license.

import SwiftUI
import FloatingPanel

@main
struct MapsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .floatingPanel(
                    coordinator: MapPanelCoordinator.self
                ) { proxy in
                    FloatingPanelContentView(proxy: proxy)
                }
                .floatingPanelSurfaceAppearance(.phone)
                .floatingPanelContentMode(.fitToBounds)
                .floatingPanelContentInsetAdjustmentBehavior(.never)
        }
    }
    func onFloatingPanelEvent(_ event: MapPanelCoordinator.Event) {}
}

final class MapPanelCoordinator: FloatingPanelCoordinator {
    enum Event {}

    let action: (Event) -> ()
    let proxy: FloatingPanelProxy

    private lazy var delegate: FloatingPanelControllerDelegate? = self

    init(action: @escaping (Event) -> ()) {
        self.action = action
        self.proxy = .init(controller: FloatingPanelController())
    }

    public func setupFloatingPanel<Main: View, Content: View>(
        mainHostingController: UIHostingController<Main>,
        contentHostingController: UIHostingController<Content>
    ) {
        mainHostingController.ignoresKeyboardSafeArea()
        contentHostingController.ignoresKeyboardSafeArea()

        if #available(iOS 16, *) {
            // Set the delegate object
            controller.delegate = delegate

            // Set up the content
            contentHostingController.view.backgroundColor = nil
            controller.set(contentViewController: contentHostingController)

            // Show the panel
            controller.addPanel(toParent: mainHostingController, animated: false)
        } else {
            // NOTE: Fix floating panel content view constraints (#549)
            // This issue happens on iOS 15 or earlier.

            // Set the delegate object
            controller.delegate = delegate

            // Set up the content
            contentHostingController.view.backgroundColor = nil
            let contentWrapperViewController = UIViewController()
            contentWrapperViewController.view.addSubview(contentHostingController.view)
            contentWrapperViewController.addChild(contentHostingController)
            contentHostingController.didMove(toParent: contentWrapperViewController)
            controller.set(contentViewController: contentWrapperViewController)

            // Show the panel
            controller.addPanel(toParent: mainHostingController, animated: false)

            contentHostingController.view.translatesAutoresizingMaskIntoConstraints = false
            let bottomConstraint = contentHostingController.view.bottomAnchor.constraint(
                equalTo: contentWrapperViewController.view.bottomAnchor
            )
            bottomConstraint.priority = .defaultHigh
            NSLayoutConstraint.activate([
                contentHostingController.view.topAnchor.constraint(
                    equalTo: contentWrapperViewController.view.topAnchor
                ),
                contentHostingController.view.leadingAnchor.constraint(
                    equalTo: contentWrapperViewController.view.leadingAnchor
                ),
                contentHostingController.view.trailingAnchor.constraint(
                    equalTo: contentWrapperViewController.view.trailingAnchor
                ),
                bottomConstraint
            ])
        }
    }

    func onUpdate<Representable>(
        context: UIViewControllerRepresentableContext<Representable>
    ) where Representable: UIViewControllerRepresentable {}
}

extension MapPanelCoordinator: FloatingPanelControllerDelegate {
    func floatingPanelWillBeginAttracting(
        _ fpc: FloatingPanelController,
        to state: FloatingPanelState
    ) {
        if fpc.state == .full {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}
