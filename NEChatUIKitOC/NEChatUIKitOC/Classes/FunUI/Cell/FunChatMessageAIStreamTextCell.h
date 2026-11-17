// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunChatMessageTextCell.h"
#import <NEBaseUIKitOC/NELottieAnimationView.h>

NS_ASSUME_NONNULL_BEGIN

@interface FunChatMessageAIStreamTextCell : FunChatMessageTextCell

@property (nonatomic, strong) NELottieAnimationView *loadingViewLeft;
@property (nonatomic, strong) UIButton *stopStreamButton;
@property (nonatomic, strong) UIButton *regenStreamButton;

- (void)stopStreamButtonAction;
- (void)regenStreamButtonAction;

@end

NS_ASSUME_NONNULL_END
