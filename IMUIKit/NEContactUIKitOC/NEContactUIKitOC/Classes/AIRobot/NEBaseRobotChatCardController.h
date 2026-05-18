// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEContactBaseViewController.h"
#import <NIMSDK/NIMSDK.h>

NS_ASSUME_NONNULL_BEGIN

@class NEUserHeaderView;

@interface NEBaseRobotChatCardController : NEContactBaseViewController

@property(nonatomic, strong, readonly) V2NIMUserAIBot *bot;
@property(nonatomic, strong) NEUserHeaderView *avatarView;
@property(nonatomic, strong) UILabel *nameLabel;
@property(nonatomic, strong) UIButton *chatButton;

- (instancetype)initWithBot:(V2NIMUserAIBot *)bot;

- (void)setupCardUI;
- (void)configCard;

- (UIColor *)cardPageBackgroundColor;
- (CGFloat)cardHorizontalMargin;
- (CGFloat)avatarSize;
- (UIColor *)chatButtonColor;

- (void)didTapChatButton;

@end

NS_ASSUME_NONNULL_END
