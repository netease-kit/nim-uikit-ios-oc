// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBasePinMessageCell.h"
#import <NEBaseUIKitOC/NEBaseUIKitOC.h>
#import <NEBaseUIKitOC/LinkableLabelProtocol.h>

@class NELinkableLabel;

NS_ASSUME_NONNULL_BEGIN

@interface NEBasePinMessageTextCell : NEBasePinMessageCell <LinkableLabelProtocol>

@property (nonatomic, strong) NELinkableLabel *contentLabel;
@property (nonatomic, strong) UILabel *replyLabel;

- (void)commonUI;

@end

NS_ASSUME_NONNULL_END
