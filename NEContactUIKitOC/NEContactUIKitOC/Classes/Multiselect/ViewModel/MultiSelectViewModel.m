// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "MultiSelectViewModel.h"
#import "ContactConst.h"

#import <NIMSDK/NIMSDK.h>
#import <NEChatKit/ConversationRepo.h>
#import <NEChatKit/LocalConversationRepo.h>
#import <NEChatKit/TeamRepo.h>
#import <NEChatKit/SettingRepo.h>
#import <NEChatKit/NEChatKit.h>
#import <NEChatKit/NEAIRobotManager.h>

@interface MultiSelectViewModel ()

@property (nonatomic, assign) NSInteger conversationLimit;
@property (nonatomic, strong) NSMutableArray<MultiSelectModel *> *conversationList;
@property (nonatomic, strong) NSMutableArray<MultiSelectModel *> *contactList;
@property (nonatomic, strong) NSMutableArray<MultiSelectModel *> *teamList;

@end

@implementation MultiSelectViewModel

- (instancetype)init {
  self = [super initWithContactHeaders:nil];
  if (self) {
    _conversationRepo = [ConversationRepo shared];
    _localConversationRepo = [LocalConversationRepo shared];
    _teamRepo = [TeamRepo shared];
    _settingRepo = [SettingRepo shared];
    _conversationLimit = 100;
    _conversationList = [NSMutableArray array];
    _contactList = [NSMutableArray array];
    _teamList = [NSMutableArray array];
    _sessions = [NSMutableArray array];
  }
  return self;
}

- (void)loadAllData:(nullable NSSet<NSString *> *)filters
         completion:(void (^)(NSError *_Nullable))completion {
  __weak typeof(self) weakSelf = self;
  [[NEAIRobotManager shared] loadAll:^(NSError *_Nullable loadError) {
    (void)loadError;
    // 加载群聊
    [weakSelf loadDataAtIndex:2 filters:filters completion:^(NSError *_Nullable error) {
      if (error) {
        [weakSelf.sessions removeAllObjects];
        completion(error);
        return;
      }
      // 加载好友
      [weakSelf loadDataAtIndex:1 filters:filters completion:^(NSError *_Nullable error) {
        if (error) {
          [weakSelf.sessions removeAllObjects];
          completion(error);
          return;
        }
        // 加载最近会话
        [weakSelf loadDataAtIndex:0 filters:filters completion:completion];
      }];
    }];
  }];
}

- (void)loadAllData:(nullable NSSet<NSString *> *)filters
                   :(void (^)(NSError *_Nullable))completion {
  [self loadAllData:filters completion:completion];
}

- (void)loadDataAtIndex:(NSInteger)index
                filters:(nullable NSSet<NSString *> *)filters
             completion:(void (^)(NSError *_Nullable))completion {
  [self.sessions removeAllObjects];
  if (index == 0) {
    if (self.conversationList.count == 0) {
      __weak typeof(self) weakSelf = self;
      [self getConversationList:filters completion:^(NSError *_Nullable error) {
        for (MultiSelectModel *model in weakSelf.conversationList) {
          if (![weakSelf isRobotConversation:model.conversationId]) {
            [weakSelf.sessions addObject:model];
          }
        }
        completion(error);
      }];
    } else {
      for (MultiSelectModel *model in self.conversationList) {
        if (![self isRobotConversation:model.conversationId]) {
          [self.sessions addObject:model];
        }
      }
      completion(nil);
    }
  } else if (index == 1) {
    if (self.contactList.count == 0) {
      __weak typeof(self) weakSelf = self;
      [self getContactListForMultiSelect:filters completion:^(NSError *_Nullable error) {
        for (MultiSelectModel *model in weakSelf.contactList) {
          if (![weakSelf isRobotConversation:model.conversationId]) {
            [weakSelf.sessions addObject:model];
          }
        }
        completion(error);
      }];
    } else {
      for (MultiSelectModel *model in self.contactList) {
        if (![self isRobotConversation:model.conversationId]) {
          [self.sessions addObject:model];
        }
      }
      completion(nil);
    }
  } else if (index == 2) {
    if (self.teamList.count == 0) {
      __weak typeof(self) weakSelf = self;
      [self getTeamList:filters completion:^(NSError *_Nullable error) {
        [weakSelf.sessions addObjectsFromArray:weakSelf.teamList];
        completion(error);
      }];
    } else {
      [self.sessions addObjectsFromArray:self.teamList];
      completion(nil);
    }
  }
}

