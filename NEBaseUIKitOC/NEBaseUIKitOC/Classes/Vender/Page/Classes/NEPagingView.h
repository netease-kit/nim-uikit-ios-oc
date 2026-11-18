// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class NEPagingOptions;

@interface NEPagingView : UIView

@property (nonatomic, strong, readonly) UICollectionView *collectionView;
@property (nonatomic, strong, readonly) UIView *pageView;
@property (nonatomic, strong) NEPagingOptions *options;

- (instancetype)initWithOptions:(NEPagingOptions *)options
                 collectionView:(UICollectionView *)collectionView
                       pageView:(UIView *)pageView;
- (void)configure;
- (void)setupConstraints;

@end

NS_ASSUME_NONNULL_END
