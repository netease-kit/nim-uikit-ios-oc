// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import <NEBaseUIKitOC/NEUserHeaderView.h>

@class NETeamMemberInfoModel;

NS_ASSUME_NONNULL_BEGIN

@interface NEBaseTeamUserCell : UICollectionViewCell

@property (nonatomic, strong, nullable) NETeamMemberInfoModel *user;
@property (nonatomic, strong) NEUserHeaderView *userHeaderView;

- (void)setupUI;

@end

NS_ASSUME_NONNULL_END
