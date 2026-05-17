// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunContactAliasViewController.h"
#import "FunContactUIColor.h"
#import "ContactConst.h"

@implementation FunContactAliasViewController

- (void)setupUI {
  [super setupUI];
  UIBarButtonItem *clearItem = [[UIBarButtonItem alloc] initWithTitle:contactLocalizable(@"save")
                                                               style:UIBarButtonItemStyleDone
                                                              target:self
                                                              action:@selector(saveAlias)];
  clearItem.tintColor = [UIColor funContactThemeColor];
  self.navigationItem.rightBarButtonItem = clearItem;

  [self.navigationView.moreButton setTitleColor:[UIColor funContactThemeColor] forState:UIControlStateNormal];

  self.aliasInputTopAnchor = [self.aliasInput.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:self.topConstant];
  self.aliasInputTopAnchor.active = YES;
  [NSLayoutConstraint activateConstraints:@[
    [self.aliasInput.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:0],
    [self.aliasInput.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant:0],
    [self.aliasInput.heightAnchor constraintEqualToConstant:60],
  ]];
}

@end
