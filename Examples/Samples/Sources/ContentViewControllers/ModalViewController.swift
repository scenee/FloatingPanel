// Copyright 2018 the FloatingPanel authors. All rights reserved. MIT license.

import UIKit
import FloatingPanel

final class ModalViewController: UIViewController, FloatingPanelControllerDelegate {
    var fpc: FloatingPanelController!
    var consoleVC: DebugTextViewController!

    @IBOutlet weak var safeAreaView: UIView!

    var isNewlayout: Bool = false

    override func viewDidLoad() {
        // Initialize FloatingPanelController
        fpc = FloatingPanelController()
        fpc.delegate = self

        let appearance = SurfaceAppearance()
        appearance.cornerRadius = 6.0
        fpc.surfaceView.appearance = appearance

        // Set a content view controller and track the scroll view
        let consoleVC = storyboard?.instantiateViewController(withIdentifier: "ConsoleViewController") as! DebugTextViewController
        fpc.set(contentViewController: consoleVC)
        fpc.track(scrollView: consoleVC.textView)

        self.consoleVC = consoleVC

        //  Add FloatingPanel to self.view
        fpc.addPanel(toParent: self, at: view.subviews.firstIndex(of: safeAreaView) ?? -1)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        //  Remove FloatingPanel from a view
        fpc.removePanelFromParent(animated: false)
    }

    @IBAction func close(sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func moveToFull(sender: UIButton) {
        fpc.move(to: .full, animated: true)
    }
    @IBAction func moveToHalf(sender: UIButton) {
        fpc.move(to: .half, animated: true)
    }
    @IBAction func moveToTip(sender: UIButton) {
        fpc.move(to: .tip, animated: true)
    }
    @IBAction func moveToHidden(sender: UIButton) {
        fpc.move(to: .hidden, animated: true)
    }
    @IBAction func updateLayout(_ sender: Any) {
        isNewlayout = !isNewlayout
        UIView.animate(withDuration: 0.5) {
            self.fpc.invalidateLayout()
        }
    }

    func floatingPanel(_ vc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout {
        return (isNewlayout) ? ModalSecondLayout() : FloatingPanelBottomLayout()
    }

    class ModalSecondLayout: FloatingPanelLayout {
        let position: FloatingPanelPosition = .bottom
        let initialState: FloatingPanelState = .half
        let anchors: [FloatingPanelState : FloatingPanelLayoutAnchoring] = [
            .full: FloatingPanelLayoutAnchor(absoluteInset: 16.0, edge: .top, referenceGuide: .safeArea),
            .half: FloatingPanelLayoutAnchor(absoluteInset: 262, edge: .top, referenceGuide: .safeArea),
            .tip: FloatingPanelLayoutAnchor(absoluteInset: 44.0, edge: .bottom, referenceGuide: .safeArea)
        ]
    }
}
