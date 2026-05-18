// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <NEChatKitOC/ContactRepo.h>
#import <NEChatKitOC/TeamRepo.h>

NS_ASSUME_NONNULL_BEGIN

@class NETeamMemberInfoModel;
@class NETeamInfoModel;

@protocol TeamManagerListViewModelDelegate <NSObject>
- (void)didNeedReloadData;
@end

@interface TeamManagerListViewModel : NSObject <NETeamListener, NEContactListener>

@property (nonatomic, strong) TeamRepo *teamRepo;
@property (nonatomic, strong, nullable) V2NIMTeamMember *currentMember;
@property (nonatomic, strong) NSMutableArray<NETeamMemberInfoModel *> *managers;
@property (nonatomic, weak, nullable) id<TeamManagerListViewModelDelegate> delegate;
@property (nonatomic, copy, nullable) NSString *teamId;
@property (nonatomic, assign) BOOL isRequest;

- (void)didTapHeader:(NSNotification *)noti;
- (void)getManagerDatas:(NSString *)teamId completion:(void (^)(NSError * _Nullable error))completion;
- (void)getCurrentUserTeamMember:(NSString *)teamId completion:(void (^)(NSError * _Nullable error))completion;
- (void)addTeamManager:(NSString *)teamId uids:(NSArray<NSString *> *)uids completion:(void (^)(NSError * _Nullable error))completion;
- (void)removeTeamManager:(NSString *)teamId uids:(NSArray<NSString *> *)uids completion:(void (^)(NSError * _Nullable error))completion;
- (void)getCurrentMember:(NSString *)teamId;
- (void)refreshData;
- (void)onTeamMemberChanged:(NSArray<V2NIMTeamMember *> *)members;
- (void)getTeamInfo:(NSString *)teamId completion:(void (^)(NETeamInfoModel * _Nullable model, NSError * _Nullable error))completion;
- (void)getTeamManagers:(NETeamInfoModel *)teamInfo
              queryType:(V2NIMTeamMemberRoleQueryType)queryType
             completion:(void (^)(NSError * _Nullable error, NETeamInfoModel * _Nullable teamInfo))completion;
- (void)splitTeamManagers:(NSArray<V2NIMTeamMember *> *)members
                    model:(NETeamInfoModel *)model
            maxSizeByPage:(NSInteger)maxSizeByPage
               completion:(void (^)(NSError * _Nullable error, NETeamInfoModel * _Nullable teamInfo))completion;
- (void)fetchManagersInfo:(NSMutableArray<NSArray<V2NIMTeamMember *> *> *)remainUserIds
                    model:(NETeamInfoModel *)model
               completion:(void (^)(NSError * _Nullable error, NETeamInfoModel * _Nullable teamInfo))completion;
- (void)getAllTeamManagerInfos:(NSString *)teamId
                     nextToken:(nullable NSString *)nextToken
                    memberList:(NSMutableArray<V2NIMTeamMember *> *)memberList
                     queryType:(V2NIMTeamMemberRoleQueryType)queryType
                    completion:(void (^)(NSArray<V2NIMTeamMember *> * _Nullable members, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