- (void)loadData:(NSInteger)index
               :(nullable NSSet<NSString *> *)filters
               :(void (^)(NSError *_Nullable))completion {
  [self loadDataAtIndex:index filters:filters completion:completion];
}

- (NSArray<MultiSelectModel *> *)loadRecentForward {
  NSMutableArray<MultiSelectModel *> *recentSessions = [NSMutableArray array];
  NSMutableArray<NSString *> *recentList = [[self.settingRepo getRecentForward] mutableCopy] ?: [NSMutableArray array];

  NSMutableArray<NSString *> *invalidRobotIds = [NSMutableArray array];
  for (NSString *conversationId in recentList) {
    if ([self isRobotConversation:conversationId]) {
      [invalidRobotIds addObject:conversationId];
    }
  }
  if (invalidRobotIds.count > 0) {
    [recentList removeObjectsInArray:invalidRobotIds];
    [self.settingRepo updateRecentForward:recentList];
  }

  for (NSString *recent in [recentList copy]) {
    MultiSelectModel *found = nil;
    for (MultiSelectModel *session in self.conversationList) {
      if ([session.conversationId isEqualToString:recent]) { found = session; break; }
    }
    if (!found) {
      for (MultiSelectModel *session in self.contactList) {
        if ([session.conversationId isEqualToString:recent]) { found = session; break; }
      }
    }
    if (!found) {
      for (MultiSelectModel *session in self.teamList) {
        if ([session.conversationId isEqualToString:recent]) { found = session; break; }
      }
    }
    if (found) {
      if (![self isRobotConversation:found.conversationId]) {
        [recentSessions addObject:found];
      }
    } else {
      [recentList removeObject:recent];
      [self.settingRepo updateRecentForward:recentList];
    }
  }
  return recentSessions;
}

- (void)getConversationList:(nullable NSSet<NSString *> *)filters
                 completion:(void (^)(NSError *_Nullable))completion {
  __weak typeof(self) weakSelf = self;

  void (^processConversations)(NSArray *, NSError *) = ^(NSArray *conversations, NSError *error) {
    if (error) {
      NSLog(@"ContactKit log");
    } else if (conversations) {
      NSMutableArray *filtered = [conversations mutableCopy];
      if (filters) {
        NSMutableArray *toRemove = [NSMutableArray array];
        for (id conv in filtered) {
          NSString *convId = [conv performSelector:@selector(conversationId)];
          if ([filters containsObject:convId]) [toRemove addObject:conv];
        }
        [filtered removeObjectsInArray:toRemove];
      }
      NSMutableArray *robotConversations = [NSMutableArray array];
      for (id conv in filtered) {
        NSString *convId = [conv performSelector:@selector(conversationId)];
        if ([weakSelf isRobotConversation:convId]) {
          [robotConversations addObject:conv];
        }
      }
      [filtered removeObjectsInArray:robotConversations];
      for (id conversation in filtered) {
        NSString *convId = [conversation performSelector:@selector(conversationId)];
        MultiSelectModel *friendModel = [weakSelf findFriend:convId];
        if (friendModel) { [weakSelf.conversationList addObject:friendModel]; continue; }
        MultiSelectModel *teamModel = [weakSelf findTeam:convId];
        if (teamModel) { [weakSelf.conversationList addObject:teamModel]; continue; }
        MultiSelectModel *model = [[MultiSelectModel alloc] init];
        model.conversationId = convId;
        model.name = [conversation performSelector:@selector(name)];
        model.avatar = [conversation performSelector:@selector(avatar)];
        [weakSelf.conversationList addObject:model];
      }
    }
    completion(error);
  };

  if ([[NIMSDK sharedSDK].v2Option enableV2CloudConversation] == NO) {
    [self.localConversationRepo getConversationList:0 limit:self.conversationLimit completion:^(NSArray<V2NIMLocalConversation *> *_Nullable list, NSNumber *_Nullable offset, NSNumber *_Nullable finished, NSError *_Nullable error) {
      processConversations(list, error);
    }];
    return;
  }

  [self.conversationRepo getConversationList:0 limit:self.conversationLimit completion:^(NSArray<V2NIMConversation *> *_Nullable list, NSNumber *_Nullable offset, NSNumber *_Nullable finished, NSError *_Nullable error) {
    processConversations(list, error);
  }];
}

