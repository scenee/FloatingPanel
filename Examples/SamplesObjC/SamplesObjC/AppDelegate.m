// Copyright 2018 the FloatingPanel authors. All rights reserved. MIT license.

#import "AppDelegate.h"
@import FloatingPanel;

@interface AppDelegate ()
@end

@implementation AppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey,id> *)launchOptions
{
    [FloatingPanelController enableDismissToRemove];
    return YES;
}
@end
