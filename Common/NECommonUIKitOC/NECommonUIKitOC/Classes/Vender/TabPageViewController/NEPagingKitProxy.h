// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^NEPagingKitLayoutBlock)(void);
typedef void (^NEPagingKitAnimationCompletion)(BOOL finished);

@interface NEPagingKitConfig : NSObject

@property (class, nonatomic, strong) UIColor *focusColor;
@property (class, nonatomic, strong) UIColor *normalColor;
@property (class, nonatomic, strong) UIFont *menuTitleFont;

@end

@interface NEPagingKitProxy : NSObject

+ (void)catchLayoutCompletionWithLayout:(NEPagingKitLayoutBlock)layout
                             completion:(NEPagingKitAnimationCompletion)completion;
+ (void)performSystemAnimation:(dispatch_block_t)animations
                    completion:(nullable NEPagingKitAnimationCompletion)completion;

@end

NS_ASSUME_NONNULL_END
