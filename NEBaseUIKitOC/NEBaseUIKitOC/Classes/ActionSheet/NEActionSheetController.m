// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEActionSheetController.h"
#import "NEActionSheetTransitioningDelegate.h"

@interface NEActionSheetController ()
@property (nonatomic, strong) NEActionSheetTransitioningDelegate *sheetTransitioning;
@property (nonatomic, strong) CAShapeLayer *navigationBarMask;
@end

@implementation NEActionSheetController

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController {
  self = [super initWithRootViewController:rootViewController];
  if (self) {
    _dismissOnTouchOutside = YES;
    _sheetTransitioning = [[NEActionSheetTransitioningDelegate alloc] init];
    self.modalPresentationStyle = UIModalPresentationCustom;
    self.transitioningDelegate = _sheetTransitioning;
    self.navigationBar.clipsToBounds = YES;
    self.navigationBar.translucent = NO;
    self.navigationBar.tintColor = UIColor.blackColor;

    if (@available(iOS 15.0, *)) {
      UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
      [appearance configureWithOpaqueBackground];
      appearance.titleTextAttributes = @{
        NSForegroundColorAttributeName: UIColor.blackColor,
        NSFontAttributeName: [UIFont systemFontOfSize:16]
      };
      appearance.backgroundColor = UIColor.whiteColor;
      self.navigationBar.standardAppearance = appearance;
      self.navigationBar.scrollEdgeAppearance = appearance;
    }

    _navigationBarMask = [CAShapeLayer layer];
  }
  return self;
}

- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  self.navigationBar.frame = CGRectMake(0, 0, self.view.frame.size.width, 48);
  _navigationBarMask.frame = self.navigationBar.bounds;
  UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:self.navigationBar.bounds
                                               byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight
                                                     cornerRadii:CGSizeMake(12, 12)];
  _navigationBarMask.path = maskPath.CGPath;
  self.navigationBar.layer.mask = _navigationBarMask;
}

@end