- (void)getConversationList:(nullable NSSet<NSString *> *)filters
                            :(void (^)(NSError *_Nullable))completion {
  [self getConversationList:filters completion:completion];
}

- (void)getContactListForMultiSelect:(nullable NSSet<NSString *> *)filters
                          completion:(void (^)(NSError *_Nullable))completion {
  NSLog(@"ContactKit log");

  __weak typeof(self) weakSelf = self;
  [self getContactList:filters completion:^(NSArray<ContactSection *> *_Nullable result, NSError *_Nullable error) {
    for (ContactSection *item in result ?: @[]) {
      for (ContactInfo *contact in item.contacts) {
        NSString *conversationId = [V2NIMConversationIdUtil p2pConversationId:contact.user.user.accountId ?: @""];
        MultiSelectModel *model = [[MultiSelectModel alloc] init];
        model.conversationId = conversationId;
        model.avatar = contact.user.user.avatar;
        model.avatarName = contact.user.user.name ?: contact.user.user.accountId;
        model.name = [contact.user showName] ?: @"";
        if (![weakSelf isRobotConversation:conversationId]) {
          [weakSelf.contactList addObject:model];
        }
      }
    }
    completion(error);
  }];
}

- (void)getContactList:(nullable NSSet<NSString *> *)filters
                       :(void (^)(NSError *_Nullable))completion {
  [self getContactListForMultiSelect:filters completion:completion];
}

- (void)getTeamList:(nullable NSSet<NSString *> *)filters
         completion:(void (^)(NSError *_Nullable))completion {
  __weak typeof(self) weakSelf = self;
  [self.teamRepo getTeamList:^(NSArray<V2NIMTeam *> *_Nullable teams, NSError *_Nullable error) {
    if (error) {
      NSLog(@"ContactKit log");
    } else if (teams) {
      NSMutableArray<V2NIMTeam *> *filteredTeams = [teams mutableCopy];
      if (filters) {
        NSMutableArray *toRemove = [NSMutableArray array];
        for (V2NIMTeam *t in filteredTeams) {
          if ([filters containsObject:t.teamId ?: @""]) [toRemove addObject:t];
        }
        [filteredTeams removeObjectsInArray:toRemove];
      }
      [filteredTeams sortUsingComparator:^NSComparisonResult(V2NIMTeam *t1, V2NIMTeam *t2) {
        if (t1.createTime > t2.createTime) return NSOrderedAscending;
        if (t1.createTime < t2.createTime) return NSOrderedDescending;
        return NSOrderedSame;
      }];
      for (V2NIMTeam *team in filteredTeams) {
        NSString *conversationId = [V2NIMConversationIdUtil teamConversationId:team.teamId ?: @""];
        MultiSelectModel *model = [[MultiSelectModel alloc] init];
        model.conversationId = conversationId;
        model.name = team.name;
        model.avatar = team.avatar;
        model.memberCount = team.memberCount;
        [weakSelf.teamList addObject:model];
      }
      completion(nil);
    }
  }];
}

- (void)getTeamList:(nullable NSSet<NSString *> *)filters
                    :(void (^)(NSError *_Nullable))completion {
  [self getTeamList:filters completion:completion];
}

- (nullable MultiSelectModel *)findFriend:(nullable NSString *)conversationId {
  for (MultiSelectModel *conv in self.contactList) {
    if ([conv.conversationId isEqualToString:conversationId]) {
      return conv;
    }
  }
  return nil;
}

- (nullable MultiSelectModel *)findTeam:(nullable NSString *)conversationId {
  for (MultiSelectModel *conv in self.teamList) {
    if ([conv.conversationId isEqualToString:conversationId]) {
      return conv;
    }
  }
  return nil;
}

- (BOOL)isRobotConversation:(nullable NSString *)conversationId {
  if (conversationId.length == 0) {
    return NO;
  }
  NSString *accountId = [V2NIMConversationIdUtil conversationTargetId:conversationId];
  return accountId.length > 0 && [[NEAIRobotManager shared] isRobot:accountId];
}

- (void)searchText:(NSString *)text {
  if (text.length == 0) {
    return;
  }
  NSMutableArray<MultiSelectModel *> *filtered = [NSMutableArray array];
  for (MultiSelectModel *model in self.sessions) {
    if (model.name && [model.name containsString:text]) {
      [filtered addObject:model];
    }
  }
  self.sessions = filtered;
}

@end
