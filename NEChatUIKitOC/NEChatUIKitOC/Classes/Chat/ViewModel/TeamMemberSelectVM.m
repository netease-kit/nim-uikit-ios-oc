// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "TeamMemberSelectVM.h"
#import <NEChatKit/NEChatKit.h>
#import <NEChatKit/NEALog.h>
#import "NEChatUIConstant.h"
#import "NETeamUserManager.h"

@implementation TeamMemberSelectVM

- (instancetype)init {
  self = [super init];
  if (self) {
    _teamRepo = [TeamRepo shared];
  }
  return self;
}

- (void)getTeamMembers:(NSString *)teamId
            completion:(void (^)(NSError *_Nullable error, NETeamInfoModel *_Nullable model))completion {
  [self getTeamMembers:teamId progress:nil completion:completion];
}

- (void)getTeamMembers:(NSString *)teamId
               progress:(void (^)(NETeamMemberLoadProgress *progress))progress
             completion:(void (^)(NSError *_Nullable error, NETeamInfoModel *_Nullable model))completion {
  [NEALog infoLog:[NSString stringWithFormat:@"%@ TeamMemberSelectVM", ChatUIKitModuleName] desc:[NSString stringWithFormat:@"%s, teamId: %@", __FUNCTION__, teamId]];

  [[NETeamUserManager shared] refreshTeamInfoAndSelfMember:teamId completion:^{
    V2NIMTeam *team = [[NETeamUserManager shared] getTeamInfo];
    NSArray<NETeamMemberInfoModel *> *teamMembers = [[NETeamUserManager shared] getAllTeamMemberModels];

    if ([team.teamId isEqualToString:teamId] && teamMembers) {
      NETeamInfoModel *model = [[NETeamInfoModel alloc] init];
      model.team = team;
      model.users = [teamMembers mutableCopy] ?: [NSMutableArray array];
      if (completion) {
        completion(nil, model);
      }
    } else {
      [[NETeamUserManager shared] getAllTeamMembers:teamId
                                          queryType:V2NIM_TEAM_MEMBER_ROLE_QUERY_TYPE_ALL
                                           progress:progress
                                         completion:^(NSArray<NEUserWithFriend *> *members) {
        V2NIMTeam *fetchedTeam = [[NETeamUserManager shared] getTeamInfo];
        NSArray<NETeamMemberInfoModel *> *fetchedMembers = [[NETeamUserManager shared] getAllTeamMemberModels];
        if ([fetchedTeam.teamId isEqualToString:teamId] && fetchedMembers) {
          NETeamInfoModel *model = [[NETeamInfoModel alloc] init];
          model.team = fetchedTeam;
          model.users = [fetchedMembers mutableCopy] ?: [NSMutableArray array];
          if (completion) {
            completion(nil, model);
          }
        } else {
          if (completion) {
            completion(nil, nil);
          }
        }
      }];
    }
  }];
}

@end
