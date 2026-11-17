// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "TeamIntroduceViewController.h"
#import <NEBaseUIKitOC/NEAdaptiveDeviceGate.h>
#import "TeamConstant.h"
#import <NEChatKit/NEConstant.h>
#import <NEChatKit/UIColor+NECommon.h>
#import <NEBaseUIKitOC/NECommonUIConstant.h>

@implementation TeamIntroduceViewController

- (void)setupUI {
  [super setupUI];
  self.view.backgroundColor = UIColor.ne_lightBackgroundColor;
  self.navigationView.backgroundColor = UIColor.ne_lightBackgroundColor;
  self.navigationController.navigationBar.backgroundColor = UIColor.ne_lightBackgroundColor;
  [self addRightActionWithTitle:NETeamUIKitLocalizable(@"save") action:@selector(saveIntr) target:self];
  if (![self getPermission]) {
    self.rightNavButton.hidden = YES;
    self.navigationView.moreButton.hidden = YES;
    self.navigationItem.rightBarButtonItem = nil;
  }
  [self.navigationView setBackButtonTitle:commonLocalizable(@"cancel")];
  [self.navigationView.backButton setTitleColor:UIColor.ne_greyText forState:UIControlStateNormal];

  self.backView.layer.cornerRadius = 8.0;
  [NSLayoutConstraint activateConstraints:@[
    [self.backView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:20.0],
    [self.backView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:12.0 + NEUIKitAdaptiveNavigationAndStatusHeight()],
    [self.backView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant:-20.0],
    [self.backView.heightAnchor constraintEqualToConstant:170.0],
  ]];

  [NSLayoutConstraint activateConstraints:@[
    [self.textView.leftAnchor constraintEqualToAnchor:self.backView.leftAnchor constant:16.0],
    [self.textView.rightAnchor constraintEqualToAnchor:self.backView.rightAnchor constant:-32.0],
    [self.textView.topAnchor constraintEqualToAnchor:self.backView.topAnchor constant:16.0],
    [self.textView.heightAnchor constraintEqualToConstant:120.0],
  ]];

  [NSLayoutConstraint activateConstraints:@[
    [self.clearButton.rightAnchor constraintEqualToAnchor:self.backView.rightAnchor constant:-16.0],
    [self.clearButton.centerYAnchor constraintEqualToAnchor:self.backView.centerYAnchor],
    [self.clearButton.widthAnchor constraintEqualToConstant:16.0],
    [self.clearButton.heightAnchor constraintEqualToConstant:16.0],
  ]];
}

@end
