// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseFindFriendViewController.h"
#import "ContactConst.h"
#import <NEChatKit/NECommonLoader.h>
#import <NEChatKit/NEChatDetectNetworkTool.h>
#import <NEChatKit/UIColor+NECommon.h>

#import <NEChatKit/ContactRepo.h>
#import <NEChatKit/NEFriendUserCache.h>
#import <NEChatKit/IMKitConfigCenter.h>
#import <NECommonUIKitOC/NECommonUIKitOC.h>
#import <NECommonUIKitOC/NENavigationView.h>
#import <NECommonUIKitOC/NECommonUIConstant.h>
#import <NECommonUIKitOC/UIView+YXToast.h>
#import "ContactConst.h"
#import <NEChatKit/NEChatKitOC.h>

static NSString * const NEFindFriendMeSettingRouterCompat = @"imkit://mine/userInfo.page";
static NSString * const NEFindFriendContactUserInfoPageRouterCompat = @"imkit://contact/userInfo.page";

@implementation NEBaseFindFriendViewController

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    _viewModel = [[FindFriendViewModel alloc] init];
    _hasRequest = NO;
    _isRequesting = NO;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  return [super initWithCoder:coder];
}

#pragma mark - Life Cycle

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  self.searchBackViewTopAnchor.constant = 20 + self.topConstant;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [self changeLanguage];
  [self setupUI];

  __weak typeof(self) weakSelf = self;
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    [weakSelf.searchInput becomeFirstResponder];
  });
}

#pragma mark - setupUI

- (void)setupUI {
  [self.view addSubview:self.searchBackView];
  self.searchBackViewTopAnchor = [self.searchBackView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:20 + self.topConstant];
  self.searchBackViewTopAnchor.active = YES;
  [NSLayoutConstraint activateConstraints:@[
    [self.searchBackView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:20],
    [self.searchBackView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant:-20],
    [self.searchBackView.heightAnchor constraintEqualToConstant:32],
  ]];

  [self.searchBackView addSubview:self.searchImageView];
  [NSLayoutConstraint activateConstraints:@[
    [self.searchImageView.centerYAnchor constraintEqualToAnchor:self.searchBackView.centerYAnchor],
    [self.searchImageView.leftAnchor constraintEqualToAnchor:self.searchBackView.leftAnchor constant:18],
    [self.searchImageView.widthAnchor constraintEqualToConstant:13],
    [self.searchImageView.heightAnchor constraintEqualToConstant:13],
  ]];

  [self.searchBackView addSubview:self.searchInput];
  self.searchInput.delegate = self;

  [NSLayoutConstraint activateConstraints:@[
    [self.searchInput.leftAnchor constraintEqualToAnchor:self.searchImageView.rightAnchor constant:5],
    [self.searchInput.rightAnchor constraintEqualToAnchor:self.searchBackView.rightAnchor constant:-18],
    [self.searchInput.topAnchor constraintEqualToAnchor:self.searchBackView.topAnchor],
    [self.searchInput.bottomAnchor constraintEqualToAnchor:self.searchBackView.bottomAnchor],
  ]];

  UIButton *clearButton = [self.searchInput valueForKey:@"_clearButton"];
  if (clearButton) {
    clearButton.accessibilityIdentifier = @"id.clear";
  }

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(textFieldChange)
                                               name:UITextFieldTextDidChangeNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(changeLanguage)
                                               name:NENotificationNameChangeLanguage
                                             object:nil];

  [self.view addSubview:self.emptyView];
  [NSLayoutConstraint activateConstraints:@[
    [self.emptyView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
    [self.emptyView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:0],
    [self.emptyView.widthAnchor constraintEqualToConstant:200],
    [self.emptyView.heightAnchor constraintEqualToConstant:200],
  ]];
}

- (void)changeLanguage {
  self.title = contactLocalizable(@"add_friend");
  self.navigationView.moreButton.hidden = YES;
  self.emptyView.message = contactLocalizable(@"user_not_exist");
  self.searchInput.placeholder = contactLocalizable(@"input_userId");
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  NSString *text = textField.text;
  if (!text) return NO;
  if (text.length <= 0) return NO;
  if (self.hasRequest == NO) {
    [self startSearch:text];
  }
  return YES;
}

- (void)textFieldChange {
  NSString *text = self.searchInput.text;
  if (text && text.length <= 0) {
    self.emptyView.hidden = YES;
  }
}

- (void)startSearch:(NSString *)text {
  if (![[NEChatDetectNetworkTool shareInstance] isNetworkReachability]) {
    [self showToast:commonLocalizable(@"network_error")];
    return;
  }

  if ([[IMKitClient instance] isMe:text]) {
    [[Router shared] use:NEFindFriendMeSettingRouterCompat
              parameters:@{@"nav": self.navigationController ?: [NSNull null]}
                 closure:nil];
    return;
  }

  if (self.isRequesting == YES) return;
  self.isRequesting = YES;
  __weak typeof(self) weakSelf = self;
  [self.viewModel searchFriend:text completion:^(NEUserWithFriend * _Nullable user, NSError * _Nullable error) {
    weakSelf.isRequesting = NO;
    if (error == nil) {
      if (user && (user.user != nil || user.friend != nil)) {
        // go to detail
        [[Router shared] use:NEFindFriendContactUserInfoPageRouterCompat
                  parameters:@{@"nav": weakSelf.navigationController ?: [NSNull null], @"user": user}
                     closure:nil];
        weakSelf.emptyView.hidden = YES;
      } else {
        weakSelf.emptyView.hidden = NO;
      }
    } else {
      [weakSelf showToast:error.localizedDescription ?: @""];
    }
  }];
}

#pragma mark - Lazy Init

- (UITextField *)searchInput {
  if (!_searchInput) {
    _searchInput = [[UITextField alloc] init];
    _searchInput.translatesAutoresizingMaskIntoConstraints = NO;
    _searchInput.textColor = [UIColor ne_darkText];
    _searchInput.placeholder = contactLocalizable(@"input_userId");
    _searchInput.font = [UIFont systemFontOfSize:14.0];
    _searchInput.returnKeyType = UIReturnKeySearch;
    _searchInput.clearButtonMode = UITextFieldViewModeAlways;
    _searchInput.accessibilityIdentifier = @"id.addFriendAccount";
  }
  return _searchInput;
}

- (UIView *)searchBackView {
  if (!_searchBackView) {
    _searchBackView = [[UIView alloc] init];
    _searchBackView.backgroundColor = [UIColor ne_colorWithHexString:@"F2F4F5"];
    _searchBackView.translatesAutoresizingMaskIntoConstraints = NO;
    _searchBackView.clipsToBounds = YES;
    _searchBackView.layer.cornerRadius = 4.0;
  }
  return _searchBackView;
}

- (UIImageView *)searchImageView {
  if (!_searchImageView) {
    _searchImageView = [[UIImageView alloc] init];
    _searchImageView.image = [coreLoader() loadImage:@"textField_search_icon"];
    _searchImageView.translatesAutoresizingMaskIntoConstraints = NO;
  }
  return _searchImageView;
}

@end
