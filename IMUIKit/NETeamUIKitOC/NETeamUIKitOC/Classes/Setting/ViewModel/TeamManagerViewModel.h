// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <NEChatKitOC/ChatRepo.h>
#import <NEChatKitOC/TeamRepo.h>

NS_ASSUME_NONNULL_BEGIN

@class NETeamInfoModel;
@class SettingCellModel;
@class SettingSectionModel;

@protocol TeamManagerViewModelDelegate <NSObject>
- (void)didChangeInviteModeClick:(SettingCellModel *)model;
- (void)didUpdateTeamInfoClick:(SettingCellModel *)model;
- (void)didAtPermissionClick:(SettingCellModel *)model;
- (void)didTopMessagePermissionClick:(SettingCellModel *)model;
- (void)didJoinTeamNeedAgreeClick:(SettingCellModel *)model isOpen:(BOOL)isOpen;
- (void)didJoinTeamNeedVerificationClick:(SettingCellModel *)model isOpen:(BOOL)isOpen;
- (void)didManagerClick;
- (void)didRefreshData;
@end

@interface TeamManagerViewModel : NSObject <NETeamListener>

@property (nonatomic, strong) TeamRepo *teamRepo;
@property (nonatomic, strong) ChatRepo *chatRepo;
@property (nonatomic, strong, nullable) NETeamInfoModel *teamInfoModel;
@property (nonatomic, strong) NSMutableArray<SettingSectionModel *> *sectionData;
@property (nonatomic, strong) NSMutableArray<V2NIMTeamMember *> *managerUsers;
@property (nonatomic, assign) BOOL isRequestData;
@property (nonatomic, weak, nullable) id<TeamManagerViewModelDelegate> delegate;
@property (nonatomic, strong, nullable) V2NIMTeamMember *teamMember;

- (void)getSectionData;
- (void)getCurrentUserTeamMember:(NSString *)userId
                          teamId:(nullable NSString *)teamId
                      completion:(void (^)(V2NIMTeamMember * _Nullable member, NSError * _Nullable error))completion;
- (void)getTeamWithMembers:(NSString *)teamId completion:(void (^)(NSError * _Nullable error))completion;
- (SettingSectionModel *)getFirstSection;
- (SettingSectionModel *)getSecondSection;
- (SettingSectionModel *)getThirdSection;
- (void)updateTeamAtAllPermission:(BOOL)isManager completion:(void (^)(NSError * _Nullable error))completion;
- (NSString *)getTeamAtAllPermissionValue;
- (NSString *)getTeamTopMessagePermissionValue;
- (void)updateTeamTopMessagePermission:(BOOL)isManager completion:(void (^)(NSError * _Nullable error))completion;
- (void)updateTeamAgreeMode:(BOOL)isNeedAgree completion:(void (^)(NSError * _Nullable error))completion;
- (void)updateTeamJoinMode:(BOOL)isNeedAgree completion:(void (^)(NSError * _Nullable error))completion;
- (void)updateTeamInfoPrivilege:(NSString *)teamId
                           mode:(V2NIMTeamUpdateInfoMode)mode
                     completion:(void (^)(NSError * _Nullable error, V2NIMTeam * _Nullable team))completion;
- (void)updateInviteMode:(NSString *)teamId
                    mode:(V2NIMTeamInviteMode)mode
              completion:(void (^)(NSError * _Nullable error, V2NIMTeam * _Nullable team))completion;
- (void)updateTeamInfo:(NSString *)teamId;
- (void)onTeamMemberChanged:(NSArray<V2NIMTeamMember *> *)members;
- (void)getAllTeamManagers:(NSString *)teamId
                 nextToken:(nullable NSString *)nextToken
                memberList:(NSMutableArray<V2NIMTeamMember *> *)memberList
                 queryType:(V2NIMTeamMemberRoleQueryType)queryType
                completion:(void (^)(NSArray<V2NIMTeamMember *> * _Nullable members, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
