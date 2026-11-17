// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "ConversationSearchController.h"
#import "ConversationSearchCell.h"
#import "NEBaseConversationSearchCell.h"
#import <NEBaseUIKitOC/FunSearchView.h>
#import <NEBaseUIKitOC/NECommonUIConstant.h>
#import <NEBaseUIKitOC/NENavigationView.h>
#import <NEBaseUIKitOC/SearchTextField.h>

FOUNDATION_EXTERN NSString *NEConversationSearchLocalizedString(NSString *key);

@implementation SearchSessionHeaderView

- (void)setupUI {
  [super setupUI];
  [NSLayoutConstraint activateConstraints:@[
    [self.titleLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
    [self.titleLabel.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:20.0],
    [self.bottomLine.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-20.0],
    [self.bottomLine.leftAnchor constraintEqualToAnchor:self.titleLabel.leftAnchor],
    [self.bottomLine.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
    [self.bottomLine.heightAnchor constraintEqualToConstant:1.0],
  ]];
}

@end

@implementation ConversationSearchController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    self.tag = @"ConversationSearchController";
  }
  return self;
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  self.searchTextFieldTopAnchor.constant = self.topConstant + 20.0;
}

- (void)setupSubviews {
  [super setupSubviews];
  self.title = commonLocalizable(@"search");
  self.navigationController.navigationBar.backgroundColor = UIColor.whiteColor;
  self.navigationView.backgroundColor = UIColor.whiteColor;
  self.navigationView.moreButton.hidden = YES;

  self.searchTextField.placeholder = NEConversationSearchLocalizedString(@"search_keyword");
  self.searchTextFieldTopAnchor = [self.searchTextField.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:self.topConstant + 20.0];
  self.searchTextFieldTopAnchor.active = YES;
  [NSLayoutConstraint activateConstraints:@[
    [self.searchTextField.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:20.0],
    [self.searchTextField.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant:-20.0],
    [self.searchTextField.heightAnchor constraintEqualToConstant:32.0],
    [self.tableView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.tableView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    [self.tableView.topAnchor constraintEqualToAnchor:self.searchTextField.bottomAnchor constant:20.0],
  ]];

  [self.tableView registerClass:[ConversationSearchCell class]
         forCellReuseIdentifier:NSStringFromClass([NEBaseConversationSearchCell class])];
  [self.tableView registerClass:[SearchSessionHeaderView class]
forHeaderFooterViewReuseIdentifier:NSStringFromClass([SearchSessionBaseView class])];
}

@end
