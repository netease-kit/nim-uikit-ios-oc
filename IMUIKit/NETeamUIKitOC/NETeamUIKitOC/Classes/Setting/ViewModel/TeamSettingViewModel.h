// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import "NEBaseTeamSettingCell.h"
#import <NEChatKit/ContactRepo.h>
#import <NEChatKit/ConversationRepo.h>
#import <NEChatKit/LocalConversationRepo.h>
#import <NEChatKit/TeamMemberInfoModel.h>
#import <NEChatKit/TeamRepo.h>
#import <NIMSDK/NIMSDK.h>

NS_ASSUME_NONNULL_BEGIN

@class HistoryMessageModel;
@class NETeamInfoModel;
@class SettingSectionModel;

@protocol TeamSettingViewModelDelegate <NSObject>
- (void)didClickChangeNick;
- (void)didClickHistoryMessage;
- (void)didNeedRefreshUI;
- (void)didError:(NSError *)error;
- (void)didClickMark;
- (void)didClickTeamManage;
- (void)didShowNoNetworkToast;
@end

@interface TeamSettingViewModel : NSObject <NETeamListener, NEConversationListener, NELocalConversationListener>

@property (nonatomic, strong) NSMutableArray<SettingSectionModel *> *sectionData;
@property (nonatomic, strong, nullable) NSArray<HistoryMessageModel *> *searchResultInfos;
@property (nonatomic, strong, nullable) NETeamInfoModel *teamInfoModel;
@property (nonatomic, strong) TeamRepo *teamRepo;
@property (nonatomic, strong) ContactRepo *contactRepo;
@property (nonatomic, strong, nullable) V2NIMTeamMember *memberInTeam;
@property (nonatomic, weak, nullable) id<TeamSettingViewModelDelegate> delegate;
@property (nonatomic, assign) TeamSettingType teamSettingType;
@property (nonatomic, strong, nullable) id<V2NIMBaseConversation> conversation;
@property (nonatomic, strong) ConversationRepo *conversationRepo;
@property (nonatomic, strong) LocalConversationRepo *localConversationRepo;
@property (nonatomic, assign) BOOL isRequestSettingData;
@property (nonatomic, strong) NSMutableDictionary<NSString *, V2NIMTeamMember *> *allMembersDic;

- (void)didTapHeader:(NSNotification *)notification;
- (void)clear;
- (void)getData;
- (SettingSectionModel *)getOneSection;
- (SettingSectionModel *)getTwoSection;
- (SettingSectionModel *)getThreeSection;
- (void)getTeamWithMembers:(NSString *)teamId completion:(void (^)(NSError * _Nullable error))completion;
- (void)getAllTeamMemberInfos:(NSString *)teamId
                    queryType:(V2NIMTeamMemberRoleQueryType)queryType
                   completion:(void (^)(NSError * _Nullable error))completion;
- (void)getTeamInfoWithSomeMembers:(NSString *)teamId
                        completion:(void (^)(NSError * _Nullable error, NSNumber * _Nullable finished))completion;
- (void)getUserInfo:(NSArray<V2NIMTeamMember *> *)members
         completion:(void (^)(NSError * _Nullable error, NSArray<NETeamMemberInfoModel *> * _Nullable models))completion;
- (void)dismissTeam:(NSString *)teamId completion:(void (^)(NSError * _Nullable error))completion;
- (void)leaveTeam:(NSString *)teamId completion:(void (^)(NSError * _Nullable error))completion;
- (void)removeStickTop:(void (^)(NSError * _Nullable error))completion;
- (void)getCurrentMember:(NSString *)userId
                  teamId:(nullable NSString *)teamId
              completion:(void (^)(V2NIMTeamMember * _Nullable member, NSError * _Nullable error))completion;
- (BOOL)isOwner;
- (BOOL)isManager;
- (nullable NSString *)sampleMemberId:(NSArray<NETeamMemberInfoModel *> *)arr owner:(NSString *)owner;
- (void)transferTeamOwner:(void (^)(NSError * _Nullable error))completion;
- (BOOL)isNormalTeam;
- (void)onTeamMemberChanged:(NSArray<V2NIMTeamMember *> *)members;
- (void)inviteUsers:(NSArray<NSString *> *)members
             teamId:(NSString *)teamId
         completion:(void (^)(NSError * _Nullable error, NSArray<V2NIMTeamMember *> * _Nullable members))completion;

@end

NS_ASSUME_NONNULL_END
