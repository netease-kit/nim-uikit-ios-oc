// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "MultiSelectViewModel.h"
#import "ContactConst.h"
#import <NEChatKitOC/NECoreIM2KitOC.h>
#import <NIMSDK/NIMSDK.h>
#import <NEChatKitOC/ConversationRepo.h>
#import <NEChatKitOC/LocalConversationRepo.h>
#import <NEChatKitOC/TeamRepo.h>
#import <NEChatKitOC/SettingRepo.h>

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
  // 加载群聊
  [self loadDataAtIndex:2 filters:filters completion:^(NSError *_Nullable error) {
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
}

- (void)loadDataAtIndex:(NSInteger)index
                filters:(nullable NSSet<NSString *> *)filters
             completion:(void (^)(NSError *_Nullable))completion {
  [self.sessions removeAllObjects];
  if (index == 0) {
    if (self.conversationList.count == 0) {
      __weak typeof(self) weakSelf = self;
      [self getConversationList:filters completion:^(NSError *_Nullable error) {
        [weakSelf.sessions addObjectsFromArray:weakSelf.conversationList];
        completion(error);
      }];
    } else {
      [self.sessions addObjectsFromArray:self.conversationList];
      completion(nil);
    }
  } else if (index == 1) {
    if (self.contactList.count == 0) {
      __weak typeof(self) weakSelf = self;
      [self getContactListForMultiSelect:filters completion:^(NSError *_Nullable error) {
        [weakSelf.sessions addObjectsFromArray:weakSelf.contactList];
        completion(error);
      }];
    } else {
      [self.sessions addObjectsFromArray:self.contactList];
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

- (NSArray<MultiSelectModel *> *)loadRecentForward {
  NSMutableArray<MultiSelectModel *> *recentSessions = [NSMutableArray array];
  NSMutableArray<NSString *> *recentList = [[self.settingRepo getRecentForward] mutableCopy] ?: [NSMutableArray array];

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
      [recentSessions addObject:found];
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
        model.name = [contact.user showName] ?: @"";
        [weakSelf.contactList addObject:model];
      }
    }
    completion(error);
  }];
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
