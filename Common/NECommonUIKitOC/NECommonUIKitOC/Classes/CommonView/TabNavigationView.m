// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "TabNavigationView.h"
#import "NECommonUIConstant.h"
#import "ExpandButton.h"
#import <NEChatKitOC/NEConstant.h>
#import <NEChatKitOC/UIColor+NECommon.h>
#import <NEChatKitOC/NECommonLoader.h>

@interface TabNavigationView ()
@property (nonatomic, strong, readwrite) UIButton *brandBtn;
@property (nonatomic, strong, readwrite) UILabel *navigationTitle;
@property (nonatomic, strong, readwrite) UIButton *searchBtn;
@property (nonatomic, strong, readwrite) ExpandButton *addBtn;
@property (nonatomic, strong, readwrite) UIView *titleBarView;
@property (nonatomic, strong, readwrite) UIView *titleBarBottomLine;
@end

@implementation TabNavigationView

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    _titleBarBottomLineHeight = 0.5;
    [self setupSubviews];
    self.backgroundColor = [UIColor clearColor];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  if (self = [super initWithCoder:coder]) {
    _titleBarBottomLineHeight = 0.5;
  }
  return self;
}

- (void)setupSubviews {
  [self addSubview:self.titleBarView];
  [self addSubview:self.titleBarBottomLine];

  [NSLayoutConstraint activateConstraints:@[
    [self.titleBarView.topAnchor constraintEqualToAnchor:self.topAnchor],
    [self.titleBarView.leftAnchor constraintEqualToAnchor:self.leftAnchor],
    [self.titleBarView.rightAnchor constraintEqualToAnchor:self.rightAnchor],
    [self.titleBarView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-self.titleBarBottomLineHeight],
  ]];

  [NSLayoutConstraint activateConstraints:@[
    [self.titleBarBottomLine.leftAnchor constraintEqualToAnchor:self.leftAnchor],
    [self.titleBarBottomLine.rightAnchor constraintEqualToAnchor:self.rightAnchor],
    [self.titleBarBottomLine.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
    [self.titleBarBottomLine.heightAnchor constraintEqualToConstant:self.titleBarBottomLineHeight],
  ]];
}

#pragma mark - Actions

- (void)brandBtnClick:(UIButton *)sender {
  if ([self.delegate respondsToSelector:@selector(brandBtnClick)]) {
    [self.delegate brandBtnClick];
  }
}

- (void)searchBtnClick:(UIButton *)sender {
  if ([self.delegate respondsToSelector:@selector(searchAction)]) {
    [self.delegate searchAction];
  }
}

- (void)addBtnClick:(UIButton *)sender {
  if ([self.delegate respondsToSelector:@selector(didClickAddBtn)]) {
    [self.delegate didClickAddBtn];
  }
}

#pragma mark - Lazy Getters

- (UIButton *)brandBtn {
  if (!_brandBtn) {
    _brandBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _brandBtn.accessibilityIdentifier = @"id.titleBarTitle";
    [_brandBtn setTitle:commonLocalizable(@"appName") forState:UIControlStateNormal];
    [_brandBtn setImage:[coreLoader() loadImage:@"brand_yunxin"] forState:UIControlStateNormal];
    _brandBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [_brandBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    _brandBtn.titleLabel.font = [NEConstant textFont:@"PingFangSC-Medium" size:20];
    [_brandBtn addTarget:self action:@selector(brandBtnClick:) forControlEvents:UIControlEventTouchUpInside];
  }
  return _brandBtn;
}

- (UILabel *)navigationTitle {
  if (!_navigationTitle) {
    _navigationTitle = [[UILabel alloc] init];
    _navigationTitle.translatesAutoresizingMaskIntoConstraints = NO;
    _navigationTitle.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    _navigationTitle.hidden = YES;
    _navigationTitle.accessibilityIdentifier = @"id.titleBarTitle";
  }
  return _navigationTitle;
}

- (UIButton *)searchBtn {
  if (!_searchBtn) {
    _searchBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _searchBtn.accessibilityIdentifier = @"id.titleBarSearchImg";
    [_searchBtn setImage:[coreLoader() loadImage:@"nav_search"] forState:UIControlStateNormal];
    _searchBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [_searchBtn addTarget:self action:@selector(searchBtnClick:) forControlEvents:UIControlEventTouchUpInside];
  }
  return _searchBtn;
}

- (ExpandButton *)addBtn {
  if (!_addBtn) {
    _addBtn = [[ExpandButton alloc] init];
    _addBtn.accessibilityIdentifier = @"id.titleBarMoreImg";
    [_addBtn setImage:[coreLoader() loadImage:@"nav_add"] forState:UIControlStateNormal];
    _addBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [_addBtn addTarget:self action:@selector(addBtnClick:) forControlEvents:UIControlEventTouchUpInside];
  }
  return _addBtn;
}

- (UIView *)titleBarView {
  if (!_titleBarView) {
    _titleBarView = [[UIView alloc] init];
    _titleBarView.translatesAutoresizingMaskIntoConstraints = NO;
    _titleBarView.backgroundColor = [UIColor clearColor];

    [_titleBarView addSubview:self.brandBtn];
    [_titleBarView addSubview:self.navigationTitle];
    [_titleBarView addSubview:self.searchBtn];
    [_titleBarView addSubview:self.addBtn];

    CGFloat interval = NEConstant.screenInterval;

    [NSLayoutConstraint activateConstraints:@[
      [self.brandBtn.bottomAnchor constraintEqualToAnchor:_titleBarView.bottomAnchor constant:-12],
      [self.brandBtn.leftAnchor constraintEqualToAnchor:_titleBarView.leftAnchor constant:interval],
    ]];

    [NSLayoutConstraint activateConstraints:@[
      [self.navigationTitle.centerXAnchor constraintEqualToAnchor:_titleBarView.centerXAnchor],
      [self.navigationTitle.centerYAnchor constraintEqualToAnchor:self.brandBtn.centerYAnchor],
    ]];

    [NSLayoutConstraint activateConstraints:@[
      [self.addBtn.centerYAnchor constraintEqualToAnchor:self.brandBtn.centerYAnchor],
      [self.addBtn.rightAnchor constraintEqualToAnchor:_titleBarView.rightAnchor constant:-interval],
      [self.addBtn.widthAnchor constraintEqualToConstant:20],
      [self.addBtn.heightAnchor constraintEqualToConstant:20],
    ]];

    [NSLayoutConstraint activateConstraints:@[
      [self.searchBtn.centerYAnchor constraintEqualToAnchor:self.brandBtn.centerYAnchor],
      [self.searchBtn.rightAnchor constraintEqualToAnchor:self.addBtn.leftAnchor constant:-interval],
      [self.searchBtn.widthAnchor constraintEqualToConstant:20],
      [self.searchBtn.heightAnchor constraintEqualToConstant:20],
    ]];
  }
  return _titleBarView;
}

- (UIView *)titleBarBottomLine {
  if (!_titleBarBottomLine) {
    _titleBarBottomLine = [[UIView alloc] init];
    _titleBarBottomLine.translatesAutoresizingMaskIntoConstraints = NO;
    _titleBarBottomLine.backgroundColor = [UIColor ne_colorWithHexString:@"0xDBE0E8"];
  }
  return _titleBarBottomLine;
}

@end
