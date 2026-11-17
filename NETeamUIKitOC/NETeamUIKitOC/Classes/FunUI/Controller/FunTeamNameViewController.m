// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunTeamNameViewController.h"
#import <NEBaseUIKitOC/NEAdaptiveDeviceGate.h>
#import "TeamConstant.h"
#import "FunTeamUIColor.h"
#import <NEChatKit/NEConstant.h>
#import <NEBaseUIKitOC/NENavigationView.h>

@implementation FunTeamNameViewController

- (void)setupUI {
  [super setupUI];
  self.view.backgroundColor = UIColor.funTeamBackgroundColor;
  self.navigationController.navigationBar.backgroundColor = UIColor.funTeamBackgroundColor;
  [self addRightActionWithTitle:NETeamUIKitLocalizable(@"save")
                         action:@selector(saveName)
                         target:self
                          color:UIColor.funTeamThemeColor];
  self.navigationView.backgroundColor = UIColor.funTeamBackgroundColor;
  [self.navigationView.moreButton setTitleColor:UIColor.funTeamThemeColor forState:UIControlStateNormal];

  [NSLayoutConstraint activateConstraints:@[
    [self.backView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.backView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [self.backView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:NEUIKitAdaptiveNavigationAndStatusHeight()],
    [self.backView.heightAnchor constraintEqualToConstant:60.0],
  ]];

  [NSLayoutConstraint activateConstraints:@[
    [self.textInputView.leftAnchor constraintEqualToAnchor:self.backView.leftAnchor constant:16.0],
    [self.textInputView.rightAnchor constraintEqualToAnchor:self.backView.rightAnchor constant:-32.0],
    [self.textInputView.centerYAnchor constraintEqualToAnchor:self.backView.centerYAnchor],
    [self.textInputView.heightAnchor constraintEqualToConstant:60.0],
  ]];

  [NSLayoutConstraint activateConstraints:@[
    [self.clearButton.rightAnchor constraintEqualToAnchor:self.backView.rightAnchor constant:-16.0],
    [self.clearButton.topAnchor constraintEqualToAnchor:self.backView.topAnchor constant:16.0],
    [self.clearButton.widthAnchor constraintEqualToConstant:16.0],
    [self.clearButton.heightAnchor constraintEqualToConstant:16.0],
  ]];
}

- (void)disableSubmit {
  [self.rightNavButton setTitleColor:UIColor.funTeamThemeDisableColor forState:UIControlStateNormal];
  self.rightNavButton.enabled = NO;
  [self.navigationView.moreButton setTitleColor:UIColor.funTeamThemeDisableColor forState:UIControlStateNormal];
  self.navigationView.moreButton.enabled = NO;
}

- (void)enableSubmit {
  [self.rightNavButton setTitleColor:UIColor.funTeamThemeColor forState:UIControlStateNormal];
  self.rightNavButton.enabled = YES;
  [self.navigationView.moreButton setTitleColor:UIColor.funTeamThemeColor forState:UIControlStateNormal];
  self.navigationView.moreButton.enabled = YES;
}

@end
