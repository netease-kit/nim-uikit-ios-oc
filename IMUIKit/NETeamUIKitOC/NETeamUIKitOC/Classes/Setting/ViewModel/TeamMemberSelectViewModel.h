// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <NEChatKitOC/TeamRepo.h>
#import <NEChatUIKitOC/NETeamUserManager.h>

NS_ASSUME_NONNULL_BEGIN

@class NESelectTeamMember;
@class NETeamInfoModel;
@class NETeamMemberInfoModel;

@protocol TeamMemberSelectViewModelDelegate <NSObject>
- (void)didNeedRefresh;
@end

@interface TeamMemberSelectViewModel : NSObject <NETeamListener, NETeamChatUserCacheListener>

@property (nonatomic, strong) TeamRepo *teamRepo;
@property (nonatomic, strong) NSMutableArray<NESelectTeamMember *> *datas;
@property (nonatomic, strong) NSMutableArray<NESelectTeamMember *> *showDatas;
@property (nonatomic, strong, nullable) NETeamInfoModel *teamInfoModel;
@property (nonatomic, weak, nullable) id<TeamMemberSelectViewModelDelegate> delegate;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NETeamMemberInfoModel *> *selectDic;
@property (nonatomic, assign) BOOL isRequest;
@property (nonatomic, assign) BOOL showAllMembers;
@property (nonatomic, strong) NSMutableSet<NSString *> *managerSet;

- (void)didTapHeader:(NSNotification *)noti;
- (void)getTeamInfo:(NSString *)teamId
     showAllMembers:(BOOL)showAllMembers
         completion:(void (^)(NSError * _Nullable error))completion;
- (void)getData:(BOOL)showAllMembers;
- (void)onTeamMemberUpdate:(NSString *)accountId;
- (NSArray<NESelectTeamMember *> *)searchAllData:(NSString *)searchText;
- (NSArray<NESelectTeamMember *> *)searchShowData:(NSString *)searchText;
- (BOOL)findContainStr:(NSString *)text selectModel:(NESelectTeamMember *)selectModel;
- (void)getTeamMembers:(NETeamInfoModel *)teamInfo
             queryType:(V2NIMTeamMemberRoleQueryType)queryType
            completion:(void (^)(NSError * _Nullable error, NETeamInfoModel * _Nullable model))completion;
- (void)splitSelectMembers:(NSArray<V2NIMTeamMember *> *)members
                     model:(NETeamInfoModel *)model
             maxSizeByPage:(NSInteger)maxSizeByPage
                completion:(void (^)(NSError * _Nullable error, NETeamInfoModel * _Nullable model))completion;
- (void)fetchSelectUsersInfo:(NSMutableArray<NSArray<V2NIMTeamMember *> *> *)remainUserIds
                       model:(NETeamInfoModel *)model
                  completion:(void (^)(NSError * _Nullable error, NETeamInfoModel * _Nullable model))completion;
- (void)getSelectMemberInfos:(NSString *)teamId
                   nextToken:(nullable NSString *)nextToken
                  memberList:(NSMutableArray<V2NIMTeamMember *> *)memberList
                   queryType:(V2NIMTeamMemberRoleQueryType)queryType
                  completion:(void (^)(NSArray<V2NIMTeamMember *> * _Nullable members, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
