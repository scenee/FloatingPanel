// Copyright 2018-Present Shin Yamamoto. All rights reserved. MIT license.

import UIKit
import FloatingPanel

final class DetailViewController: InspectableViewController {
    @IBOutlet weak var modeChangeView: UIStackView!
    @IBOutlet weak var intrinsicHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var closeButton: UIButton!
    @IBAction func close(sender: UIButton) {
        // (self.parent as? FloatingPanelController)?.removePanelFromParent(animated: true, completion: nil)
        dismiss(animated: true, completion: nil)
    }

    @IBAction func buttonPressed(_ sender: UIButton) {
        switch sender.titleLabel?.text {
        case "Show":
            performSegue(withIdentifier: "ShowSegue", sender: self)
        case "Present Modally":
            performSegue(withIdentifier: "PresentModallySegue", sender: self)
        default:
            break
        }
    }
    @IBAction func modeChanged(_ sender: Any) {
        guard let fpc = parent as? FloatingPanelController else { return }
        fpc.contentMode = (fpc.contentMode == .static) ? .fitToBounds : .static
    }

    @IBAction func tapped(_ sender: Any) {
        print("Detail panel is tapped!")
    }
    @IBAction func swipped(_ sender: Any) {
        print("Detail panel is swipped!")
    }
    @IBAction func longPressed(_ sender: Any) {
        print("Detail panel is longPressed!")
    }
}
