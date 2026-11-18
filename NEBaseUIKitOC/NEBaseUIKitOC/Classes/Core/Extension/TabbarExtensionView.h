// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UITabBar (TabbarExtensionView)

- (void)showBadgOnIndex:(NSInteger)itemIndex tabbarItemNums:(CGFloat)tabbarItemNums;
- (void)setRedDotViewWithIndex:(NSInteger)itemIndex;
- (void)hideRedDocViewWithIndex:(NSInteger)itemIndex;
- (void)hideBadgOnIndex:(NSInteger)itemIndex;
- (void)setServerBadge:(nullable NSString *)count;

@end

NS_ASSUME_NONNULL_END

