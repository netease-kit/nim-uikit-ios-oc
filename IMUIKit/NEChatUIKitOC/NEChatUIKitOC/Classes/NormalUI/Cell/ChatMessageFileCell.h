// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NormalChatMessageBaseCell.h"
#import <NECommonUIKitOC/FileStateView.h>
#import "MessageFileModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface ChatMessageFileCell : NormalChatMessageBaseCell

@property (nonatomic, weak, nullable) MessageFileModel *weakModel;
@property (nonatomic, strong) UIImageView *imgViewLeft;
@property (nonatomic, strong) FileStateView *stateViewLeft;
@property (nonatomic, strong) UILabel *titleLabelLeft;
@property (nonatomic, strong) UILabel *sizeLabelLeft;
@property (nonatomic, strong) UIView *labelViewLeft;
@property (nonatomic, strong) UIView *backViewLeft;
@property (nonatomic, strong) UIImageView *imgViewRight;
@property (nonatomic, strong) FileStateView *stateViewRight;
@property (nonatomic, strong) UILabel *titleLabelRight;
@property (nonatomic, strong) UILabel *sizeLabelRight;
@property (nonatomic, strong) UIView *labelViewRight;
@property (nonatomic, strong) UIView *backViewRight;

@end

NS_ASSUME_NONNULL_END
