// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "LoginViewController.h"
#import <NEChatKit/NEChatKit.h>
#import "Main/AppKey.h"
#import "Mine/Controller/IMPocConfigViewController.h"
#import "Mine/Controller/NENodeViewController.h"
#import "PocLoginViewController.h"
#import <NEBaseUIKitOC/UIView+YXToast.h>

@interface LoginViewController ()

@property (nonatomic, strong) UIImageView *launchIconView;
@property (nonatomic, strong) UILabel *launchIconLabel;
@property (nonatomic, strong) UIButton *loginButton;
@property (nonatomic, strong) UIButton *emailLoginButton;
@property (nonatomic, strong) UIButton *pocLoginButton;
@property (nonatomic, strong) UIButton *nodeButton;
@property (nonatomic, strong) UIButton *pocSettingButton;

@end

@implementation LoginViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = UIColor.whiteColor;
  [self setupUI];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  self.navigationController.navigationBarHidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  self.navigationController.navigationBarHidden = NO;
}

- (void)setupUI {
  self.launchIconView = [[UIImageView alloc] init];
  self.launchIconView.translatesAutoresizingMaskIntoConstraints = NO;
  self.launchIconView.contentMode = UIViewContentModeScaleAspectFit;
  self.launchIconView.image = [UIImage imageNamed:@"launchIcon"];
  if (!self.launchIconView.image) {
    self.launchIconView.backgroundColor = [UIColor colorWithRed:0x33 / 255.0
                                                          green:0x7E / 255.0
                                                           blue:0xFF / 255.0
                                                          alpha:1.0];
    self.launchIconView.layer.cornerRadius = 24.0;
    self.launchIconView.clipsToBounds = YES;
  }
  [self.view addSubview:self.launchIconView];

  self.launchIconLabel = [[UILabel alloc] init];
  self.launchIconLabel.translatesAutoresizingMaskIntoConstraints = NO;
  self.launchIconLabel.text = NELocalizable(@"appName");
  self.launchIconLabel.font = [UIFont systemFontOfSize:24.0];
  self.launchIconLabel.textColor = [UIColor colorWithRed:0x33 / 255.0
                                                   green:0x33 / 255.0
                                                    blue:0x33 / 255.0
                                                   alpha:1.0];
  self.launchIconLabel.textAlignment = NSTextAlignmentCenter;
  self.launchIconLabel.accessibilityIdentifier = @"id.appYunxin";
  [self.view addSubview:self.launchIconLabel];

  self.loginButton = [UIButton buttonWithType:UIButtonTypeCustom];
  self.loginButton.translatesAutoresizingMaskIntoConstraints = NO;
  self.loginButton.layer.cornerRadius = 8.0;
  self.loginButton.backgroundColor = [UIColor colorWithRed:0x33 / 255.0
                                                     green:0x7E / 255.0
                                                      blue:0xFF / 255.0
                                                     alpha:1.0];
  [self.loginButton setTitle:NELocalizable(@"register_login") forState:UIControlStateNormal];
  [self.loginButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
  self.loginButton.titleLabel.font = [UIFont systemFontOfSize:15.0];
  self.loginButton.accessibilityIdentifier = @"id.loginButton";
  [self.loginButton addTarget:self action:@selector(loginBtnClick) forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:self.loginButton];

  self.emailLoginButton = [self makeBottomButton:NELocalizable(@"email_login")
                                        accessId:@"id.emailLogin"
                                          action:@selector(emailLoginBtnClick)];
  self.nodeButton = [self makeBottomButton:NELocalizable(@"node_select")
                                  accessId:@"id.serverConfig"
                                    action:@selector(nodeBtnClick)];
  self.pocSettingButton = [self makeBottomButton:NELocalizable(@"privatized_configuration")
                                        accessId:@"id.pocSetting"
                                          action:@selector(pocSettingBtnClick)];
  self.pocLoginButton = [self makeBottomButton:NELocalizable(@"login_by_account")
                                      accessId:@"id.pocLogin"
                                        action:@selector(pocLoginBtnClick)];

  UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[
    self.emailLoginButton, self.nodeButton, self.pocSettingButton, self.pocLoginButton
  ]];
  stack.translatesAutoresizingMaskIntoConstraints = NO;
  stack.axis = UILayoutConstraintAxisHorizontal;
  stack.alignment = UIStackViewAlignmentCenter;
  stack.distribution = UIStackViewDistributionFillEqually;
  stack.spacing = 8;
  [self.view addSubview:stack];

  CGFloat screenWidth = UIScreen.mainScreen.bounds.size.width;
  [NSLayoutConstraint activateConstraints:@[
    [self.launchIconView.widthAnchor constraintEqualToConstant:88],
    [self.launchIconView.heightAnchor constraintEqualToConstant:88],
    [self.launchIconView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
    [self.launchIconView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:145.0],
    [self.launchIconLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
    [self.launchIconLabel.topAnchor constraintEqualToAnchor:self.launchIconView.bottomAnchor constant:-12.0],
    [self.loginButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
    [self.loginButton.topAnchor constraintEqualToAnchor:self.launchIconLabel.bottomAnchor constant:20.0],
    [self.loginButton.widthAnchor constraintEqualToConstant:screenWidth - 80.0],
    [self.loginButton.heightAnchor constraintEqualToConstant:44.0],
    [stack.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
    [stack.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-70.0],
    [stack.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:20],
    [stack.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant:-20],
    [stack.heightAnchor constraintEqualToConstant:44.0],
  ]];
}

- (UIButton *)makeBottomButton:(NSString *)title accessId:(NSString *)accessId action:(SEL)action {
  UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
  [btn setTitle:title forState:UIControlStateNormal];
  [btn setTitleColor:[UIColor colorWithRed:0x99 / 255.0
                                     green:0x99 / 255.0
                                      blue:0x99 / 255.0
                                     alpha:1.0]
            forState:UIControlStateNormal];
  btn.titleLabel.font = [UIFont systemFontOfSize:12.0];
  btn.accessibilityIdentifier = accessId;
  [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
  return btn;
}

- (void)loginBtnClick {
  if (NEAppKey.length == 0 || NEAppAccount.length == 0 || NEAppToken.length == 0) {
    [self.view ne_makeToast:@"请先配置本地 AppKey、账号和 Token"];
    return;
  }

  __weak typeof(self) weakSelf = self;
  [[IMKitClient instance] login:NEAppAccount
                          token:NEAppToken
                     completion:^(NSError * _Nullable error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      if (error) {
        [weakSelf.view ne_makeToast:error.localizedDescription ?: @""];
      } else if (weakSelf.loginSuccess) {
        weakSelf.loginSuccess();
      }
    });
  }];
}

- (void)emailLoginBtnClick {
}

- (void)pocLoginBtnClick {
  PocLoginViewController *vc = [[PocLoginViewController alloc] init];
  vc.loginSuccess = self.loginSuccess;
  [self.navigationController pushViewController:vc animated:YES];
}

- (void)nodeBtnClick {
  NENodeViewController *vc = [[NENodeViewController alloc] init];
  [self.navigationController pushViewController:vc animated:YES];
}

- (void)pocSettingBtnClick {
  IMPocConfigViewController *vc = [[IMPocConfigViewController alloc] init];
  [self.navigationController pushViewController:vc animated:YES];
}

@end
