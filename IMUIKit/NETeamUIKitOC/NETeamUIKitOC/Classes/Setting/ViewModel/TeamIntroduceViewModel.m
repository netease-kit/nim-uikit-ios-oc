// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "TeamIntroduceViewModel.h"
#import <NEChatKitOC/TeamRepo.h>
#import <NEChatKitOC/IMKitClient.h>

@interface TeamIntroduceViewModel ()
@property (nonatomic, strong) TeamRepo *teamRepo;
@end

@implementation TeamIntroduceViewModel

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

- (void)updateTeamIntroduce:(NSString *)teamId introduce:(NSString *)introduce completion:(void (^)(NSError * _Nullable))completion {
  [self.teamRepo updateTeamIntroduce:teamId teamType:V2NIM_TEAM_TYPE_NORMAL introduce:introduce completion:^(NSError * _Nullable error) {
    if (completion) {
      completion(error);
    }
  }];
}

@end
