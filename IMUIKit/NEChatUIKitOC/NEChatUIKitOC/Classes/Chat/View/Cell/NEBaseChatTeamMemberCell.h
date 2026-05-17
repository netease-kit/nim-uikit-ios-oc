// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import <NEChatKitOC/NEChatKitOC.h>
#import <NECommonUIKitOC/NECommonUIKitOC.h>
#import "ChatCellConstantValue.h"

NS_ASSUME_NONNULL_BEGIN

@interface NEBaseChatTeamMemberCell : UITableViewCell

@property (nonatomic, strong) NEUserHeaderView *headerView;
@property (nonatomic, strong) UILabel *nameLabel;

- (void)setupUI;
- (void)configure:(NETeamMemberInfoModel *)model;

@end

NS_ASSUME_NONNULL_END
