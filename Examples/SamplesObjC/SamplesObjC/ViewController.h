//
//  ViewController.h
//  SamplesObjC
//
//  Created by Shin Yamamoto on 2018/12/07.
//  Copyright © 2018 Shin Yamamoto. All rights reserved.
//

#import <UIKit/UIKit.h>
@import FloatingPanel;

@interface ViewController : UIViewController
@end


@interface MyFloatingPanelLayout: NSObject<FloatingPanelLayout>
@end

@interface MyFloatingPanelBehavior: NSObject<FloatingPanelBehavior>
@end
