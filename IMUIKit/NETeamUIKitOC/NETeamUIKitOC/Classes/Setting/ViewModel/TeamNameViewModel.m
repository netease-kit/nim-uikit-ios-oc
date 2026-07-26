// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "TeamNameViewModel.h"
#import <NEChatKit/TeamRepo.h>
#import <NEChatKit/IMKitClient.h>

@interface TeamNameViewModel ()
@property (nonatomic, strong) TeamRepo *teamRepo;
@end

@implementation TeamNameViewModel

- (instancetype)init {
  self = [super init];
  if (self) {
    _teamRepo = [TeamRepo shared];
  }
  return self;
}

- (void)getCurrentUserTeamMember:(NSString *)teamId completion:(void (^)(NSError * _Nullable))completion {
  if (teamId.length == 0) {
    if (completion) {
      completion(nil);
    }
    return;
  }

  NSString *currentUserAccid = [IMKitClient instance].account;
  [self.teamRepo getTeamMember:teamId teamType:V2NIM_TEAM_TYPE_NORMAL accId:currentUserAccid completion:^(V2NIMTeamMember * _Nullable member, NSError * _Nullable error) {
    self.currentTeamMember = member;
    if (completion) {
      completion(error);
    }
  }];
}

@end
