// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NEPagingBorderOptions : NSObject <NSCopying>

@property (nonatomic, assign, getter=isVisible) BOOL visible;
@property (nonatomic, assign) CGFloat height;
@property (nonatomic, assign) NSInteger zIndex;
@property (nonatomic, assign) UIEdgeInsets insets;

+ (instancetype)visibleWithHeight:(CGFloat)height
                           zIndex:(NSInteger)zIndex
                           insets:(UIEdgeInsets)insets;
+ (instancetype)hiddenOptions;

@end

NS_ASSUME_NONNULL_END
