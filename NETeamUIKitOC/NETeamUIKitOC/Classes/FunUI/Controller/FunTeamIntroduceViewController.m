// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunTeamIntroduceViewController.h"
#import <NEBaseUIKitOC/NEAdaptiveDeviceGate.h>
#import "FunTeamUIColor.h"
#import "TeamConstant.h"
#import <NEChatKit/NEConstant.h>

@implementation FunTeamIntroduceViewController

- (void)setupUI {
  [super setupUI];
  self.view.backgroundColor = UIColor.funTeamBackgroundColor;
  [self addRightActionWithTitle:NETeamUIKitLocalizable(@"save")
                         action:@selector(saveIntr)
                         target:self
                          color:UIColor.funTeamThemeColor];
  if (![self getPermission]) {
    self.rightNavButton.hidden = YES;
    self.navigationView.moreButton.hidden = YES;
    self.navigationItem.rightBarButtonItem = nil;
  }
  self.navigationController.navigationBar.backgroundColor = UIColor.funTeamBackgroundColor;
  self.navigationView.backgroundColor = UIColor.funTeamBackgroundColor;
  [self.navigationView.moreButton setTitleColor:UIColor.funTeamThemeColor forState:UIControlStateNormal];

  [NSLayoutConstraint activateConstraints:@[
    [self.backView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.backView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:NEUIKitAdaptiveNavigationAndStatusHeight()],
    [self.backView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [self.backView.heightAnchor constraintEqualToConstant:142.0],
  ]];

  [NSLayoutConstraint activateConstraints:@[
    [self.textView.leftAnchor constraintEqualToAnchor:self.backView.leftAnchor constant:16.0],
    [self.textView.rightAnchor constraintEqualToAnchor:self.backView.rightAnchor constant:-32.0],
    [self.textView.topAnchor constraintEqualToAnchor:self.backView.topAnchor constant:16.0],
    [self.textView.heightAnchor constraintEqualToConstant:110.0],
  ]];

  [NSLayoutConstraint activateConstraints:@[
    [self.clearButton.rightAnchor constraintEqualToAnchor:self.backView.rightAnchor constant:-16.0],
    [self.clearButton.centerYAnchor constraintEqualToAnchor:self.backView.centerYAnchor],
    [self.clearButton.widthAnchor constraintEqualToConstant:16.0],
    [self.clearButton.heightAnchor constraintEqualToConstant:16.0],
  ]];
}

@end
