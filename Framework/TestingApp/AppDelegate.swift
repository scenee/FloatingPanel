//
//  Created by Shin Yamamoto on 2018/11/01.
//  Copyright © 2018 Shin Yamamoto. All rights reserved.
//

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
