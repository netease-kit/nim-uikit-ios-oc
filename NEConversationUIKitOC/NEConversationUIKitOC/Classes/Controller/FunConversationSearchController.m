// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunConversationSearchController.h"
#import <NEBaseUIKitOC/NEAdaptiveDeviceGate.h>
#import "FunConversationSearchCell.h"
#import "NEBaseConversationSearchCell.h"
#import <NEChatKit/NEConstant.h>
#import <NEChatKit/UIColor+NECommon.h>

#import <NEBaseUIKitOC/NEEmptyDataView.h>
#import <NEBaseUIKitOC/FunSearchView.h>
#import <NEBaseUIKitOC/NECommonUIConstant.h>
#import <NEBaseUIKitOC/NENavigationView.h>
#import <NEBaseUIKitOC/NEUnifiedBackButton.h>
#import <NEBaseUIKitOC/SearchTextField.h>
#import <NEChatKit/NEChatKit.h>

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
@property (nonatomic, strong) NEUnifiedBackButton *cancelButton;
@property (nonatomic, strong, nullable) NSLayoutConstraint *searchTextFieldLeftAnchor;
@end

@implementation FunConversationSearchController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    self.tag = @"FunConversationSearchController";
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = NEFunConversationBackgroundColor();
  [self.emptyView setEmptyImageWithName:@"fun_user_empty"];
}

- (void)viewSafeAreaInsetsDidChange {
  [super viewSafeAreaInsetsDidChange];
  if (!self.searchTextFieldTopAnchor) return;
  CGFloat top = NEUIKitStatusBarHeightForView(self.view) + 12.0;
  if (fabs(self.searchTextFieldTopAnchor.constant - top) < 0.5) return;
  self.searchTextFieldTopAnchor.constant = top;
  [self.view setNeedsLayout];
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
  self.searchTextFieldTopAnchor = [self.searchTextField.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:NEUIKitStatusBarHeightForView(self.view) + 12.0];
  self.searchTextFieldTopAnchor.active = YES;
  self.searchTextFieldLeftAnchor =
      [self.searchTextField.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:58.0];
  [NSLayoutConstraint activateConstraints:@[
    self.searchTextFieldLeftAnchor,
    [self.searchTextField.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant:-12.0],
    [self.searchTextField.heightAnchor constraintEqualToConstant:36.0],
  ]];

  [self.view addSubview:self.cancelButton];
  [NSLayoutConstraint activateConstraints:@[
    [self.cancelButton.centerYAnchor constraintEqualToAnchor:self.searchTextField.centerYAnchor],
    [self.cancelButton.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:16.0],
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

- (NEUnifiedBackButton *)cancelButton {
  if (_cancelButton == nil) {
    _cancelButton = [[NEUnifiedBackButton alloc] initWithAccessibilityLabel:commonLocalizable(@"cancel")];
    _cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    _cancelButton.accessibilityIdentifier = @"id.backArrow";
    [_cancelButton addTarget:self action:@selector(backEvent) forControlEvents:UIControlEventTouchUpInside];
  }
  return _cancelButton;
}

- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  BOOL hasPageBackEntry = !self.cancelButton.hidden && self.cancelButton.alpha > 0.01;
  CGFloat inset = hasPageBackEntry ? 58.0 : 12.0;
  if (fabs(self.searchTextFieldLeftAnchor.constant - inset) > 0.5) {
    self.searchTextFieldLeftAnchor.constant = inset;
  }
}

@end
