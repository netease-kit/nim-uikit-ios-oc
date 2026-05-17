// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "JoinTeamViewModel.h"
#import "TeamConstant.h"
#import <NEChatKitOC/NEALog.h>
#import <NEChatKitOC/TeamRepo.h>

@interface JoinTeamViewModel ()
@property (nonatomic, strong) TeamRepo *teamRepo;
@end

@implementation JoinTeamViewModel

- (instancetype)init {
  self = [super init];
  if (self) {
    _teamRepo = [TeamRepo shared];
  }
  return self;
}

- (void)getTeamInfo:(NSString *)text completion:(void (^)(V2NIMTeam * _Nullable, NSError * _Nullable))completion {
  [NEALog infoLog:[NSString stringWithFormat:@"%@ %@", NETeamUIKitModuleName, @"JoinTeamViewModel"]
             desc:[NSString stringWithFormat:@"%@, text: %lu", NSStringFromSelector(_cmd), (unsigned long)text.length]];
  [self.teamRepo getTeamInfo:text teamType:V2NIM_TEAM_TYPE_NORMAL completion:completion];
}

@end
