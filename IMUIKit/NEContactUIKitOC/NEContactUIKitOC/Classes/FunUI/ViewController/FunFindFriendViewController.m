// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunFindFriendViewController.h"
#import <NEChatKit/NECommonLoader.h>
#import <NEChatKit/UIColor+NECommon.h>
#import "ContactConst.h"
#import <NECommonUIKitOC/NECommonUIKitOC.h>

@implementation FunFindFriendViewController

- (void)setupUI {
  self.view.backgroundColor = [UIColor ne_colorWithHexString:@"0xEDEDED"];

  UIView *searchBackView = [[UIView alloc] init];
  [self.view addSubview:searchBackView];
  searchBackView.backgroundColor = [UIColor whiteColor];
  searchBackView.translatesAutoresizingMaskIntoConstraints = NO;
  searchBackView.clipsToBounds = YES;
  searchBackView.layer.cornerRadius = 4.0;
  self.searchBackViewTopAnchor = [searchBackView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:10 + self.topConstant];
  self.searchBackViewTopAnchor.active = YES;
  [NSLayoutConstraint activateConstraints:@[
    [searchBackView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:20],
    [searchBackView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant:-20],
    [searchBackView.heightAnchor constraintEqualToConstant:36],
  ]];

  UIImageView *searchImageView = [[UIImageView alloc] init];
  [searchBackView addSubview:searchImageView];
  searchImageView.image = [coreLoader() loadImage:@"textField_search_icon"];
  searchImageView.translatesAutoresizingMaskIntoConstraints = NO;
  [NSLayoutConstraint activateConstraints:@[
    [searchImageView.centerYAnchor constraintEqualToAnchor:searchBackView.centerYAnchor],
    [searchImageView.leftAnchor constraintEqualToAnchor:searchBackView.leftAnchor constant:18],
    [searchImageView.widthAnchor constraintEqualToConstant:13],
    [searchImageView.heightAnchor constraintEqualToConstant:13],
  ]];

  [searchBackView addSubview:self.searchInput];
  self.searchInput.delegate = self;
  [NSLayoutConstraint activateConstraints:@[
    [self.searchInput.leftAnchor constraintEqualToAnchor:searchImageView.rightAnchor constant:5],
    [self.searchInput.rightAnchor constraintEqualToAnchor:searchBackView.rightAnchor constant:-18],
    [self.searchInput.topAnchor constraintEqualToAnchor:searchBackView.topAnchor],
    [self.searchInput.bottomAnchor constraintEqualToAnchor:searchBackView.bottomAnchor],
  ]];
  UIButton *clearButton = [self.searchInput valueForKey:@"_clearButton"];
  if (clearButton) {
    clearButton.accessibilityIdentifier = @"id.clear";
  }

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(textFieldChange)
                                               name:UITextFieldTextDidChangeNotification
                                             object:nil];

  [self.view addSubview:self.emptyView];
  [NSLayoutConstraint activateConstraints:@[
    [self.emptyView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
    [self.emptyView.topAnchor constraintEqualToAnchor:self.searchInput.bottomAnchor constant:74],
    [self.emptyView.widthAnchor constraintEqualToConstant:200],
    [self.emptyView.heightAnchor constraintEqualToConstant:200],
  ]];
  [self.emptyView setEmptyImageName:@"fun_user_empty"];
}

@end
