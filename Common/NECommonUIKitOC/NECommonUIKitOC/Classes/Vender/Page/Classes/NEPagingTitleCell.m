// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEPagingTitleCell.h"
#import "NEPagingCellLayoutAttributes.h"
#import "NEPagingCellViewModel.h"
#import "NEPagingIndexItem.h"
#import "NEPagingOptions.h"
#import "UIColor+interpolation.h"

@interface NEPagingTitleCell ()

@property (nonatomic, strong, readwrite) UILabel *titleLabel;
@property (nonatomic, strong, nullable) NEPagingTitleCellViewModel *viewModel;
@property (nonatomic, copy) NSArray<NSLayoutConstraint *> *horizontalConstraints;
@property (nonatomic, copy) NSArray<NSLayoutConstraint *> *verticalConstraints;

@end

@implementation NEPagingTitleCell

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self configure];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    [self configure];
  }
  return self;
}

- (void)setSelected:(BOOL)selected {
  [super setSelected:selected];
  [self configureTitleLabel];
}

- (void)setPagingItem:(id<NEPagingItem>)pagingItem
             selected:(BOOL)selected
              options:(NEPagingOptions *)options {
  if ([pagingItem isKindOfClass:[NEPagingIndexItem class]]) {
    NEPagingIndexItem *titleItem = (NEPagingIndexItem *)pagingItem;
    self.viewModel = [[NEPagingTitleCellViewModel alloc] initWithTitle:titleItem.title
                                                              selected:selected
                                                               options:options];
  } else {
    self.viewModel = nil;
  }
  [self configureTitleLabel];
  [self configureAccessibility];
}

- (void)configure {
  _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
  _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
  [self.contentView addSubview:_titleLabel];
  self.contentView.isAccessibilityElement = YES;

  self.horizontalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[label]|"
                                                                       options:0
                                                                       metrics:nil
                                                                         views:@{ @"label" : _titleLabel }];
  self.verticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[label]|"
                                                                     options:0
                                                                     metrics:nil
                                                                       views:@{ @"label" : _titleLabel }];
  [self.contentView addConstraints:self.horizontalConstraints];
  [self.contentView addConstraints:self.verticalConstraints];
}

- (void)configureTitleLabel {
  if (!self.viewModel) {
    return;
  }
  self.titleLabel.text = self.viewModel.title;
  self.titleLabel.textAlignment = NSTextAlignmentCenter;

  if (self.viewModel.isSelected) {
    self.titleLabel.font = self.viewModel.selectedFont;
    self.titleLabel.textColor = self.viewModel.selectedTextColor;
    self.backgroundColor = self.viewModel.selectedBackgroundColor;
  } else {
    self.titleLabel.font = self.viewModel.font;
    self.titleLabel.textColor = self.viewModel.textColor;
    self.backgroundColor = self.viewModel.backgroundColor;
  }

  for (NSLayoutConstraint *constraint in self.horizontalConstraints) {
    constraint.constant = self.viewModel.labelSpacing;
  }
}

- (void)configureAccessibility {
  self.accessibilityIdentifier = self.viewModel.title;
  self.contentView.accessibilityLabel = self.viewModel.title;
  self.contentView.accessibilityTraits = self.viewModel.isSelected ? (UIAccessibilityTraitTabBar | UIAccessibilityTraitSelected) : UIAccessibilityTraitTabBar;
}

- (void)applyLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes {
  [super applyLayoutAttributes:layoutAttributes];
  if (!self.viewModel || ![layoutAttributes isKindOfClass:[NEPagingCellLayoutAttributes class]]) {
    return;
  }
  NEPagingCellLayoutAttributes *attributes = (NEPagingCellLayoutAttributes *)layoutAttributes;
  self.titleLabel.textColor = [UIColor interpolateFrom:self.viewModel.textColor
                                                    to:self.viewModel.selectedTextColor
                                          withFraction:attributes.progress];
  self.backgroundColor = [UIColor interpolateFrom:self.viewModel.backgroundColor
                                               to:self.viewModel.selectedBackgroundColor
                                     withFraction:attributes.progress];
}

@end
