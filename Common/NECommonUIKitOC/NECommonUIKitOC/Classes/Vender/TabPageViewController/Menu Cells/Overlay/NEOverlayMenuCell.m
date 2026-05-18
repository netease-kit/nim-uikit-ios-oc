// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEOverlayMenuCell.h"

@interface NEOverlayMenuCell ()

@property (nonatomic, assign) UIEdgeInsets maskInsets;
@property (nonatomic, strong) UIView *textMaskView;
@property (nonatomic, strong) UILabel *highlightLabel;
@property (nonatomic, strong) UILabel *titleLabel;

@end

@implementation NEOverlayMenuCell

+ (instancetype)sizingCell {
  static NEOverlayMenuCell *cell;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    cell = [[self alloc] initWithFrame:CGRectZero];
  });
  return cell;
}

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self commonInit];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    [self commonInit];
  }
  return self;
}

- (void)commonInit {
  self.maskInsets = UIEdgeInsetsMake(6, 8, 6, 8);
  self.textMaskView = [[UIView alloc] init];
  self.textMaskView.backgroundColor = UIColor.blackColor;

  self.highlightLabel = [[UILabel alloc] init];
  self.highlightLabel.textColor = UIColor.whiteColor;
  self.highlightLabel.maskView = self.textMaskView;

  self.titleLabel = [[UILabel alloc] init];
  [self addConstraintViews];
}

- (void)layoutSubviews {
  [super layoutSubviews];
  self.textMaskView.bounds = UIEdgeInsetsInsetRect(self.bounds, self.maskInsets);
}

- (UIColor *)hightlightTextColor {
  return self.highlightLabel.textColor;
}

- (void)setHightlightTextColor:(UIColor *)hightlightTextColor {
  self.highlightLabel.textColor = hightlightTextColor;
}

- (UIColor *)normalTextColor {
  return self.titleLabel.textColor;
}

- (void)setNormalTextColor:(UIColor *)normalTextColor {
  self.titleLabel.textColor = normalTextColor;
}

- (UIFont *)hightlightTextFont {
  return self.highlightLabel.font;
}

- (void)setHightlightTextFont:(UIFont *)hightlightTextFont {
  self.highlightLabel.font = hightlightTextFont;
}

- (UIFont *)normalTextFont {
  return self.titleLabel.font;
}

- (void)setNormalTextFont:(UIFont *)normalTextFont {
  self.titleLabel.font = normalTextFont;
}

- (void)configureWithTitle:(NSString *)title {
  self.titleLabel.text = title;
  self.highlightLabel.text = title;
}

- (void)updateMaskAnimated:(BOOL)animated {
  if (!self.referencedMenuView || !self.referencedFocusView) {
    return;
  }
  [self setFrameForMenuView:self.referencedMenuView
                  maskFrame:self.referencedFocusView.frame
                   animated:animated];
}

- (CGFloat)calculateWidthFromHeight:(CGFloat)height title:(NSString *)title {
  [self configureWithTitle:title];
  CGSize referenceSize = UILayoutFittingCompressedSize;
  referenceSize.height = height;
  CGSize size = [self systemLayoutSizeFittingSize:referenceSize
                    withHorizontalFittingPriority:UILayoutPriorityDefaultLow
                          verticalFittingPriority:UILayoutPriorityDefaultHigh];
  return size.width;
}

- (void)setFrameForMenuView:(NETabPagingMenuView *)menuView
                  maskFrame:(CGRect)maskFrame
                   animated:(BOOL)animated {
  self.textMaskView.frame = UIEdgeInsetsInsetRect([menuView convertRect:maskFrame toView:self.highlightLabel], self.maskInsets);
  NSNumber *expectedOriginX = [menuView expectedAlignmentPositionXIfNeeded];
  if (expectedOriginX) {
    CGRect frame = self.textMaskView.frame;
    frame.origin.x += expectedOriginX.doubleValue;
    self.textMaskView.frame = frame;
  }
}

- (void)addConstraintViews {
  [self addSubview:self.titleLabel];
  [self addSubview:self.highlightLabel];
  self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
  self.highlightLabel.translatesAutoresizingMaskIntoConstraints = NO;

  for (UILabel *label in @[ self.titleLabel, self.highlightLabel ]) {
    NSLayoutConstraint *trailingConstraint =
        [NSLayoutConstraint constraintWithItem:self
                                     attribute:NSLayoutAttributeTrailing
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:label
                                     attribute:NSLayoutAttributeTrailing
                                    multiplier:1.0
                                      constant:16.0];
    NSLayoutConstraint *leadingConstraint =
        [NSLayoutConstraint constraintWithItem:label
                                     attribute:NSLayoutAttributeLeading
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:self
                                     attribute:NSLayoutAttributeLeading
                                    multiplier:1.0
                                      constant:16.0];
    NSLayoutConstraint *bottomConstraint =
        [NSLayoutConstraint constraintWithItem:self
                                     attribute:NSLayoutAttributeTop
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:label
                                     attribute:NSLayoutAttributeTop
                                    multiplier:1.0
                                      constant:8.0];
    NSLayoutConstraint *topConstraint =
        [NSLayoutConstraint constraintWithItem:label
                                     attribute:NSLayoutAttributeBottom
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:self
                                     attribute:NSLayoutAttributeBottom
                                    multiplier:1.0
                                      constant:8.0];
    [self addConstraints:@[
      topConstraint,
      bottomConstraint,
      trailingConstraint,
      leadingConstraint,
    ]];
  }
}

@end
