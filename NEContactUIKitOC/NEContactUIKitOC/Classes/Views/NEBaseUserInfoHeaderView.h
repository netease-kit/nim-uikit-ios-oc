// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import <NEBaseUIKitOC/NEBaseUIKitOC.h>
#import <NEChatKit/NEChatKit.h>


@class NEUserWithFriend;

NS_ASSUME_NONNULL_BEGIN

@interface NEBaseUserInfoHeaderView : UIView

@property (nonatomic, strong) NSMutableArray<NSLayoutConstraint *> *labelConstraints;
@property (nonatomic, strong) NEUserHeaderView *userHeaderView;
@property (nonatomic, strong) CopyableLabel *titleLabel;
@property (nonatomic, strong) CopyableLabel *detailLabel;
@property (nonatomic, strong) CopyableLabel *detailLabel2;
@property (nonatomic, strong, readonly) UIView *lineView;

- (void)commonUI;
- (void)commonUIWithShowDetail:(BOOL)showDetail;
- (void)setData:(nullable NEUserWithFriend *)user;
- (void)setDataWithUser:(nullable NEUserWithFriend *)user;

@end

NS_ASSUME_NONNULL_END
