// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

@class NETeamMemberInfoModel;
@class NEUserHeaderView;

NS_ASSUME_NONNULL_BEGIN

@protocol TeamMemberCellDelegate <NSObject>
- (void)didClickRemoveButton:(nullable NETeamMemberInfoModel *)model index:(NSInteger)index;
@end

@interface NEBaseTeamMemberCell : UITableViewCell

@property (nonatomic, strong, nullable) NETeamMemberInfoModel *currentModel;
@property (nonatomic, weak, nullable) id<TeamMemberCellDelegate> delegate;
@property (nonatomic, strong, nullable) NSLayoutConstraint *ownerWidth;
@property (nonatomic, strong, nullable) NSLayoutConstraint *nameLabelRightMargin;
@property (nonatomic, assign) NSInteger index;

@property (nonatomic, strong, readonly) NEUserHeaderView *headerView;
@property (nonatomic, strong, readonly) UILabel *ownerLabel;
@property (nonatomic, strong, readonly) UILabel *nameLabel;
@property (nonatomic, strong, readonly) UILabel *removeLabel;
@property (nonatomic, strong, readonly) UIButton *removeButton;

- (void)setupUI;
- (void)configure:(NETeamMemberInfoModel *)model;
- (void)setupRemoveButton;
- (void)didClickRemove;

@end

NS_ASSUME_NONNULL_END
