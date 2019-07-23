//
//  Created by Shin Yamamoto on 2018/09/18.
//  Copyright © 2018 Shin Yamamoto. All rights reserved.
//

import UIKit
import FloatingPanel

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FloatingPanelSurfaceView.appearance().shadowHidden = false
        FloatingPanelSurfaceView.appearance().cornerRadius = 6.0
        // FloatingPanelSurfaceView.appearance().backgroundColor = .lightGray
        // FloatingPanelBackdropView.appearance().backgroundColor = .red
        // GrabberHandleView.appearance().barColor = .red
        return true
    }
}
