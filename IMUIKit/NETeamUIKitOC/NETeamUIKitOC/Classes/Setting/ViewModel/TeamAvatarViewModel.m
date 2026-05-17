// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "TeamAvatarViewModel.h"
#import "TeamConstant.h"
#import <NEChatKitOC/NSObject+NECommon.h>
#import <NEChatKitOC/IMKitClient.h>
#import <NEChatKitOC/NEALog.h>
#import <NEChatKitOC/ResourceRepo.h>
#import <NEChatKitOC/TeamRepo.h>

@interface TeamAvatarViewModel ()
@property (nonatomic, strong) TeamRepo *teamRepo;
@end

@implementation TeamAvatarViewModel

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

- (void)updateTeamAvatar:(NSString *)url teamId:(NSString *)teamId antispamConfig:(V2NIMAntispamConfig *)antispamConfig completion:(void (^)(NSError * _Nullable))completion {
  (void)antispamConfig;
  [NEALog infoLog:[NSString stringWithFormat:@"%@ %@", NETeamUIKitModuleName, [self className]]
             desc:[NSString stringWithFormat:@"%@, url:%@", NSStringFromSelector(_cmd), url ?: @""]];
  [self.teamRepo updateTeamIcon:teamId teamType:V2NIM_TEAM_TYPE_NORMAL url:url completion:^(NSError * _Nullable error) {
    if (completion) {
      completion(error);
    }
  }];
}

- (V2NIMUploadFileTask *)createTask:(NSString *)filePath {
  return [self createTask:filePath sceneName:nil];
}

- (V2NIMUploadFileTask *)createTask:(NSString *)filePath sceneName:(NSString *)sceneName {
  return [[ResourceRepo shared] createUploadFileTask:filePath sceneName:sceneName];
}

- (void)uploadImageFile:(V2NIMUploadFileTask *)fileTask progress:(void (^)(float))progress completion:(void (^)(NSString * _Nullable, NSError * _Nullable))completion {
  [NEALog infoLog:[NSString stringWithFormat:@"%@ %@", NETeamUIKitModuleName, [self className]]
             desc:[NSString stringWithFormat:@"%@, taskId:%@", NSStringFromSelector(_cmd), fileTask.taskId ?: @""]];
  [[ResourceRepo shared] uploadFile:fileTask progress:progress completion:completion];
}

@end
