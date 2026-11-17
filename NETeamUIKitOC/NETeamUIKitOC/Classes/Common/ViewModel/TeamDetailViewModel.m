// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "TeamDetailViewModel.h"
#import "TeamConstant.h"
#import <NEChatKit/NEALog.h>
#import <NEChatKit/TeamRepo.h>

@interface TeamDetailViewModel () <NETeamListener>
@property (nonatomic, strong) TeamRepo *teamRepo;
@end

@implementation TeamDetailViewModel

- (instancetype)init {
  self = [super init];
  if (self) {
    _teamRepo = [TeamRepo shared];
    [_teamRepo addTeamListener:self];
  }
  return self;
}

- (void)dealloc {
  [self.teamRepo removeTeamListener:self];
}

- (void)applyJoinTeam:(NSString *)teamId completion:(void (^)(V2NIMTeam * _Nullable, NSError * _Nullable))completion {
  [NEALog infoLog:[NSString stringWithFormat:@"%@ %@", NETeamUIKitModuleName, @"ContactUserViewModel"]
             desc:[NSString stringWithFormat:@"%@, teamId: %@", NSStringFromSelector(_cmd), teamId ?: @""]];
  [self.teamRepo applyJoinTeam:teamId teamType:V2NIM_TEAM_TYPE_NORMAL postscript:nil completion:completion];
}

- (void)applyJoinTeam:(NSString *)teamId :(void (^)(V2NIMTeam * _Nullable, NSError * _Nullable))completion {
  [self applyJoinTeam:teamId completion:completion];
}

- (void)getTeamInfo:(NSString *)teamId completion:(void (^)(V2NIMTeam * _Nullable, NSError * _Nullable))completion {
  [NEALog infoLog:[NSString stringWithFormat:@"%@ %@", NETeamUIKitModuleName, @"ContactUserViewModel"]
             desc:[NSString stringWithFormat:@"%@, teamId: %@", NSStringFromSelector(_cmd), teamId ?: @""]];
  [self.teamRepo getTeamInfo:teamId teamType:V2NIM_TEAM_TYPE_NORMAL completion:completion];
}

- (void)getTeamInfo:(NSString *)teamId :(void (^)(V2NIMTeam * _Nullable, NSError * _Nullable))completion {
  [self getTeamInfo:teamId completion:completion];
}

- (void)onTeamJoined:(V2NIMTeam *)team {
  __weak typeof(self) weakSelf = self;
  dispatch_async(dispatch_get_main_queue(), ^{
    void (^teamJoined)(V2NIMTeam *) = weakSelf.teamJoined;
    if (teamJoined) {
      teamJoined(team);
    }
  });
}

@end
