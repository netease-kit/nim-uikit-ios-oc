// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEPagingView.h"
#import "NEPagingOptions.h"

@interface NEPagingView ()

@property (nonatomic, strong, readwrite) UICollectionView *collectionView;
@property (nonatomic, strong, readwrite) UIView *pageView;
@property (nonatomic, strong, nullable) NSLayoutConstraint *heightConstraint;

@end

@implementation NEPagingView

- (instancetype)initWithOptions:(NEPagingOptions *)options
                 collectionView:(UICollectionView *)collectionView
                       pageView:(UIView *)pageView {
  self = [super initWithFrame:CGRectZero];
  if (self) {
    _options = options ?: [[NEPagingOptions alloc] init];
    _collectionView = collectionView;
    _pageView = pageView;
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  [NSException raise:NSInternalInconsistencyException format:@"initWithCoder: has not been implemented"];
  return nil;
}

- (void)configure {
  self.collectionView.backgroundColor = self.options.menuBackgroundColor;
  [self addSubview:self.pageView];
  [self addSubview:self.collectionView];
  [self setupConstraints];
}

- (void)setupConstraints {
  self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
  self.pageView.translatesAutoresizingMaskIntoConstraints = NO;
  NSDictionary *views = @{ @"collectionView": self.collectionView, @"pageView": self.pageView };
  NSDictionary *metrics = @{ @"height": @(self.options.menuHeight) };
  [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[collectionView]|"
                                                               options:0
                                                               metrics:metrics
                                                                 views:views]];
  [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[pageView]|"
                                                               options:0
                                                               metrics:metrics
                                                                 views:views]];
  NSArray<NSLayoutConstraint *> *verticalConstraints = nil;
  switch (self.options.menuPosition) {
    case NEPagingMenuPositionTop:
      verticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[collectionView(==height)][pageView]|"
                                                                    options:0
                                                                    metrics:metrics
                                                                      views:views];
      break;
    case NEPagingMenuPositionBottom:
      verticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[pageView][collectionView(==height)]|"
                                                                    options:0
                                                                    metrics:metrics
                                                                      views:views];
      break;
  }
  [self addConstraints:verticalConstraints];
  for (NSLayoutConstraint *constraint in verticalConstraints) {
    if (constraint.firstAttribute == NSLayoutAttributeHeight) {
      self.heightConstraint = constraint;
      break;
    }
  }
}

- (void)setOptions:(NEPagingOptions *)options {
  _options = options ?: [[NEPagingOptions alloc] init];
  self.heightConstraint.constant = self.options.menuHeight;
  self.collectionView.backgroundColor = self.options.menuBackgroundColor;
}

@end
