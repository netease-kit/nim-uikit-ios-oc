// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <NIMSDK/NIMSDK.h>
#import <NEChatKitOC/NEChatKitOC.h>
#import "UserSettingCellModel.h"

NS_ASSUME_NONNULL_BEGIN

@protocol UserSettingViewModelDelegate <NSObject>
- (void)didNeedRefreshUI;
- (void)didError:(NSError *)error;
- (void)didShowErrorMsg:(NSString *)msg;
- (void)didClickMark;
- (void)didClickHistory;
@end

/// 用户设置 ViewModel
@interface UserSettingViewModel : NSObject

@property (nonatomic, strong) NEUserWithFriend *userInfo;
@property (nonatomic, strong) NSMutableArray<UserSettingCellModel *> *cellDatas;
@property (nonatomic, weak, nullable) id<UserSettingViewModelDelegate> delegate;
@property (nonatomic, strong, nullable) id<V2NIMBaseConversation> conversation;

/// 获取单聊会话
- (void)getConversation:(NSString *)userId completion:(void (^)(NSError *_Nullable error))completion;

/// 获取用户设置UI显示数据模型
- (void)getUserSettingModel:(NSString *)userId completion:(void (^)(void))completion;

/// 拼装UI显示数据模型
- (void)getSectionDatas;

/// 设置圆角
- (void)setAudoType;

/// 设置Fun皮肤圆角
- (void)setFunType;

/// 用户信息变更
- (void)userInfoDidChange;

@end

NS_ASSUME_NONNULL_END
