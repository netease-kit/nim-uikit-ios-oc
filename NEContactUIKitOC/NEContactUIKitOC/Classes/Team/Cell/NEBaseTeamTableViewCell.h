// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import <NEBaseUIKitOC/NEBaseUIKitOC.h>

@class NETeam;

NS_ASSUME_NONNULL_BEGIN

@interface NEBaseTeamTableViewCell : UITableViewCell

/// 头像
@property (nonatomic, strong) NEUserHeaderView *userHeaderView;
/// 名称
@property (nonatomic, strong) UILabel *titleLabel;
/// 右侧图标
@property (nonatomic, strong) UIImageView *arrowImageView;

- (void)commonUI;
- (void)updateTitleLabelRightConstant:(CGFloat)constant;
- (void)updateUserHeaderViewSize:(CGFloat)size;
- (void)setModel:(id)model;

@end

NS_ASSUME_NONNULL_END
