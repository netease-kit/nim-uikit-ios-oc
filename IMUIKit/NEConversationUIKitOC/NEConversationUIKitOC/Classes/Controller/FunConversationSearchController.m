// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunConversationSearchController.h"
#import <NEChatKit/NEChatKitOC.h>
#import "FunConversationSearchCell.h"
#import "NEBaseConversationSearchCell.h"
#import <NEChatKit/NEConstant.h>
#import <NEChatKit/UIColor+NECommon.h>
#import <NECommonUIKitOC/NEEmptyDataView.h>
#import <NECommonUIKitOC/FunSearchView.h>
#import <NECommonUIKitOC/NECommonUIConstant.h>
#import <NECommonUIKitOC/NENavigationView.h>
#import <NECommonUIKitOC/SearchTextField.h>

static UIColor *NEFunConversationBackgroundColor(void) {
  return [UIColor ne_colorWithHexString:@"#EDEDED"];
}

static UIColor *NEFunConversationSearchHeaderTitleColor(void) {
  return [UIColor ne_colorWithHexString:@"#737373"];
}

static UIColor *NEFunConversationLineBorderColor(void) {
  return [UIColor ne_colorWithHexString:@"#E5E5E5"];
}

@interface FunConversationSearchController ()
@property (nonatomic, strong) UIButton *cancelButton;
@end

@implementation FunConversationSearchController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = NEFunConversationBackgroundColor();
  [self.emptyView setEmptyImageWithName:@"fun_user_empty"];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  self.navigationController.navigationBarHidden = YES;
  self.navigationView.hidden = YES;
}

- (void)setupSubviews {
  [super setupSubviews];
  UIImageView *leftImageView = [[UIImageView alloc] initWithImage:[coreLoader() loadImage:@"fun_search"]];
  self.searchTextField.leftView = leftImageView;
  self.searchTextField.font = [UIFont systemFontOfSize:16.0];
  self.searchTextField.textColor = UIColor.blackColor;
  self.searchTextField.layer.cornerRadius = 4.0;
  self.searchTextField.backgroundColor = UIColor.whiteColor;
  self.searchTextFieldTopAnchor = [self.searchTextField.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:NEConstant.statusBarHeight + 12.0];
  self.searchTextFieldTopAnchor.active = YES;
  [NSLayoutConstraint activateConstraints:@[
    [self.searchTextField.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:8.0],
    [self.searchTextField.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant:-72.0],
    [self.searchTextField.heightAnchor constraintEqualToConstant:36.0],
  ]];

  [self.view addSubview:self.cancelButton];
  [NSLayoutConstraint activateConstraints:@[
    [self.cancelButton.centerYAnchor constraintEqualToAnchor:self.searchTextField.centerYAnchor],
    [self.cancelButton.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant:-5.0],
    [self.cancelButton.widthAnchor constraintEqualToConstant:55.0],
  ]];

  self.tableView.sectionHeaderHeight = 38.0;
  [NSLayoutConstraint activateConstraints:@[
    [self.tableView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.tableView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    [self.tableView.topAnchor constraintEqualToAnchor:self.searchTextField.bottomAnchor constant:12.0],
  ]];

  [self.tableView registerClass:[FunConversationSearchCell class]
         forCellReuseIdentifier:NSStringFromClass([NEBaseConversationSearchCell class])];
  [self.tableView registerClass:[FunSearchSessionHeaderView class]
forHeaderFooterViewReuseIdentifier:NSStringFromClass([SearchSessionBaseView class])];
  if (@available(iOS 15.0, *)) {
    self.tableView.sectionHeaderTopPadding = 0.0;
  }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  FunSearchSessionHeaderView *sectionView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:NSStringFromClass([SearchSessionBaseView class])];
  sectionView.titleLabel.textColor = NEFunConversationSearchHeaderTitleColor();
  sectionView.bottomLine.backgroundColor = NEFunConversationLineBorderColor();
  [sectionView setUpTitle:self.headTitleArr[section]];
  return sectionView;
}

- (UIButton *)cancelButton {
  if (_cancelButton == nil) {
    _cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_cancelButton setTitle:commonLocalizable(@"cancel") forState:UIControlStateNormal];
    [_cancelButton setTitleColor:UIColor.ne_greyText forState:UIControlStateNormal];
    [_cancelButton addTarget:self action:@selector(backEvent) forControlEvents:UIControlEventTouchUpInside];
    _cancelButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    _cancelButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    _cancelButton.accessibilityIdentifier = @"id.backArrow";
  }
  return _cancelButton;
}

@end
