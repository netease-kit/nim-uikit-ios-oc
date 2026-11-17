// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class NEPagingOptions;

@interface NEPagingBorderLayoutAttributes : UICollectionViewLayoutAttributes

@property (nonatomic, strong, nullable) UIColor *backgroundColor;
@property (nonatomic, assign) UIEdgeInsets insets;

- (void)configureWithOptions:(NEPagingOptions *)options;
- (void)updateWithContentSize:(CGSize)contentSize
                       bounds:(CGRect)bounds
               safeAreaInsets:(UIEdgeInsets)safeAreaInsets;

@end

NS_ASSUME_NONNULL_END
