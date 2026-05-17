// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NETitleLabelMenuViewCell.h"

#import "NEPagingKitProxy.h"

@interface NETitleLabelMenuViewCell ()

@property (nonatomic, strong, readwrite) UILabel *titleLabel;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIStackView *stackView;

@end

@implementation NETitleLabelMenuViewCell

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self setup];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    [self setup];
  }
  return self;
}

- (void)setup {
  self.focusColor = NEPagingKitConfig.focusColor;
  self.normalColor = NEPagingKitConfig.normalColor;
  self.backgroundColor = UIColor.clearColor;

  self.imageView = [[UIImageView alloc] init];
  self.imageView.hidden = YES;
  self.imageView.contentMode = UIViewContentModeScaleAspectFit;

  self.titleLabel = [[UILabel alloc] init];
  self.titleLabel.font = NEPagingKitConfig.menuTitleFont;
  self.titleLabel.backgroundColor = UIColor.clearColor;
  self.titleLabel.textAlignment = NSTextAlignmentCenter;

  self.stackView = [[UIStackView alloc] init];
  self.stackView.axis = UILayoutConstraintAxisHorizontal;
  self.stackView.spacing = 4.0;
  [self.stackView addArrangedSubview:self.imageView];
  [self.stackView addArrangedSubview:self.titleLabel];
  self.stackView.translatesAutoresizingMaskIntoConstraints = NO;

  [self addSubview:self.stackView];
  [self addConstraints:@[
    [self anchorLabelFromItem:self.stackView toItem:self constant:8 attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual],
    [self anchorLabelFromItem:self.stackView toItem:self constant:8 attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationGreaterThanOrEqual],
    [self anchorLabelFromItem:self toItem:self.stackView constant:8 attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationGreaterThanOrEqual],
    [self anchorLabelFromItem:self toItem:self.stackView constant:8 attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual],
    [self anchorLabelFromItem:self.stackView toItem:self constant:0 attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual],
  ]];

  [self updateSelectedState];
}

- (CGFloat)labelWidth {
  return CGRectGetWidth(self.stackView.bounds);
}

- (CGFloat)spacing {
  return self.stackView.spacing;
}

- (void)setSpacing:(CGFloat)spacing {
  self.stackView.spacing = spacing;
}

- (void)setImage:(UIImage *)image {
  self.imageView.image = image;
  self.imageView.hidden = (image == nil);
}

- (CGFloat)calcIntermediateLabelSizeWithCurrentCell:(NETitleLabelMenuViewCell *)currentCell
                                            percent:(CGFloat)percent {
  CGFloat diff = (self.labelWidth - currentCell.labelWidth) * fabs(percent);
  return currentCell.labelWidth + diff;
}

- (void)setSelected:(BOOL)selected {
  [super setSelected:selected];
  [self updateSelectedState];
}

- (void)setFocusColor:(UIColor *)focusColor {
  _focusColor = focusColor ?: NEPagingKitConfig.focusColor;
  if (self.isSelected) {
    [self updateSelectedState];
  }
}

- (void)setNormalColor:(UIColor *)normalColor {
  _normalColor = normalColor ?: NEPagingKitConfig.normalColor;
  if (!self.isSelected) {
    [self updateSelectedState];
  }
}

- (void)updateSelectedState {
  UIColor *color = self.isSelected ? self.focusColor : self.normalColor;
  self.imageView.tintColor = color;
  self.titleLabel.textColor = color;
}

- (NSLayoutConstraint *)anchorLabelFromItem:(id)fromItem
                                     toItem:(id)toItem
                                   constant:(CGFloat)constant
                                  attribute:(NSLayoutAttribute)attribute
                                  relatedBy:(NSLayoutRelation)relatedBy {
  return [NSLayoutConstraint constraintWithItem:fromItem
                                      attribute:attribute
                                      relatedBy:relatedBy
                                         toItem:toItem
                                      attribute:attribute
                                     multiplier:1.0
                                       constant:constant];
}

@end
