// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NEBaseValidationCell.h"
#import <NEBaseUIKitOC/NEBaseUIKitOC.h>

NS_ASSUME_NONNULL_BEGIN

@interface NEBaseSystemNotificationCell : NEBaseValidationCell

@property (nonatomic, strong) ExpandButton *rejectButton;
@property (nonatomic, strong) ExpandButton *agreeButton;
@property (nonatomic, strong) UIImageView *resultImage;
@property (nonatomic, strong) UILabel *resultLabel;
@property (nonatomic, weak, nullable) id<SystemNotificationCellDelegate> delegate;

- (void)rejectClick:(UIButton *)sender;
- (void)agreeClick:(UIButton *)sender;

@end

NS_ASSUME_NONNULL_END
