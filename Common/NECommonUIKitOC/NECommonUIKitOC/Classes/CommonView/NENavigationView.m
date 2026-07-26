// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NENavigationView.h"
#import "CommonUIConfig.h"
#import "NECommonUIConstant.h"
#import <NEChatKit/UIColor+NECommon.h>
#import <NEChatKit/NEConstant.h>
#import <NEChatKit/NEAppLanguageUtil.h>
#import <NEChatKit/NECommonLoader.h>

@interface NENavigationView ()
@property (nonatomic, strong, readwrite) UIButton *backButton;
@property (nonatomic, strong, readwrite) UILabel *navTitle;
@property (nonatomic, strong, readwrite) UIButton *moreButton;
@property (nonatomic, strong, readwrite) UIView *titleBarView;
@property (nonatomic, strong, readwrite) UIView *titleBarBottomLine;
@end

@implementation NENavigationView

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    _bottomMargin = 12;
    _leftMargin = 20;
    [self setupUI];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  if (self = [super initWithCoder:coder]) {
    _bottomMargin = 12;
    _leftMargin = 20;
  }
  return self;
}

- (void)setupUI {
  [self addSubview:self.titleBarView];
  [self addSubview:self.titleBarBottomLine];
  self.backgroundColor = [UIColor clearColor];

  self.titleBarBottomLineHeightAnchor = [self.titleBarBottomLine.heightAnchor constraintEqualToConstant:0.5];
  self.titleBarBottomLineHeightAnchor.active = YES;
  [NSLayoutConstraint activateConstraints:@[
    [self.titleBarBottomLine.leftAnchor constraintEqualToAnchor:self.leftAnchor],
    [self.titleBarBottomLine.rightAnchor constraintEqualToAnchor:self.rightAnchor],
    [self.titleBarBottomLine.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
  ]];

  [NSLayoutConstraint activateConstraints:@[
    [self.titleBarView.topAnchor constraintEqualToAnchor:self.topAnchor],
    [self.titleBarView.leftAnchor constraintEqualToAnchor:self.leftAnchor],
    [self.titleBarView.rightAnchor constraintEqualToAnchor:self.rightAnchor],
    [self.titleBarView.bottomAnchor constraintEqualToAnchor:self.titleBarBottomLine.topAnchor],
  ]];
}

#pragma mark - Back Button

- (void)setBackButtonTitle:(NSString *)title {
  self.backButton.hidden = NO;
  [self.backButton setTitle:title forState:UIControlStateNormal];
  [self.backButton setImage:nil forState:UIControlStateNormal];
}

- (void)setBackButtonImage:(UIImage *)image {
  self.backButton.hidden = NO;
  [self.backButton setTitle:@"" forState:UIControlStateNormal];
  [self.backButton setImage:image forState:UIControlStateNormal];
}

- (void)setBackButtonWidth:(CGFloat)width {
  self.backButtonWidthAnchor.constant = width;
}

- (void)addBackButtonTarget:(id)target selector:(SEL)selector {
  self.backButton.hidden = NO;
  [self.backButton addTarget:target action:selector forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark - More Button

- (void)setMoreButtonTitle:(NSString *)title {
  [self setMoreButtonTitle:title color:UIColor.ne_normalTheme];
}

- (void)setMoreButtonTitle:(NSString *)title color:(UIColor *)color {
  self.moreButton.hidden = NO;
  [self.moreButton setTitle:title forState:UIControlStateNormal];
  [self.moreButton setImage:nil forState:UIControlStateNormal];
  [self.moreButton setTitleColor:color forState:UIControlStateNormal];
}

- (void)setMoreButtonImage:(UIImage *)image {
  self.moreButton.hidden = NO;
  [self.moreButton setTitle:@"" forState:UIControlStateNormal];
  [self.moreButton setImage:image forState:UIControlStateNormal];
}

- (void)setMoreButtonWidth:(CGFloat)width {
  self.moreButtonWidthAnchor.constant = width;
}

- (void)addMoreButtonTarget:(id)target selector:(SEL)selector {
  self.moreButton.hidden = NO;
  [self.moreButton addTarget:target action:selector forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark - Appearance

- (void)setTitleBarBottomLineHeight:(CGFloat)height {
  self.titleBarBottomLineHeightAnchor.constant = height;
}

- (void)setNavigationBackgroundColor:(UIColor *)color {
  self.backgroundColor = color;
  self.titleBarBottomLine.backgroundColor = color;
}

#pragma mark - Lazy Getters

- (UIButton *)backButton {
  if (!_backButton) {
    _backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _backButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_backButton setImage:CommonUIConfig.shared.backArrowImage forState:UIControlStateNormal];
    _backButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [_backButton setTitleColor:UIColor.ne_darkText forState:UIControlStateNormal];
    _backButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    _backButton.accessibilityIdentifier = @"id.backArrow";
  }
  return _backButton;
}

- (UILabel *)navTitle {
  if (!_navTitle) {
    _navTitle = [[UILabel alloc] init];
    _navTitle.translatesAutoresizingMaskIntoConstraints = NO;
    _navTitle.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    _navTitle.textAlignment = NSTextAlignmentCenter;
    _navTitle.textColor = UIColor.ne_darkText;
    _navTitle.text = @"";
    _navTitle.accessibilityIdentifier = @"id.title";
  }
  return _navTitle;
}

- (UIButton *)moreButton {
  if (!_moreButton) {
    _moreButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _moreButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_moreButton setImage:[coreLoader() loadImage:@"three_point"] forState:UIControlStateNormal];
    _moreButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [_moreButton setTitleColor:UIColor.ne_normalTheme forState:UIControlStateNormal];
    _moreButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    _moreButton.accessibilityIdentifier = @"id.threePoint";
  }
  return _moreButton;
}

- (UIView *)titleBarView {
  if (!_titleBarView) {
    _titleBarView = [[UIView alloc] init];
    _titleBarView.translatesAutoresizingMaskIntoConstraints = NO;
    _titleBarView.backgroundColor = [UIColor clearColor];

    [_titleBarView addSubview:self.navTitle];
    [_titleBarView addSubview:self.backButton];
    [_titleBarView addSubview:self.moreButton];

    CGFloat isEnglish = ([NEAppLanguageUtil getCurrentLanguage] == NEAppLanguageEnglish);
    CGFloat buttonWidth = isEnglish ? 60 : 34;

    self.backButtonWidthAnchor = [self.backButton.widthAnchor constraintEqualToConstant:buttonWidth];
    self.backButtonWidthAnchor.active = YES;
    [NSLayoutConstraint activateConstraints:@[
      [self.backButton.leftAnchor constraintEqualToAnchor:_titleBarView.leftAnchor constant:self.leftMargin],
      [self.backButton.centerYAnchor constraintEqualToAnchor:self.navTitle.centerYAnchor],
      [self.backButton.heightAnchor constraintEqualToConstant:32],
    ]];

    self.moreButtonWidthAnchor = [self.moreButton.widthAnchor constraintEqualToConstant:buttonWidth];
    self.moreButtonWidthAnchor.active = YES;
    [NSLayoutConstraint activateConstraints:@[
      [self.moreButton.rightAnchor constraintEqualToAnchor:_titleBarView.rightAnchor constant:-self.leftMargin],
      [self.moreButton.centerYAnchor constraintEqualToAnchor:self.navTitle.centerYAnchor],
      [self.moreButton.heightAnchor constraintEqualToConstant:32],
    ]];

    CGFloat maxBtnWidth = MAX(self.backButtonWidthAnchor.constant, self.moreButtonWidthAnchor.constant);
    CGFloat titleMaxWidth = NEConstant.screenWidth - self.leftMargin * 4 - maxBtnWidth * 2;
    [NSLayoutConstraint activateConstraints:@[
      [self.navTitle.bottomAnchor constraintEqualToAnchor:_titleBarView.bottomAnchor constant:-self.bottomMargin],
      [self.navTitle.centerXAnchor constraintEqualToAnchor:_titleBarView.centerXAnchor],
      [self.navTitle.widthAnchor constraintLessThanOrEqualToConstant:titleMaxWidth],
    ]];
  }
  return _titleBarView;
}

- (UIView *)titleBarBottomLine {
  if (!_titleBarBottomLine) {
    _titleBarBottomLine = [[UIView alloc] init];
    _titleBarBottomLine.translatesAutoresizingMaskIntoConstraints = NO;
    _titleBarBottomLine.backgroundColor = [UIColor ne_colorWithHexString:@"#E9EFF5"];
    _titleBarBottomLine.hidden = YES;
  }
  return _titleBarBottomLine;
}

@end
