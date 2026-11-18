// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import <NEBaseUIKitOC/CopyableLabel.h>
#import <NEBaseUIKitOC/NEUserHeaderView.h>

@class V2NIMTeam;

NS_ASSUME_NONNULL_BEGIN

@interface TeamDetailHeaderView : UIView

@property (nonatomic, strong) NSMutableArray<NSLayoutConstraint *> *labelConstraints;
@property (nonatomic, strong) NEUserHeaderView *teamHeaderView;
@property (nonatomic, strong) CopyableLabel *teamNameLabel;
@property (nonatomic, strong) CopyableLabel *teamIdLabel;
@property (nonatomic, strong) CopyableLabel *teamOwnerLabel;
@property (nonatomic, strong, readonly) UIView *lineView;
@property (nonatomic, assign) CGFloat avatarWH;

- (instancetype)initWithAvatarWH:(CGFloat)avatarWH;
- (void)commonUI;
- (void)commonUIWithShowOwner:(BOOL)showOwner;
- (void)resetAvatarWH:(CGFloat)wh;
- (void)setCornerRadius:(CGFloat)cornerRadius;
- (void)setData:(nullable V2NIMTeam *)team showOwner:(BOOL)showOwner;
- (void)setData:(nullable V2NIMTeam *)team :(BOOL)showOwner;
- (void)getOwnerName:(nullable V2NIMTeam *)team completion:(void (^)(NSString *ownerName))completion;
- (void)getOwnerName:(nullable V2NIMTeam *)team :(void (^)(NSString *ownerName))completion;

@end

NS_ASSUME_NONNULL_END
