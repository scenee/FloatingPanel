// Copyright 2018 the FloatingPanel authors. All rights reserved. MIT license.

import UIKit

class InspectableViewController: UIViewController {
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        print(">>> Content View: viewWillLayoutSubviews", layoutInsets)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        print(">>> Content View: viewDidLayoutSubviews", layoutInsets)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print(">>> Content View: viewWillAppear", layoutInsets)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print(">>> Content View: viewDidAppear", view.bounds, layoutInsets)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print(">>> Content View: viewWillDisappear")
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print(">>> Content View: viewDidDisappear")
    }

    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
        print(">>> Content View: willMove(toParent: \(String(describing: parent))")
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        print(">>> Content View: didMove(toParent: \(String(describing: parent))")
    }
    public override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        print(">>> Content View: willTransition(to: \(newCollection), with: \(coordinator))", layoutInsets)
    }
}
