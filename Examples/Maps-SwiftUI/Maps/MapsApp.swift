// Copyright 2021 the FloatingPanel authors. All rights reserved. MIT license.

import SwiftUI
import FloatingPanel

@main
struct MapsApp: App {
    var body: some Scene {
        WindowGroup {
            ZStack {
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
    }
    func onFloatingPanelEvent(_ event: MapPanelCoordinator.Event) {}
}

final class MapPanelCoordinator: FloatingPanelCoordinator {
    enum Event {}

    let action: (Event) -> ()
    lazy var delegate: FloatingPanelControllerDelegate? = self
    let proxy: FloatingPanelProxy

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

        // Set the delegate object
        controller.delegate = delegate

        // Set up the content
        contentHostingController.view.backgroundColor = .clear
        controller.set(contentViewController: contentHostingController)

        // Show the panel
        controller.addPanel(toParent: mainHostingController, animated: false)
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
