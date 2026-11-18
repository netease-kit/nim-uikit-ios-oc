// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import <NIMSDK/NIMSDK.h>

NS_ASSUME_NONNULL_BEGIN

@class NEUserHeaderView;

@interface NEBaseAIRobotBindCell : UITableViewCell

@property(nonatomic, strong) NEUserHeaderView *avatarView;
@property(nonatomic, strong) UILabel *nameLabel;
@property(nonatomic, strong) UIImageView *arrowView;
@property(nonatomic, strong) UIView *separator;

- (void)setupCellUI;

- (CGFloat)avatarSize;
- (CGFloat)avatarCornerRadius;
- (CGFloat)nameFont;
- (CGFloat)arrowRightMargin;
- (UIColor *)separatorColor;

- (void)configureBot:(V2NIMUserAIBot *)bot isSelected:(BOOL)isSelected;
- (void)configureWithBot:(V2NIMUserAIBot *)bot isSelected:(BOOL)isSelected;

@end

NS_ASSUME_NONNULL_END
