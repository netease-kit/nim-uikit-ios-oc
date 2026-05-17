// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <NIMSDK/NIMSDK.h>

@class TeamRepo;
@class NETeam;

NS_ASSUME_NONNULL_BEGIN

@interface TeamListViewModel : NSObject

@property (nonatomic, strong) TeamRepo *teamRepo;
@property (nonatomic, copy) void (^refresh)(void);
@property (nonatomic, strong) NSMutableArray<NETeam *> *teamList;

- (void)getTeamList:(void (^)(NSArray<NETeam *> *_Nullable, NSError *_Nullable))completion;

// NETeamListener
- (void)onTeamAdded:(V2NIMTeam *)team;
- (void)onTeamUpdated:(V2NIMTeam *)team;
- (void)onTeamRemoved:(V2NIMTeam *)team;
- (void)onTeamCreated:(V2NIMTeam *)team;
- (void)onTeamJoined:(V2NIMTeam *)team;
- (void)onTeamInfoUpdated:(V2NIMTeam *)team;
- (void)onTeamLeft:(V2NIMTeam *)team isKicked:(BOOL)isKicked;
- (void)onTeamDismissed:(V2NIMTeam *)team;

@end

NS_ASSUME_NONNULL_END
