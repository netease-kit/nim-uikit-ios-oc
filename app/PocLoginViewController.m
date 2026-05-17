// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "PocLoginViewController.h"
#import "Main/AppKey.h"
#import "Manager/IMPocConfigManager.h"
#import <NIMSDK/NIMSDK.h>
#import <NECommonUIKitOC/UIView+YXToast.h>

@interface PocLoginViewController ()

@property (nonatomic, strong) UITextField *usernameTextField;
@property (nonatomic, strong) UITextField *passwordTextField;
@property (nonatomic, assign) BOOL isLogining;

@end

@implementation PocLoginViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.title = NELocalizable(@"login_by_account");
  self.view.backgroundColor = UIColor.whiteColor;
  [self setupUI];
}

- (void)setupUI {
  _usernameTextField = [[UITextField alloc] init];
  _usernameTextField.placeholder = @"用户名";
  _usernameTextField.borderStyle = UITextBorderStyleRoundedRect;
  _usernameTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
  _usernameTextField.autocorrectionType = UITextAutocorrectionTypeNo;
  _usernameTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
  _usernameTextField.translatesAutoresizingMaskIntoConstraints = NO;
  [self.view addSubview:_usernameTextField];

  _passwordTextField = [[UITextField alloc] init];
  _passwordTextField.placeholder = @"密码";
  _passwordTextField.borderStyle = UITextBorderStyleRoundedRect;
  _passwordTextField.secureTextEntry = YES;
  _passwordTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
  _passwordTextField.autocorrectionType = UITextAutocorrectionTypeNo;
  _passwordTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
  _passwordTextField.translatesAutoresizingMaskIntoConstraints = NO;
  [self.view addSubview:_passwordTextField];

  UIButton *loginButton = [UIButton buttonWithType:UIButtonTypeCustom];
  [loginButton setTitle:@"登录" forState:UIControlStateNormal];
  [loginButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
  loginButton.backgroundColor = [UIColor colorWithRed:0x33 / 255.0
                                                green:0x7E / 255.0
                                                 blue:0xFF / 255.0
                                                alpha:1.0];
  loginButton.layer.cornerRadius = 8;
  loginButton.translatesAutoresizingMaskIntoConstraints = NO;
  [loginButton addTarget:self action:@selector(login) forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:loginButton];

  UIButton *clearConfigButton = [UIButton buttonWithType:UIButtonTypeCustom];
  [clearConfigButton setTitle:@"清除私有化配置" forState:UIControlStateNormal];
  [clearConfigButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
  clearConfigButton.backgroundColor = [UIColor colorWithRed:0x33 / 255.0
                                                      green:0x7E / 255.0
                                                       blue:0xFF / 255.0
                                                      alpha:1.0];
  clearConfigButton.layer.cornerRadius = 8;
  clearConfigButton.translatesAutoresizingMaskIntoConstraints = NO;
  [clearConfigButton addTarget:self action:@selector(clearConfig) forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:clearConfigButton];

  CGFloat topConstant = 8.0;
  [NSLayoutConstraint activateConstraints:@[
    [_usernameTextField.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:topConstant],
    [_usernameTextField.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:20],
    [_usernameTextField.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant:-20],
    [_usernameTextField.heightAnchor constraintEqualToConstant:40],

    [_passwordTextField.topAnchor constraintEqualToAnchor:_usernameTextField.bottomAnchor constant:20],
    [_passwordTextField.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:20],
    [_passwordTextField.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant:-20],
    [_passwordTextField.heightAnchor constraintEqualToConstant:40],

    [loginButton.topAnchor constraintEqualToAnchor:_passwordTextField.bottomAnchor constant:20],
    [loginButton.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:20],
    [loginButton.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant:-20],
    [loginButton.heightAnchor constraintEqualToConstant:40],

    [clearConfigButton.topAnchor constraintEqualToAnchor:loginButton.bottomAnchor constant:20],
    [clearConfigButton.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:20],
    [clearConfigButton.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant:-20],
    [clearConfigButton.heightAnchor constraintEqualToConstant:40],
  ]];
}

- (void)login {
  if (self.isLogining) return;

  NSString *username = [_usernameTextField.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
  NSString *password = [_passwordTextField.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];

  if (username.length == 0 || password.length == 0) {
    [self.view endEditing:YES];
    [self showToast:@"请输入用户名和密码"];
    return;
  }

  self.isLogining = YES;
  V2NIMLoginOption *option = [[V2NIMLoginOption alloc] init];
  option.syncLevel = V2NIM_DATA_SYNC_TYPE_LEVEL_BASIC;

  [[NIMSDK sharedSDK].v2LoginService login:username
                                     token:password
                                    option:option
                                   success:^{
    dispatch_async(dispatch_get_main_queue(), ^{
      self.isLogining = NO;
      IMPocConfigModel *config = [[IMPocConfigManager instance] getConfig];
      config.accountId = username;
      config.accountIdToken = password;
      [[IMPocConfigManager instance] saveConfig:config];
      if (self.loginSuccess) self.loginSuccess();
    });
  } failure:^(V2NIMError * _Nonnull error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      self.isLogining = NO;
      [self.view endEditing:YES];
      [self showToast:[NSString stringWithFormat:@"登录失败: %@", error.nserror.localizedDescription ?: @""]];
    });
  }];
}

- (void)clearConfig {
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示"
                                                                 message:@"确定要清除私有化配置吗？"
                                                          preferredStyle:UIAlertControllerStyleAlert];
  [alert addAction:[UIAlertAction actionWithTitle:NELocalizable(@"cancel") style:UIAlertActionStyleCancel handler:nil]];
  [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
    [[IMPocConfigManager instance] clearConfig];
    [self showToast:@"清除成功，请重新启动应用"];
    [self.view endEditing:YES];
  }]];
  [self presentViewController:alert animated:YES completion:nil];
}

- (void)showToast:(NSString *)message {
  if (message.length > 0) {
    [self.view ne_makeToast:message];
  }
}

@end
