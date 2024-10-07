// Copyright 2025 the FloatingPanel authors. All rights reserved. MIT license.

import FloatingPanel
import SwiftUI
import UIKit

struct MainView: View {
    @State private var shouldMoveFullState = false
    @State private var panelLayout: FloatingPanelLayout? = MyFloatingPanelLayout()

    var body: some View {
        ZStack {
            Color.orange
                .ignoresSafeArea()
                .floatingPanel(
                    coordinator: MyPanelCoordinator.self,
                    onEvent: onFloatingPanelEvent(event:)
                ) { proxy in
                    ContentView(proxy: proxy)
                }
                .floatingPanelSurfaceAppearance(.transparent())
                .floatingPanelLayout(panelLayout)
                .environment(\.shouldMoveFullState, shouldMoveFullState)

            VStack(spacing: 32) {
                Button("Move to full") {
                    shouldMoveFullState = true
                }
                Button {
                    withAnimation(.interactiveSpring) {
                        if panelLayout is MyFloatingPanelLayout {
                            panelLayout = nil
                        } else {
                            panelLayout = MyFloatingPanelLayout()
                        }
                    }
                } label: {
                    if panelLayout is MyFloatingPanelLayout {
                        Text("Switch to Default layout")
                    } else {
                        Text("Switch to My layout")
                    }
                }
            }
        }
    }

    private func onFloatingPanelEvent(event: MyPanelCoordinator.Event) {
        switch event {
        case .beginMoving(let state) where state == .full:
            shouldMoveFullState = false
        default:
            break
        }
    }
}

extension EnvironmentValues {
    @Entry var shouldMoveFullState = false
}

// A custom coordinator object which handles panel context updates and setting up `FloatingPanelControllerDelegate` methods
class MyPanelCoordinator: FloatingPanelCoordinator {
    enum Event {
        case beginMoving(FloatingPanelState)
    }

    let action: (Event) -> Void
    lazy var delegate: FloatingPanelControllerDelegate? = self
    let proxy: FloatingPanelProxy

    required init(action: @escaping (MyPanelCoordinator.Event) -> Void) {
        self.action = action
        self.proxy = .init(controller: FloatingPanelController())
    }

    func setupFloatingPanel<Main, Content>(
        mainHostingController: UIHostingController<Main>,
        contentHostingController: UIHostingController<Content>
    ) where Main: View, Content: View {
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
    ) where Representable: UIViewControllerRepresentable {
        let shouldMoveFullState = context.environment[keyPath: \.shouldMoveFullState]
        if shouldMoveFullState {
            if #available(iOS 18.0, *) {
                let animation = context.transaction.animation ?? .spring(response: 0.25, dampingFraction: 0.9)
                UIView.animate(animation) {
                    proxy.move(to: .full, animated: false)
                }
            } else {
                proxy.move(to: .full, animated: true)
            }
        }
    }
}

extension MyPanelCoordinator: FloatingPanelControllerDelegate {
    func floatingPanelWillBeginAttracting(_ fpc: FloatingPanelController, to state: FloatingPanelState) {
        action(.beginMoving(fpc.state))
    }
}

// A custom layout object
class MyFloatingPanelLayout: FloatingPanelLayout {
    let position: FloatingPanelPosition = .bottom
    let initialState: FloatingPanelState = .tip
    let anchors: [FloatingPanelState: FloatingPanelLayoutAnchoring] = [
        .full: FloatingPanelLayoutAnchor(absoluteInset: 16.0, edge: .top, referenceGuide: .safeArea),
        .half: FloatingPanelLayoutAnchor(fractionalInset: 0.4, edge: .bottom, referenceGuide: .safeArea),
        .tip: FloatingPanelLayoutAnchor(absoluteInset: 44.0, edge: .bottom, referenceGuide: .safeArea),
    ]
}

#Preview("MainView") {
    MainView()
}
