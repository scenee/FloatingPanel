// Copyright 2018 the FloatingPanel authors. All rights reserved. MIT license.

import UIKit
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        let rootVC = UIViewController(nibName: nil, bundle: nil)
        rootVC.view.backgroundColor = .gray

        let window = UIWindow()
        window.rootViewController = rootVC
        window.makeKeyAndVisible()
        self.window = window

        return true
    }
}
