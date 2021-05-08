// Copyright 2018 the FloatingPanel authors. All rights reserved. MIT license.

import UIKit

final class NestedScrollViewController: UIViewController {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var nestedScrollView: UIScrollView!

    @IBAction func longPressed(_ sender: Any) {
        print("LongPressed!")
    }
    @IBAction func swipped(_ sender: Any) {
        print("Swipped!")
    }
    @IBAction func tapped(_ sender: Any) {
        print("Tapped!")
    }
}
