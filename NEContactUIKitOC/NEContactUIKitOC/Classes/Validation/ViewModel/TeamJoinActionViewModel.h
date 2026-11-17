// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <NIMSDK/NIMSDK.h>
#import "NETeamJoinAction.h"

@class TeamRepo;

NS_ASSUME_NONNULL_BEGIN

@protocol TeamJoinActionViewModelDelegate <NSObject>
- (void)tableviewReload;
@end

@interface TeamJoinActionViewModel : NSObject

@property (nonatomic, strong) TeamRepo *teamRepo;
@property (nonatomic, weak) id<TeamJoinActionViewModelDelegate> delegate;
@property (nonatomic, strong) NSMutableArray<NETeamJoinAction *> *teamJoinActions;

- (void)loadTeamJoinActionList:(BOOL)firstLoad completion:(void (^)(NSError *_Nullable))completion;
- (void)loadTeamJoinActionList:(BOOL)firstLoad :(void (^)(NSError *_Nullable))completion;
- (void)convertToNETeamJoinAction:(V2NIMTeamJoinActionInfo *)item
                              move:(BOOL)move
                        completion:(void (^)(NSError *_Nullable))completion;
- (void)convertToNETeamJoinAction:(V2NIMTeamJoinActionInfo *)item
                                  :(BOOL)move
                                  :(void (^)(NSError *_Nullable))completion;
- (void)setTeamJoinActionRead;
- (void)changeTeamJoinActionStatus:(V2NIMTeamJoinActionInfo *)action
                            status:(V2NIMTeamJoinActionStatus)status;
- (void)changeTeamJoinActionStatus:(V2NIMTeamJoinActionInfo *)action
                                  :(V2NIMTeamJoinActionStatus)status;
- (void)agreeRequest:(V2NIMTeamJoinActionInfo *)action
          completion:(void (^)(NSError *_Nullable))completion;
- (void)agreeRequestWithAction:(V2NIMTeamJoinActionInfo *)action
                              :(void (^)(NSError *_Nullable))completion;
- (void)refuseRequest:(V2NIMTeamJoinActionInfo *)action
           completion:(void (^)(NSError *_Nullable))completion;
- (void)refuseRequestWithAction:(V2NIMTeamJoinActionInfo *)action
                               :(void (^)(NSError *_Nullable))completion;
- (void)clearNotification:(void (^)(NSError *_Nullable))completion;

// NETeamListener
- (void)onReceive:(V2NIMTeamJoinActionInfo *)joinActionInfo;

@end

NS_ASSUME_NONNULL_END
