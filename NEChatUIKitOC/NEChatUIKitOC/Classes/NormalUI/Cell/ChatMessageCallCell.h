// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NormalChatMessageBaseCell.h"
#import "MessageCallRecordModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface ChatMessageCallCell : NormalChatMessageBaseCell

@property (nonatomic, strong) UILabel *contentLabelLeft;
@property (nonatomic, strong) UILabel *contentLabelRight;

@end

NS_ASSUME_NONNULL_END
