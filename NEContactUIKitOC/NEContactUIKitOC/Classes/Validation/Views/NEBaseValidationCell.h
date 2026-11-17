// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NEBaseContactViewCell.h"
#import "NEAddApplication.h"
#import "NETeamJoinAction.h"

NS_ASSUME_NONNULL_BEGIN

@protocol SystemNotificationCellDelegate <NSObject>
@optional
- (void)onAcceptWithApplication:(NEAddApplication *)application;
- (void)onRefuseWithApplication:(NEAddApplication *)application;
- (void)onAcceptWithAction:(NETeamJoinAction *)action;
- (void)onRefuseWithAction:(NETeamJoinAction *)action;
@end

@interface NEBaseValidationCell : NEBaseContactViewCell

@property (nonatomic, strong, nullable) NSLayoutConstraint *titleLabelRightMargin;
@property (nonatomic, strong) UIView *line;

- (void)setupUI;
- (void)configeWithApplication:(NEAddApplication *)application;
- (void)configeWithTeamJoinAction:(NETeamJoinAction *)teamJoinAction;

@end

NS_ASSUME_NONNULL_END
