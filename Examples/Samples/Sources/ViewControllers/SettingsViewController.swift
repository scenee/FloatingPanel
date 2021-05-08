// Copyright 2018-Present Shin Yamamoto. All rights reserved. MIT license.

import UIKit
import FloatingPanel

final class SettingsViewController: InspectableViewController {
    @IBOutlet weak var largeTitlesSwicth: UISwitch!
    @IBOutlet weak var translucentSwicth: UISwitch!
    @IBOutlet weak var versionLabel: UILabel!

    override func viewDidLoad() {
        versionLabel.text = "Version: \(Bundle.main.infoDictionary?["CFBundleVersion"] ?? "--")"
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if #available(iOS 11.0, *) {
            let prefersLargeTitles = navigationController!.navigationBar.prefersLargeTitles
            largeTitlesSwicth.setOn(prefersLargeTitles, animated: false)
        } else {
            largeTitlesSwicth.isEnabled = false
        }
        let isTranslucent = navigationController!.navigationBar.isTranslucent
        translucentSwicth.setOn(isTranslucent, animated: false)
    }

    @IBAction func toggleLargeTitle(_ sender: UISwitch) {
        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = sender.isOn
        }
    }
    @IBAction func toggleTranslucent(_ sender: UISwitch) {
        navigationController?.navigationBar.isTranslucent = sender.isOn
    }
}

