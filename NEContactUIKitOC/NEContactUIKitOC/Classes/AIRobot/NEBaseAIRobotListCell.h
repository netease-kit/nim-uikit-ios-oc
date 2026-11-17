// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

@class NEAIRobotModel;
@class NEUserHeaderView;

NS_ASSUME_NONNULL_BEGIN

@interface NEBaseAIRobotListCell : UITableViewCell

@property(nonatomic, strong, nullable) NEAIRobotModel *currentModel;
@property(nonatomic, strong) NEUserHeaderView *robotHeaderView;
@property(nonatomic, strong) UILabel *robotNameLabel;
@property(nonatomic, strong) UIImageView *arrowView;

- (CGFloat)avatarSize;
- (CGFloat)avatarCornerRadius;
- (CGFloat)avatarLeading;
- (CGFloat)avatarNameSpacing;
- (CGFloat)nameFont;
- (BOOL)showArrow;
- (CGFloat)arrowRightMargin;
- (CGFloat)nameRightMargin;

- (void)setupRobotListCellUI;
- (void)configure:(NEAIRobotModel *)model;

@end

NS_ASSUME_NONNULL_END
