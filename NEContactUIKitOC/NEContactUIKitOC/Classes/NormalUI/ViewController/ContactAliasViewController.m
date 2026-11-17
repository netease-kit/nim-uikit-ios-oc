// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "ContactAliasViewController.h"
#import <NEChatKit/UIColor+NECommon.h>
#import "ContactConst.h"
#import <NEBaseUIKitOC/NEBaseUIKitOC.h>

@implementation ContactAliasViewController

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  NSNumber *useSystemNavValue = [[NEConfigManager instance] getParameterForKey:useSystemNav];
  if (useSystemNavValue != nil && [useSystemNavValue boolValue]) {
    self.topConstant = 10;
    self.aliasInputTopAnchor.constant = self.topConstant;
  }
}

- (void)setupUI {
  [super setupUI];
  self.aliasInput.layer.cornerRadius = 8;

  UIBarButtonItem *clearItem = [[UIBarButtonItem alloc] initWithTitle:contactLocalizable(@"save")
                                                               style:UIBarButtonItemStyleDone
                                                              target:self
                                                              action:@selector(saveAlias)];
  clearItem.tintColor = [UIColor ne_colorWithHexString:@"337EFF"];
  self.navigationItem.rightBarButtonItem = clearItem;

  self.aliasInputTopAnchor = [self.aliasInput.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:self.topConstant + 10];
  self.aliasInputTopAnchor.active = YES;
  [NSLayoutConstraint activateConstraints:@[
    [self.aliasInput.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:20],
    [self.aliasInput.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant:-20],
    [self.aliasInput.heightAnchor constraintEqualToConstant:50],
  ]];
}

@end
