// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

@class NETeamMemberInfoModel;
@class NETeamMemberSearchResult;
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

@property (nonatomic, strong) NEUserHeaderView *headerView;
@property (nonatomic, strong) UILabel *ownerLabel;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UIStackView *nameStackView;
@property (nonatomic, strong) UILabel *removeLabel;
@property (nonatomic, strong) UIButton *removeButton;
@property (nonatomic, strong) NSLayoutConstraint *ownerRightMargin;
@property (nonatomic, assign) CGFloat ownerRightVisibleConstant;
@property (nonatomic, assign) CGFloat ownerRightHiddenConstant;

- (void)setupUI;
- (void)configure:(NETeamMemberInfoModel *)model;
- (void)configure:(NETeamMemberInfoModel *)model searchResult:(nullable NETeamMemberSearchResult *)searchResult;
- (void)setupRemoveButton;
- (void)setRemoveControlsVisible:(BOOL)visible;
- (void)didClickRemove;

@end

NS_ASSUME_NONNULL_END
