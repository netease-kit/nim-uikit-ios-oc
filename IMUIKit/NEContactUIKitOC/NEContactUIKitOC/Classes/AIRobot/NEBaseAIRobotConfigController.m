// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseAIRobotConfigController.h"
#import "ContactConst.h"
#import "FunContactUIColor.h"
#import "NormalContactUIColor.h"
#import <NEChatKitOC/UIColor+NECommon.h>
#import <NECommonUIKitOC/NECommonUIKitOC.h>
#import <NEChatKitOC/IMKitClient.h>

@interface NEBaseAIRobotConfigController ()

@property(nonatomic, copy) NSString *fullConfigString;

@end

@implementation NEBaseAIRobotConfigController

- (instancetype)initWithBot:(V2NIMUserAIBot *)bot {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _bot = bot;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  return [super initWithCoder:coder];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.title = contactLocalizable(@"ai_robot_config_title");
  self.navigationView.moreButton.hidden = YES;
  [self setupConfigUI];
  self.configLabel.text = self.fullConfigString;
}

- (NSString *)fullConfigString {
  NSString *appKey = [[IMKitClient instance] appKey] ?: @"";
  NSString *accid = self.bot.accid ?: @"";
  NSString *token = self.bot.token ?: @"";
  return [NSString stringWithFormat:@"%@|%@|%@", appKey, accid, token];
}

- (void)setupConfigUI {
  self.view.backgroundColor = [self pageBackgroundColor];

  [self.view addSubview:self.cardView];
  [NSLayoutConstraint activateConstraints:@[
    [self.cardView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:self.topConstant + [self cardTopMargin]],
    [self.cardView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:[self cardHorizontalMargin]],
    [self.cardView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant:-[self cardHorizontalMargin]],
  ]];
  [self setupCardCornerRadius];

  [self.cardView addSubview:self.titleLabel];
  [NSLayoutConstraint activateConstraints:@[
    [self.titleLabel.topAnchor constraintEqualToAnchor:self.cardView.topAnchor],
    [self.titleLabel.leftAnchor constraintEqualToAnchor:self.cardView.leftAnchor constant:16.0],
    [self.titleLabel.rightAnchor constraintEqualToAnchor:self.cardView.rightAnchor constant:-16.0],
    [self.titleLabel.heightAnchor constraintEqualToConstant:52.0],
  ]];

  [self.cardView addSubview:self.configLabel];
  [NSLayoutConstraint activateConstraints:@[
    [self.configLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor],
    [self.configLabel.leftAnchor constraintEqualToAnchor:self.cardView.leftAnchor constant:16.0],
    [self.configLabel.rightAnchor constraintEqualToAnchor:self.cardView.rightAnchor constant:-16.0],
    [self.configLabel.bottomAnchor constraintEqualToAnchor:self.cardView.bottomAnchor constant:-16.0],
  ]];

  [self.view addSubview:self.copyButton];
  [NSLayoutConstraint activateConstraints:@[
    [self.copyButton.topAnchor constraintEqualToAnchor:self.cardView.bottomAnchor constant:24.0],
    [self.copyButton.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:[self copyButtonHorizontalMargin]],
    [self.copyButton.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant:-[self copyButtonHorizontalMargin]],
    [self.copyButton.heightAnchor constraintEqualToConstant:50.0],
  ]];
  self.copyButton.backgroundColor = [self copyButtonColor];

  [self.view addSubview:self.warningLabel];
  [NSLayoutConstraint activateConstraints:@[
    [self.warningLabel.topAnchor constraintEqualToAnchor:self.copyButton.bottomAnchor constant:16.0],
    [self.warningLabel.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:16.0],
    [self.warningLabel.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant:-16.0],
  ]];
}

- (UIColor *)pageBackgroundColor {
  return [UIColor funContactNavigationBackgroundColor];
}

- (CGFloat)cardTopMargin {
  return 0.0;
}

- (CGFloat)cardHorizontalMargin {
  return 0.0;
}

- (CGFloat)copyButtonHorizontalMargin {
  return 20.0;
}

- (CGFloat)copyButtonCornerRadius {
  return 4.0;
}

- (UIColor *)copyButtonColor {
  return [UIColor normalContactThemeColor];
}

- (void)setupCardCornerRadius {
  self.cardView.layer.cornerRadius = 0.0;
  self.cardView.clipsToBounds = YES;
}

- (void)didTapCopy {
  [UIPasteboard generalPasteboard].string = self.fullConfigString;
  [self.view ne_makeToast:contactLocalizable(@"ai_robot_config_copy_success")];
}

#pragma mark - Lazy Init

- (UIView *)cardView {
  if (!_cardView) {
    _cardView = [[UIView alloc] init];
    _cardView.translatesAutoresizingMaskIntoConstraints = NO;
    _cardView.backgroundColor = [UIColor whiteColor];
  }
  return _cardView;
}

- (UILabel *)titleLabel {
  if (!_titleLabel) {
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _titleLabel.text = contactLocalizable(@"ai_robot_config_title");
    _titleLabel.font = [UIFont systemFontOfSize:16.0];
    _titleLabel.textColor = [UIColor ne_darkText];
  }
  return _titleLabel;
}

- (UIView *)divider {
  if (!_divider) {
    _divider = [[UIView alloc] init];
    _divider.translatesAutoresizingMaskIntoConstraints = NO;
    _divider.backgroundColor = [UIColor funContactLineBorderColor];
  }
  return _divider;
}

- (UILabel *)configLabel {
  if (!_configLabel) {
    _configLabel = [[UILabel alloc] init];
    _configLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _configLabel.font = [UIFont systemFontOfSize:14.0];
    _configLabel.textColor = [UIColor ne_lightText];
    _configLabel.numberOfLines = 1;
    _configLabel.lineBreakMode = NSLineBreakByTruncatingTail;
  }
  return _configLabel;
}

- (UIButton *)copyButton {
  if (!_copyButton) {
    _copyButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _copyButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_copyButton setTitle:contactLocalizable(@"ai_robot_config_copy") forState:UIControlStateNormal];
    [_copyButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _copyButton.titleLabel.font = [UIFont systemFontOfSize:16.0];
    _copyButton.layer.cornerRadius = [self copyButtonCornerRadius];
    _copyButton.clipsToBounds = YES;
    [_copyButton addTarget:self action:@selector(didTapCopy) forControlEvents:UIControlEventTouchUpInside];
  }
  return _copyButton;
}

- (UILabel *)warningLabel {
  if (!_warningLabel) {
    _warningLabel = [[UILabel alloc] init];
    _warningLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _warningLabel.text = contactLocalizable(@"ai_robot_config_warning");
    _warningLabel.font = [UIFont systemFontOfSize:14.0];
    _warningLabel.textColor = [UIColor ne_colorWithHexString:@"#FF9000"];
    _warningLabel.textAlignment = NSTextAlignmentCenter;
    _warningLabel.numberOfLines = 1;
  }
  return _warningLabel;
}

@end
