// Copyright 2018 the FloatingPanel authors. All rights reserved. MIT license.

#import "ViewController.h"
@import FloatingPanel;

// Defining a custom FloatingPanelState
@interface FloatingPanelState(Extended)
+ (FloatingPanelState *)LastQuart;
@end

@implementation FloatingPanelState(Extended)
static FloatingPanelState *_lastQuart;
+ (FloatingPanelState *)LastQuart {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _lastQuart = [[FloatingPanelState alloc] initWithRawValue:@"lastquart" order:750];
    });
    return _lastQuart;
}
@end

@interface ViewController()<FloatingPanelControllerDelegate>
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    FloatingPanelController *fpc = [[FloatingPanelController alloc] init];
    [fpc setContentViewController:nil];
    [fpc trackScrollView:nil];
    [fpc setDelegate:self];

    [fpc setLayout: [MyFloatingPanelLayout new]];
    [fpc setBehavior:[MyFloatingPanelBehavior new]];
    [fpc setRemovalInteractionEnabled:NO];

    [fpc addPanelToParent:self at:self.view.subviews.count  animated:NO];
    [fpc moveToState:FloatingPanelState.Tip animated:true completion:nil];

    [self updateAppearance: fpc];
}

- (id<FloatingPanelLayout>)floatingPanel:(FloatingPanelController *)vc layoutFor:(UITraitCollection *)newCollection {
    FloatingPanelBottomLayout *layout = [FloatingPanelBottomLayout new];
    return layout;
}

- (void)updateAppearance: (FloatingPanelController*)fpc
{
    FloatingPanelSurfaceAppearance *appearance = [[FloatingPanelSurfaceAppearance alloc] init];
    appearance.backgroundColor = [UIColor clearColor];
    appearance.cornerRadius = 23.0;
    if (@available(iOS 13.0, *)) {
        fpc.surfaceView.containerView.layer.cornerCurve = kCACornerCurveContinuous;
    }
    FloatingPanelSurfaceAppearanceShadow *shadow = [[FloatingPanelSurfaceAppearanceShadow alloc] init];
    shadow.color = [UIColor redColor];
    shadow.radius = 10.0;
    shadow.spread = 10.0;
    FloatingPanelSurfaceAppearanceShadow *shadow2 = [[FloatingPanelSurfaceAppearanceShadow alloc] init];
    shadow2.color = [UIColor blueColor];
    shadow2.radius = 10.0;
    shadow2.spread = 10.0;

    appearance.shadows = @[shadow, shadow2];
    fpc.surfaceView.appearance = appearance;
}
@end

@implementation  MyFloatingPanelLayout
- (FloatingPanelState *)initialState {
    return FloatingPanelState.Half;
}
- (NSDictionary<FloatingPanelState *, id<FloatingPanelLayoutAnchoring>> *)anchors {
    return @{
        FloatingPanelState.LastQuart: [[FloatingPanelLayoutAnchor alloc] initWithFractionalInset:0.25
                                                                                       edge:FloatingPanelReferenceEdgeTop
                                                                             referenceGuide:FloatingPanelLayoutReferenceGuideSafeArea],
        FloatingPanelState.Half: [[FloatingPanelLayoutAnchor alloc] initWithFractionalInset:0.5
                                                                                       edge:FloatingPanelReferenceEdgeTop
                                                                             referenceGuide:FloatingPanelLayoutReferenceGuideSafeArea],
        FloatingPanelState.Tip: [[FloatingPanelLayoutAnchor alloc] initWithAbsoluteInset:44.0
                                                                                    edge:FloatingPanelReferenceEdgeBottom
                                                                          referenceGuide:FloatingPanelLayoutReferenceGuideSafeArea],
    };
}

- (enum FloatingPanelPosition)position {
    return FloatingPanelPositionBottom;
}
@end


@implementation MyFloatingPanelBehavior
@end
