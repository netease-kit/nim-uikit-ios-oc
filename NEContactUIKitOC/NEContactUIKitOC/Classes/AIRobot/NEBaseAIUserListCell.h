// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

@class NEAIUserModel;
@class NEUserHeaderView;

NS_ASSUME_NONNULL_BEGIN

@interface NEBaseAIUserListCell : UITableViewCell

@property(nonatomic, strong, nullable) NEAIUserModel *currentModel;
@property(nonatomic, strong) NEUserHeaderView *aiUserHeaderView;
@property(nonatomic, strong) UILabel *aiUserNameLabel;

- (void)setupAIUserListCellUI;
- (void)configure:(NEAIUserModel *)model;

@end

@interface AIUserListCell : NEBaseAIUserListCell
@end

@interface FunAIUserListCell : NEBaseAIUserListCell
@property(nonatomic, strong) UIView *dividerLine;
@end

NS_ASSUME_NONNULL_END
