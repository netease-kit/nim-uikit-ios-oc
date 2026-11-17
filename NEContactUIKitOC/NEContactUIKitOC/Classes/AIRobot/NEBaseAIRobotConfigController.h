// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEContactBaseViewController.h"
#import <NIMSDK/NIMSDK.h>

NS_ASSUME_NONNULL_BEGIN

@interface NEBaseAIRobotConfigController : NEContactBaseViewController

@property(nonatomic, strong) V2NIMUserAIBot *bot;
@property(nonatomic, strong) UIView *cardView;
@property(nonatomic, strong) UILabel *titleLabel;
@property(nonatomic, strong) UIView *divider;
@property(nonatomic, strong) UILabel *configLabel;
@property(nonatomic, strong) UIButton *copyButton;
@property(nonatomic, strong) UILabel *warningLabel;

- (instancetype)initWithBot:(V2NIMUserAIBot *)bot;

- (void)setupConfigUI;

- (UIColor *)pageBackgroundColor;
- (CGFloat)cardTopMargin;
- (CGFloat)cardHorizontalMargin;
- (CGFloat)copyButtonHorizontalMargin;
- (CGFloat)copyButtonCornerRadius;
- (UIColor *)copyButtonColor;
- (void)setupCardCornerRadius;

- (void)didTapCopy;

@end

NS_ASSUME_NONNULL_END
