// Copyright 2018-Present Shin Yamamoto. All rights reserved. MIT license.

import UIKit
import FloatingPanel

final class SettingsViewController: InspectableViewController {
    @IBOutlet weak var largeTitlesSwitch: UISwitch!
    @IBOutlet weak var translucentSwitch: UISwitch!
    @IBOutlet weak var versionLabel: UILabel!

    override func viewDidLoad() {
        versionLabel.text = "Version: \(Bundle.main.infoDictionary?["CFBundleVersion"] ?? "--")"
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if #available(iOS 11.0, *) {
            let prefersLargeTitles = navigationController!.navigationBar.prefersLargeTitles
            largeTitlesSwitch.setOn(prefersLargeTitles, animated: false)
        } else {
            largeTitlesSwitch.isEnabled = false
        }
        let isTranslucent = navigationController!.navigationBar.isTranslucent
        translucentSwitch.setOn(isTranslucent, animated: false)
    }

    @IBAction func toggleLargeTitle(_ sender: UISwitch) {
        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = sender.isOn
        }
    }
    @IBAction func toggleTranslucent(_ sender: UISwitch) {
        // White non-translucent navigation bar, supports dark appearance
        if #available(iOS 15, *) {
            let appearance = UINavigationBarAppearance()
            if sender.isOn {
                appearance.configureWithTransparentBackground()
            } else {
                appearance.configureWithOpaqueBackground()
            }
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
        } else {
            navigationController?.navigationBar.isTranslucent = sender.isOn
        }
    }
}

