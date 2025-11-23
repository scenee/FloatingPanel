// Copyright 2025 the FloatingPanel authors. All rights reserved. MIT license.

import FloatingPanel
import SwiftUI
import UIKit
import os.log

struct MainView: View {
    enum CardContent: String, CaseIterable, Identifiable {
        case list
        case detail

        var id: String { rawValue }
    }
    @State private var panelLayout: FloatingPanelLayout? = MyFloatingPanelLayout()
    @State private var panelState: FloatingPanelState?
    @State private var selectedContent: CardContent = .list

    var body: some View {
        ZStack {
            Color.orange
                .ignoresSafeArea()
            VStack(spacing: 32) {
                Picker("type", selection: $selectedContent) {
                    ForEach(CardContent.allCases) {
                        type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                Button("Move to full") {
                    withAnimation(.interactiveSpring) {
                        panelState = .full
                    }
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
                Spacer()
            }
        }
        .floatingPanel(
            coordinator: MyPanelCoordinator.self
        ) { proxy in
            switch selectedContent {
            case .list:
                ContentView(proxy: proxy)
            case .detail:
                HStack {
                    Spacer()
                    VStack {
                        Text("Detail content")
                            .padding(.top, 32)
                        Spacer()
                    }
                    Spacer()
                }
                .padding()
                .background {
                    BackgroundView()
                }
            }
        }
        .floatingPanelSurfaceAppearance(.transparent())
        .floatingPanelLayout(panelLayout)
        .floatingPanelState($panelState)
        .onChange(of: panelState) { newValue in
            Logger().debug("Panel state changed: \(newValue ?? .hidden)")
        }
    }
}

// A custom coordinator object which handles panel context updates and setting up `FloatingPanelControllerDelegate` methods
class MyPanelCoordinator: FloatingPanelCoordinator {
    enum Event {}

    let action: (Event) -> Void
    let proxy: FloatingPanelProxy

    required init(action: @escaping (MyPanelCoordinator.Event) -> Void) {
        self.action = action
        self.proxy = .init(controller: FloatingPanelController())
    }

    func setupFloatingPanel<Main, Content>(
        mainHostingController: UIHostingController<Main>,
        contentHostingController: UIHostingController<Content>
    ) where Main: View, Content: View {
        // Set this as the delegate object
        controller.delegate = self

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

extension MyPanelCoordinator: FloatingPanelControllerDelegate {
    func floatingPanelDidChangeState(_ fpc: FloatingPanelController) {
        // NOTE: This timing is difference from one of the change of the binding value
        // to `floatingPanelState(_:)` modifier
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
