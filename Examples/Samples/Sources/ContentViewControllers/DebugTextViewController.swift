// Copyright 2018 the FloatingPanel authors. All rights reserved. MIT license.

import UIKit

final class DebugTextViewController: UIViewController, UITextViewDelegate {
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var textViewTopConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()
        textView.delegate = self
        print("viewDidLoad: TextView --- ", textView.contentOffset, textView.contentInset)

        textView.contentInsetAdjustmentBehavior = .never
    }

    override func viewWillLayoutSubviews() {
        print("viewWillLayoutSubviews: TextView --- ", textView.contentOffset, textView.contentInset, textView.frame)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        print("viewDidLayoutSubviews: TextView --- ", textView.contentOffset, textView.contentInset, textView.frame)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("TextView --- ", textView.contentOffset, textView.contentInset, textView.frame)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        print("TextView --- ", scrollView.contentOffset, scrollView.contentInset)
        print("TextView --- ", scrollView.adjustedContentInset)
    }

    @IBAction func toggleTopMargin(_ sender: UISwitch) {
        if sender.isOn {
            textViewTopConstraint.constant = 160
        } else {
            textViewTopConstraint.constant = 16
        }
    }

    @IBAction func close(sender: UIButton) {
        // (self.parent as? FloatingPanelController)?.removePanelFromParent(animated: true, completion: nil)
        dismiss(animated: true, completion: nil)
    }
}
