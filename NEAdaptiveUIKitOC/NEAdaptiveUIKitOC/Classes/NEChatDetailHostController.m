// Copyright (c) 2026 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEChatDetailHostController.h"

#import "NEAdaptiveUIKitOCInternals.h"

@interface NEChatDetailHostController ()
@property (nonatomic, assign) BOOL contentVisible;
@end

@implementation NEChatDetailHostController

- (instancetype)initWithNavigationController:(UINavigationController *)navigationController {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _navigationControllerContent = navigationController;
    _contentVisible = NO;
  }
  return self;
}

- (BOOL)shouldAutomaticallyForwardAppearanceMethods {
  return NO;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [self addChildViewController:_navigationControllerContent];
  [self.view addSubview:_navigationControllerContent.view];
  [_navigationControllerContent didMoveToParentViewController:self];
}

- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  _navigationControllerContent.view.frame = self.view.bounds;
}

- (void)setContentVisible:(BOOL)visible animated:(BOOL)animated {
  if (visible == _contentVisible) {
    return;
  }
  _contentVisible = visible;
  [_navigationControllerContent beginAppearanceTransition:visible animated:animated];
  [_navigationControllerContent endAppearanceTransition];
}

@end
