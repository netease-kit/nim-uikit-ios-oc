// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NormalChatMessageBaseCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface ChatMessageRevokeCell : NormalChatMessageBaseCell

@property (nonatomic, strong) UILabel *revokeLabelLeft;
@property (nonatomic, strong) UILabel *revokeLabelRight;
@property (nonatomic, strong) UIButton *reeditButton;
@property (nonatomic, strong, nullable) NSLayoutConstraint *reeditButtonW;

- (void)reeditEvent:(UIButton *)button;

@end

NS_ASSUME_NONNULL_END
