// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunSearchView.h"
#import <NEChatKitOC/NECommonLoader.h>
#import "NECommonUIConstant.h"
#import "UIView+YXToast.h"

@interface SearchSessionBaseView ()

@property (nonatomic, strong, readwrite) UILabel *titleLabel;
@property (nonatomic, strong, readwrite) UIView *bottomLine;

@end

@implementation SearchSessionBaseView

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithReuseIdentifier:reuseIdentifier];
  if (self) {
    [self setupUI];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    [self setupUI];
  }
  return self;
}

- (void)setupUI {
  [self.contentView addSubview:self.titleLabel];
  [self.contentView addSubview:self.bottomLine];
}

- (void)setUpTitle:(NSString *)title {
  self.titleLabel.text = title;
}

- (UILabel *)titleLabel {
  if (!_titleLabel) {
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _titleLabel.textColor = [UIColor colorWithRed:0x99 / 255.0
                                            green:0xA0 / 255.0
                                             blue:0xAB / 255.0
                                            alpha:1.0];
    _titleLabel.font = [UIFont systemFontOfSize:14.0];
    _titleLabel.textAlignment = NSTextAlignmentLeft;
  }
  return _titleLabel;
}

- (UIView *)bottomLine {
  if (!_bottomLine) {
    _bottomLine = [[UIView alloc] init];
    _bottomLine.translatesAutoresizingMaskIntoConstraints = NO;
    _bottomLine.backgroundColor = [UIColor colorWithRed:0xDB / 255.0
                                                  green:0xE0 / 255.0
                                                   blue:0xE8 / 255.0
                                                  alpha:1.0];
  }
  return _bottomLine;
}

@end

@implementation FunSearchSessionHeaderView

- (void)setupUI {
  [super setupUI];
  self.contentView.backgroundColor = UIColor.whiteColor;
  [NSLayoutConstraint activateConstraints:@[
    [self.titleLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [self.titleLabel.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:20.0],
    [self.bottomLine.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor],
    [self.bottomLine.leftAnchor constraintEqualToAnchor:self.titleLabel.leftAnchor],
    [self.bottomLine.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
    [self.bottomLine.heightAnchor constraintEqualToConstant:1.0],
  ]];
}

@end

@interface FunSearchView ()

@property (nonatomic, strong, readwrite) UIView *backView;
@property (nonatomic, strong, readwrite) UIButton *searchButton;

@end

@implementation FunSearchView

- (instancetype)initWithSearchButtonLeftConstant:(CGFloat)searchButtonLeftConstant
                       searchButtonRightConstant:(CGFloat)searchButtonRightConstant {
  self = [super initWithFrame:CGRectZero];
  if (self) {
    _searchButtonLeftConstant = searchButtonLeftConstant;
    _searchButtonRightConstant = searchButtonRightConstant;
    [self setupSubViews];
  }
  return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self setupSubViews];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    [self setupSubViews];
  }
  return self;
}

- (void)setupSubViews {
  [self addSubview:self.backView];
  [NSLayoutConstraint activateConstraints:@[
    [self.backView.leftAnchor constraintEqualToAnchor:self.leftAnchor],
    [self.backView.rightAnchor constraintEqualToAnchor:self.rightAnchor],
    [self.backView.topAnchor constraintEqualToAnchor:self.topAnchor],
    [self.backView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
  ]];

  [self.backView addSubview:self.searchButton];
  [NSLayoutConstraint activateConstraints:@[
    [self.searchButton.centerYAnchor constraintEqualToAnchor:self.backView.centerYAnchor],
    [self.searchButton.leftAnchor constraintEqualToAnchor:self.backView.leftAnchor
                                                 constant:self.searchButtonLeftConstant],
    [self.searchButton.rightAnchor constraintEqualToAnchor:self.backView.rightAnchor
                                                  constant:-self.searchButtonRightConstant],
  ]];
}

- (void)updateSearchButtonConstantWithSearchButtonLeftConstant:(NSNumber *)searchButtonLeftConstant
                                     searchButtonRightConstant:(NSNumber *)searchButtonRightConstant {
  if (searchButtonLeftConstant) {
    [self.backView updateLayoutConstraintFirstItem:self.searchButton
                                        secondItem:self.backView
                                         attribute:NSLayoutAttributeLeft
                                          constant:searchButtonLeftConstant.doubleValue];
  }

  if (searchButtonRightConstant) {
    [self.backView updateLayoutConstraintFirstItem:self.searchButton
                                        secondItem:self.backView
                                         attribute:NSLayoutAttributeRight
                                          constant:-searchButtonRightConstant.doubleValue];
  }
}

- (UIView *)backView {
  if (!_backView) {
    _backView = [[UIView alloc] init];
    _backView.translatesAutoresizingMaskIntoConstraints = NO;
    _backView.backgroundColor = UIColor.whiteColor;
    _backView.layer.cornerRadius = 4.0;
  }
  return _backView;
}

- (UIButton *)searchButton {
  if (!_searchButton) {
    _searchButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _searchButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_searchButton setImage:[coreLoader() loadImage:@"fun_search"] forState:UIControlStateNormal];
    [_searchButton setTitle:commonLocalizable(@"search") forState:UIControlStateNormal];
    [_searchButton setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    _searchButton.titleLabel.alpha = 0.3;
    _searchButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    _searchButton.semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;
    _searchButton.titleEdgeInsets = UIEdgeInsetsMake(0, 8, 0, -8);
    _searchButton.userInteractionEnabled = NO;
    _searchButton.accessibilityIdentifier = @"id.titleBarSearchImg";
  }
  return _searchButton;
}

@end
