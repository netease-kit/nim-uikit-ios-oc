// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "TeamDetailViewModel.h"
#import "TeamConstant.h"
#import <NEChatKitOC/NEALog.h>
#import <NEChatKitOC/TeamRepo.h>

@interface TeamDetailViewModel ()
@property (nonatomic, strong) TeamRepo *teamRepo;
@end

@implementation TeamDetailViewModel

- (instancetype)init {
  self = [super init];
  if (self) {
    _teamRepo = [TeamRepo shared];
  }
  return self;
}

- (void)applyJoinTeam:(NSString *)teamId completion:(void (^)(V2NIMTeam * _Nullable, NSError * _Nullable))completion {
  [NEALog infoLog:[NSString stringWithFormat:@"%@ %@", NETeamUIKitModuleName, @"ContactUserViewModel"]
             desc:[NSString stringWithFormat:@"%@, teamId: %@", NSStringFromSelector(_cmd), teamId ?: @""]];
  [self.teamRepo applyJoinTeam:teamId teamType:V2NIM_TEAM_TYPE_NORMAL postscript:nil completion:completion];
}

- (void)getTeamInfo:(NSString *)teamId completion:(void (^)(V2NIMTeam * _Nullable, NSError * _Nullable))completion {
  [NEALog infoLog:[NSString stringWithFormat:@"%@ %@", NETeamUIKitModuleName, @"ContactUserViewModel"]
             desc:[NSString stringWithFormat:@"%@, teamId: %@", NSStringFromSelector(_cmd), teamId ?: @""]];
  [self.teamRepo getTeamInfo:teamId teamType:V2NIM_TEAM_TYPE_NORMAL completion:completion];
}

@end
