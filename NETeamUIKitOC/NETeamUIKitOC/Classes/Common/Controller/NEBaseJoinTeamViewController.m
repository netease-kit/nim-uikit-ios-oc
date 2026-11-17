// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseJoinTeamViewController.h"
#import <NEBaseUIKitOC/SearchTextField.h>
#import "TeamConstant.h"
#import "JoinTeamViewModel.h"
#import <NEChatKit/NECommonLoader.h>
#import <NEChatKit/UIColor+NECommon.h>
#import <NEChatKit/NEChatDetectNetworkTool.h>
#import <NEBaseUIKitOC/NECommonUIConstant.h>
#import <NEBaseUIKitOC/UIView+YXToast.h>
#import <NEChatKit/NERouterUrl.h>
#import <NEChatKit/Router.h>
#import <NEChatKit/NEALog.h>

static NSString * const NETeamDetailInfoPageRouterCompat = @"imkit://team/teamDetailInfo.page";

@interface NEBaseJoinTeamViewController ()
@property (nonatomic, strong, readwrite) JoinTeamViewModel *viewModel;
@property (nonatomic, strong, readwrite) UITextField *searchInput;
@end

@implementation NEBaseJoinTeamViewController

- (BOOL)hasRequest {
  return NO;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  self.searchBackViewTopAnchor.constant = 20.0 + self.topConstant;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.title = commonLocalizable(@"join_team");
  self.navigationView.moreButton.hidden = YES;
  [self.emptyView setText:NETeamUIKitLocalizable(@"no_team_find")];
  [self setupUI];

  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    [self.searchInput becomeFirstResponder];
  });
}

- (void)setupUI {
  [self.view addSubview:self.searchBackView];
  self.searchBackViewTopAnchor = [self.searchBackView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:20.0 + self.topConstant];
  self.searchBackViewTopAnchor.active = YES;
  [NSLayoutConstraint activateConstraints:@[
    [self.searchBackView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:20.0],
    [self.searchBackView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant:-20.0],
    [self.searchBackView.heightAnchor constraintEqualToConstant:32.0],
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
    [self.emptyView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
    [self.emptyView.widthAnchor constraintEqualToConstant:200.0],
    [self.emptyView.heightAnchor constraintEqualToConstant:200.0],
  ]];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  NSString *text = textField.text ?: @"";
  if (text.length == 0) {
    return NO;
  }
  if (!self.hasRequest) {
    [self startSearch:text];
  }
  return YES;
}

- (void)textFieldChange {
  if (self.searchInput.text.length == 0) {
    self.emptyView.hidden = YES;
  }
}

- (void)startSearch:(NSString *)text {
  if ([[NEChatDetectNetworkTool shareInstance] isNetworkExplicitlyUnreachable]) {
    [self showToast:commonLocalizable(@"network_error")];
    return;
  }

  if (self.isRequesting) {
    return;
  }
  self.isRequesting = YES;

  __weak typeof(self) weakSelf = self;
  [self.viewModel getTeamInfo:text completion:^(V2NIMTeam * _Nullable team, NSError * _Nullable error) {
    __strong typeof(weakSelf) strongSelf = weakSelf;
    strongSelf.isRequesting = NO;
    [NEALog infoLog:@"NEBaseJoinTeamViewController"
               desc:[NSString stringWithFormat:@"CALLBACK getTeamInfo %@", error.localizedDescription ?: @"no error"]];
    if (error) {
      strongSelf.emptyView.hidden = NO;
      return;
    }

    if (team) {
      [[Router shared] use:NETeamDetailInfoPageRouterCompat
                parameters:@{
                  @"nav" : strongSelf.navigationController ?: [NSNull null],
                  @"team" : team
                }
                   closure:nil];
      strongSelf.emptyView.hidden = YES;
    } else {
      strongSelf.emptyView.hidden = NO;
    }
  }];
}

- (JoinTeamViewModel *)viewModel {
  if (!_viewModel) {
    _viewModel = [[JoinTeamViewModel alloc] init];
  }
  return _viewModel;
}

- (UITextField *)searchInput {
  if (!_searchInput) {
    _searchInput = [[NESingleLineTextField alloc] init];
    _searchInput.translatesAutoresizingMaskIntoConstraints = NO;
    _searchInput.textColor = UIColor.ne_darkText;
    _searchInput.placeholder = NETeamUIKitLocalizable(@"input_team_id");
    _searchInput.font = [UIFont systemFontOfSize:14.0];
    _searchInput.returnKeyType = UIReturnKeySearch;
    _searchInput.clearButtonMode = UITextFieldViewModeAlways;
    _searchInput.accessibilityIdentifier = @"id.joinTeamAccount";
  }
  return _searchInput;
}

- (UIView *)searchBackView {
  if (!_searchBackView) {
    _searchBackView = [[UIView alloc] init];
    _searchBackView.translatesAutoresizingMaskIntoConstraints = NO;
    _searchBackView.backgroundColor = [UIColor ne_colorWithHexString:@"F2F4F5"];
    _searchBackView.clipsToBounds = YES;
    _searchBackView.layer.cornerRadius = 4.0;
  }
  return _searchBackView;
}

- (UIImageView *)searchImageView {
  if (!_searchImageView) {
    _searchImageView = [[UIImageView alloc] initWithImage:[coreLoader() loadImage:@"textField_search_icon"]];
    _searchImageView.translatesAutoresizingMaskIntoConstraints = NO;
  }
  return _searchImageView;
}

@end
