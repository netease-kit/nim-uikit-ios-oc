// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "TeamNameViewController.h"
#import <NEBaseUIKitOC/NEAdaptiveDeviceGate.h>
#import "TeamConstant.h"
#import <NEChatKit/NEConstant.h>
#import <NEChatKit/UIColor+NECommon.h>
#import <NEBaseUIKitOC/NECommonUIConstant.h>
#import <NEBaseUIKitOC/NENavigationView.h>

@implementation TeamNameViewController

- (void)setupUI {
  [super setupUI];
  self.view.backgroundColor = UIColor.ne_lightBackgroundColor;
  self.navigationView.backgroundColor = UIColor.ne_lightBackgroundColor;
  self.navigationController.navigationBar.backgroundColor = UIColor.ne_lightBackgroundColor;
  [self addRightActionWithTitle:NETeamUIKitLocalizable(@"save") action:@selector(saveName) target:self];
  [self.navigationView setBackButtonTitle:commonLocalizable(@"cancel")];
  [self.navigationView.backButton setTitleColor:UIColor.ne_greyText forState:UIControlStateNormal];

  self.backView.layer.cornerRadius = 8.0;
  [NSLayoutConstraint activateConstraints:@[
    [self.backView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:20.0],
    [self.backView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant:-20.0],
    [self.backView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:12.0 + NEUIKitAdaptiveNavigationAndStatusHeight()],
    [self.backView.heightAnchor constraintEqualToConstant:60.0],
  ]];

  [NSLayoutConstraint activateConstraints:@[
    [self.textInputView.leftAnchor constraintEqualToAnchor:self.backView.leftAnchor constant:16.0],
    [self.textInputView.rightAnchor constraintEqualToAnchor:self.backView.rightAnchor constant:-40.0],
    [self.textInputView.topAnchor constraintEqualToAnchor:self.backView.topAnchor],
    [self.textInputView.heightAnchor constraintEqualToConstant:44.0],
  ]];

  [NSLayoutConstraint activateConstraints:@[
    [self.clearButton.rightAnchor constraintEqualToAnchor:self.backView.rightAnchor constant:-32.0],
    [self.clearButton.topAnchor constraintEqualToAnchor:self.backView.topAnchor constant:16.0],
    [self.clearButton.widthAnchor constraintEqualToConstant:16.0],
    [self.clearButton.heightAnchor constraintEqualToConstant:16.0],
  ]];
}

@end
