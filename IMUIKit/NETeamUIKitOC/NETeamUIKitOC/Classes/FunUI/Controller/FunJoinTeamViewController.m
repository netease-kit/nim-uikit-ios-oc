// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunJoinTeamViewController.h"
#import "FunTeamUIColor.h"

@implementation FunJoinTeamViewController

- (void)setupUI {
  self.view.backgroundColor = UIColor.funTeamBackgroundColor;

  self.searchBackView.backgroundColor = UIColor.whiteColor;
  self.searchBackView.translatesAutoresizingMaskIntoConstraints = NO;
  self.searchBackView.clipsToBounds = YES;
  self.searchBackView.layer.cornerRadius = 4.0;
  [self.view addSubview:self.searchBackView];
  self.searchBackViewTopAnchor = [self.searchBackView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:10.0 + self.topConstant];
  self.searchBackViewTopAnchor.active = YES;
  [NSLayoutConstraint activateConstraints:@[
    [self.searchBackView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:20.0],
    [self.searchBackView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant:-20.0],
    [self.searchBackView.heightAnchor constraintEqualToConstant:36.0],
  ]];

  [self.searchBackView addSubview:self.searchImageView];
  [NSLayoutConstraint activateConstraints:@[
    [self.searchImageView.centerYAnchor constraintEqualToAnchor:self.searchBackView.centerYAnchor],
    [self.searchImageView.leftAnchor constraintEqualToAnchor:self.searchBackView.leftAnchor constant:18.0],
    [self.searchImageView.widthAnchor constraintEqualToConstant:13.0],
    [self.searchImageView.heightAnchor constraintEqualToConstant:13.0],
  ]];

  [self.searchBackView addSubview:self.searchInput];
  self.searchInput.delegate = self;
  [NSLayoutConstraint activateConstraints:@[
    [self.searchInput.leftAnchor constraintEqualToAnchor:self.searchImageView.rightAnchor constant:5.0],
    [self.searchInput.rightAnchor constraintEqualToAnchor:self.searchBackView.rightAnchor constant:-18.0],
    [self.searchInput.topAnchor constraintEqualToAnchor:self.searchBackView.topAnchor],
    [self.searchInput.bottomAnchor constraintEqualToAnchor:self.searchBackView.bottomAnchor],
  ]];

  UIButton *clearButton = [self.searchInput valueForKey:@"_clearButton"];
  if ([clearButton isKindOfClass:[UIButton class]]) {
    clearButton.accessibilityIdentifier = @"id.clear";
  }

  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldChange) name:UITextFieldTextDidChangeNotification object:nil];

  [self.view addSubview:self.emptyView];
  [NSLayoutConstraint activateConstraints:@[
    [self.emptyView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
    [self.emptyView.topAnchor constraintEqualToAnchor:self.searchInput.bottomAnchor],
    [self.emptyView.widthAnchor constraintEqualToConstant:200.0],
    [self.emptyView.heightAnchor constraintEqualToConstant:200.0],
  ]];
  [self.emptyView setEmptyImageName:@"fun_user_empty"];
}

@end
