// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

@class NESelectTeamMember;
@class NEUserHeaderView;

NS_ASSUME_NONNULL_BEGIN

@interface NEBaseTeamMemberSelectCell : UITableViewCell

@property (nonatomic, strong, nullable) NESelectTeamMember *currentModel;
@property (nonatomic, strong) UIImageView *checkImageView;
@property (nonatomic, strong) NEUserHeaderView *headerView;
@property (nonatomic, strong) UILabel *nameLabel;

- (void)setupUI;
- (void)configureMember:(nullable NESelectTeamMember *)model;

@end

NS_ASSUME_NONNULL_END
