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
/// 提示文本宽度：跟随当前详情列的 viewport，未下发时回退全局最大宽度。
@property (nonatomic, strong, nullable) NSLayoutConstraint *contentWidthAnchor;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UILabel *contentLabel;

- (void)commonUI;
- (void)setModel:(MessageTipsModel *)model;

@end

NS_ASSUME_NONNULL_END
