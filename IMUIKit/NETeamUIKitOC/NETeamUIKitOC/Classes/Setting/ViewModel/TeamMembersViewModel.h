// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <NEChatKitOC/TeamRepo.h>
#import <NEChatUIKitOC/NETeamUserManager.h>

NS_ASSUME_NONNULL_BEGIN

@class NETeamInfoModel;
@class NETeamMemberInfoModel;

@protocol TeamMembersViewModelDelegate <NSObject>
- (void)didNeedRefreshUI;
@end

@interface TeamMembersViewModel : NSObject <NETeamListener, NETeamChatUserCacheListener, NESubscribeListener>

@property (nonatomic, assign) BOOL isRequest;
@property (nonatomic, copy, nullable) NSString *teamId;
@property (nonatomic, weak, nullable) id<TeamMembersViewModelDelegate> delegate;
@property (nonatomic, strong) NSMutableArray<NETeamMemberInfoModel *> *datas;
@property (nonatomic, strong) NSMutableArray<NETeamMemberInfoModel *> *searchDatas;
@property (nonatomic, strong) TeamRepo *teamRepo;
@property (nonatomic, strong, nullable) V2NIMTeamMember *currentMember;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *onLineEventDic;

- (void)didTapHeader:(NSNotification *)noti;
- (void)getMemberInfo:(NSString *)teamId completion:(void (^)(NSError * _Nullable error))completion;
- (void)removeTeamMember:(NSString *)teamId uids:(NSArray<NSString *> *)uids completion:(void (^)(NSError * _Nullable error))completion;
- (void)setShowDatas:(nullable NSArray<NETeamMemberInfoModel *> *)memberDatas;
- (void)removeModel:(NSArray<NSString *> *)rmUids;
- (void)removeSearchData:(NSArray<V2NIMTeamMember *> *)teamMembers;
- (void)changeMembers:(NSArray<V2NIMTeamMember *> *)teamMembers;
- (void)getTeamInfo:(NSString *)teamId completion:(void (^)(NETeamInfoModel * _Nullable model, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
