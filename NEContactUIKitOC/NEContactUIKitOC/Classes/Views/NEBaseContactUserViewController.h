// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import <NIMSDK/NIMSDK.h>
#import <NEChatKit/ContactRepo.h>
#import "NEContactBaseViewController.h"
#import "ContactUserViewModel.h"
#import "NEBaseUserInfoHeaderView.h"
#import "UserItem.h"

@class NEUserWithFriend;
@class NEBaseContactAliasViewController;

NS_ASSUME_NONNULL_BEGIN

/// 用户信息界面 - 基类
@interface NEBaseContactUserViewController : NEContactBaseViewController <UITableViewDelegate, UITableViewDataSource, NEContactListener>

@property (nonatomic, strong, nullable) NEUserWithFriend *user;
@property (nonatomic, copy, nullable) NSString *accountId;
@property (nonatomic, copy) NSString *className;

/// 是否为机器人账号
@property (nonatomic, assign) BOOL isRobot;

@property (nonatomic, strong) ContactUserViewModel *viewModel;
@property (nonatomic, strong) NSMutableArray<NSMutableArray<UserItem *> *> *data;
@property (nonatomic, strong) NEBaseUserInfoHeaderView *headerView;
@property (nonatomic, strong, nullable) NSLayoutConstraint *tableViewTopAnchor;
@property (nonatomic, strong) UITableView *tableView;

- (instancetype)initWithAccountId:(NSString *)accountId;
- (instancetype)initWithNimUser:(V2NIMUser *)nimUser;
- (instancetype)initWithNim_user:(V2NIMUser *)nimUser;
- (instancetype)initWithUser:(nullable NEUserWithFriend *)user;

- (void)commonUI;
- (void)loadData;
- (NSString *)chatActionTitle;

- (NEBaseContactAliasViewController *)getContactAliasViewController;
- (void)toEditRemarks;
- (void)allowNotify:(BOOL)allow;
- (void)allowNotifyWithAllow:(BOOL)allow;
- (void)blackList:(BOOL)isBlack completion:(void (^)(void))completion;
- (void)blackListWithIsBlack:(BOOL)isBlack completion:(void (^)(void))completion;
- (void)chat:(nullable NEUserWithFriend *)user;
- (void)chatWithUser:(nullable NEUserWithFriend *)user;
- (void)deleteFriendAction:(nullable NEUserWithFriend *)user;
- (void)deleteFriendActionWithUser:(nullable NEUserWithFriend *)user;
- (void)deleteFriend:(nullable NEUserWithFriend *)user;
- (void)deleteFriendWithUser:(nullable NEUserWithFriend *)user;
- (void)applyContactNameEmojiStyleToLabel:(UILabel *)label name:(nullable NSString *)name;
- (void)addFriend;

// NEContactListener
- (void)onContactChange:(NEContactChangeType)changeType
                contacts:(NSArray<NEUserWithFriend *> *)contacts;

@end

NS_ASSUME_NONNULL_END
