// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "ConversationSearchViewModel.h"
#import <NEChatKitOC/ConversationSearchListModel.h>
#import <NEChatKitOC/NEFriendUserCache.h>
#import <NEChatKitOC/NECoreIM2Constant.h>
#import <NEChatKitOC/NIMExtension.h>

@implementation ConversationSearchViewModel

- (instancetype)init {
  self = [super init];
  if (self) {
    _teamDic = [[NSMutableDictionary alloc] init];
    _friendDic = [[NSMutableDictionary alloc] init];
    _friendDatas = [[NSMutableArray alloc] init];
    _discussionDatas = [[NSMutableArray alloc] init];
    _seniorDatas = [[NSMutableArray alloc] init];

    [[ContactRepo shared] addContactListener:self];
    [[TeamRepo shared] addTeamListener:self];
    [[IMKitClient instance] addLoginListener:self];
    [self getSearchData:NO completion:^{}];
  }
  return self;
}

- (void)dealloc {
  [[ContactRepo shared] removeContactListener:self];
  [[TeamRepo shared] removeTeamListener:self];
  [[IMKitClient instance] removeLoginListener:self];
}

- (void)doSearch:(NSString *)searchText completion:(dispatch_block_t)completion {
  [self.friendDatas removeAllObjects];
  [self.discussionDatas removeAllObjects];
  [self.seniorDatas removeAllObjects];

  if (searchText.length == 0) {
    if (completion) {
      completion();
    }
    return;
  }

  [self.friendDic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, ConversationSearchListModel * _Nonnull obj, BOOL * _Nonnull stop) {
    NEUserWithFriend *user = obj.userInfo;
    if (user == nil) {
      return;
    }
    NSString *showName = [user showName] ?: @"";
    NSString *accountId = user.user.accountId ?: @"";
    if ([showName containsString:searchText] || [accountId containsString:searchText]) {
      [self.friendDatas addObject:obj];
    }
  }];

  [self.teamDic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, ConversationSearchListModel * _Nonnull obj, BOOL * _Nonnull stop) {
    V2NIMTeam *team = obj.team;
    NSString *showName = [team ne_getShowName];
    if (showName.length == 0 || ![showName containsString:searchText]) {
      return;
    }
    if ([team.serverExtension containsString:discussTeamKey]) {
      [self.discussionDatas addObject:obj];
    } else {
      [self.seniorDatas addObject:obj];
    }
  }];

  [self.friendDatas sortUsingSelector:@selector(compare:)];
  [self.discussionDatas sortUsingSelector:@selector(compare:)];
  [self.seniorDatas sortUsingSelector:@selector(compare:)];

  if (completion) {
    completion();
  }
}

- (void)getSearchData:(BOOL)removeTeamData completion:(dispatch_block_t)completion {
  dispatch_group_t group = dispatch_group_create();
  dispatch_queue_t queue = dispatch_queue_create("com.netease.im.conversation.search.data", DISPATCH_QUEUE_SERIAL);

  dispatch_group_enter(group);
  dispatch_async(queue, ^{
    NSDictionary<NSString *, NEUserWithFriend *> *friends = [[NEFriendUserCache shared] getFriendListNotInBlocklist];
    [friends enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NEUserWithFriend * _Nonnull obj, BOOL * _Nonnull stop) {
      ConversationSearchListModel *model = [[ConversationSearchListModel alloc] init];
      model.userInfo = obj;
      self.friendDic[key] = model;
    }];
    dispatch_group_leave(group);
  });

  dispatch_group_enter(group);
  [[TeamRepo shared] getTeamList:^(NSArray<V2NIMTeam *> * _Nullable teams, NSError * _Nullable error) {
    if (removeTeamData && error == nil) {
      [self.teamDic removeAllObjects];
    }
    for (V2NIMTeam *team in teams) {
      if (team.teamId.length == 0) {
        continue;
      }
      ConversationSearchListModel *model = [[ConversationSearchListModel alloc] init];
      model.team = team;
      self.teamDic[team.teamId] = model;
    }
    dispatch_group_leave(group);
  }];

  dispatch_group_notify(group, dispatch_get_main_queue(), ^{
    if (completion) {
      completion();
    }
  });
}

- (void)addTeam:(V2NIMTeam *)team {
  if (team.teamId.length == 0) {
    return;
  }
  ConversationSearchListModel *model = [[ConversationSearchListModel alloc] init];
  model.team = team;
  self.teamDic[team.teamId] = model;
}

- (void)removeTeam:(V2NIMTeam *)team {
  if (team.teamId.length == 0) {
    return;
  }
  [self.teamDic removeObjectForKey:team.teamId];
}

#pragma mark - NETeamListener

- (void)onTeamInfoUpdated:(V2NIMTeam *)team {
  ConversationSearchListModel *model = self.teamDic[team.teamId];
  if (model != nil) {
    model.team = team;
  } else {
    [self addTeam:team];
  }
}

- (void)onTeamJoined:(V2NIMTeam *)team {
  [self addTeam:team];
}

- (void)onTeamCreated:(V2NIMTeam *)team {
  [self addTeam:team];
}

- (void)onTeamDismissed:(V2NIMTeam *)team {
  [self removeTeam:team];
}

- (void)onTeamLeft:(V2NIMTeam *)team isKicked:(BOOL)isKicked {
  [self removeTeam:team];
}

- (void)onTeamSyncFinished {
  [self getSearchData:YES completion:^{}];
}

#pragma mark - NEContactListener

- (void)onContactChange:(NEContactChangeType)changeType contacts:(NSArray<NEUserWithFriend *> *)contacts {
  if (changeType != NEContactChangeTypeUpdate) {
    return;
  }
  for (NEUserWithFriend *contact in contacts) {
    NSString *accountId = contact.user.accountId ?: @"";
    if (accountId.length == 0) {
      continue;
    }
    ConversationSearchListModel *model = [[ConversationSearchListModel alloc] init];
    model.userInfo = contact;
    self.friendDic[accountId] = model;
  }
}

#pragma mark - NEIMKitClientListener

- (void)onLoginStatus:(V2NIMLoginStatus)status {
  if (status == V2NIM_LOGIN_STATUS_LOGINED) {
    [self.friendDic removeAllObjects];
    [self.teamDic removeAllObjects];
    [self getSearchData:YES completion:^{}];
  }
}

@end
