// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "ChatUIConfig.h"
#import "ChatCellConstantValue.h"
#import "MessageContentModel.h"
#import "MessageTipsModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface NEBaseChatMessageTipCell : UITableViewCell

@property (nonatomic, strong, nullable) NSLayoutConstraint *timeLabelHeightAnchor;
@property (nonatomic, strong, nullable) NSLayoutConstraint *contentLabelCenterYAnchor;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UILabel *contentLabel;

- (void)commonUI;
- (void)setModel:(MessageTipsModel *)model;

@end

NS_ASSUME_NONNULL_END
