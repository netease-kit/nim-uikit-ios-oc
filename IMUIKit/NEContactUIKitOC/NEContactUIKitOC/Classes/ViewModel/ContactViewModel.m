// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "ContactViewModel.h"
#import "ContactConst.h"
#import <NEChatKitOC/NECoreIM2KitOC.h>
#import <NEChatKitOC/ContactRepo.h>
#import <NEChatKitOC/TeamRepo.h>
#import <NEChatKitOC/NEFriendUserCache.h>
#import <NEChatKitOC/IMKitConfigCenter.h>
#import <NEChatKitOC/SubscribeRepo.h>
#import <NEChatKitOC/NESubscribeManager.h>
#import "NETeamJoinAction.h"
#import <NEChatKitOC/NSString+NECoreKit.h>

@interface ContactViewModel () <NEContactListener, NETeamListener, NESubscribeListener>

@property (nonatomic, strong, nullable) ContactSection *contactHeadersSection;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray<ContactInfo *> *> *initalDict;

@end

@implementation ContactViewModel

- (instancetype)initWithContactHeaders:(nullable NSArray<ContactHeadItem *> *)contactHeaders {
  self = [super init];
  if (self) {
    _contactSections = [NSMutableArray array];
    _initalDict = [NSMutableDictionary dictionary];
    _onlineStatusDic = [NSMutableDictionary dictionary];
    _contactRepo = [ContactRepo shared];

    // log removed


    ContactSection *headSection = [self headerSection:contactHeaders];
    if (headSection) {
      _contactHeadersSection = headSection;
      [_contactSections addObject:headSection];
    }

    [_contactRepo addContactListener:self];
    [[TeamRepo shared] addTeamListener:self];

    if ([IMKitConfigCenter shared].enableOnlineStatus) {
      [[SubscribeRepo shared] addListener:self];
    }
  }
  return self;
}

- (void)dealloc {
  [_contactRepo removeContactListener:self];
  [[TeamRepo shared] removeTeamListener:self];

  if ([IMKitConfigCenter shared].enableOnlineStatus) {
    [[SubscribeRepo shared] removeListener:self];
  }
}

- (void)setUnreadCount:(NSInteger)unreadCount {
  _unreadCount = unreadCount;
  if (self.refresh) {
    dispatch_async(dispatch_get_main_queue(), ^{
      self.refresh();
    });
  }
}

#pragma mark - Data

- (void)loadData:(nullable NSSet<NSString *> *)filters
      completion:(void (^)(NSError *_Nullable, NSInteger))completion {
  // log removed

  __weak typeof(self) weakSelf = self;
  [self getContactList:filters completion:^(NSArray<ContactSection *> *_Nullable contacts, NSError *_Nullable error) {
    if (contacts) {
      [weakSelf.contactSections removeAllObjects];
      if (weakSelf.contactHeadersSection) {
        [weakSelf.contactSections addObject:weakSelf.contactHeadersSection];
      }
      [weakSelf.contactSections addObjectsFromArray:contacts];
      weakSelf.indexs = [self getIndexs:contacts];
      completion(nil, (NSInteger)contacts.count);
      if ([IMKitConfigCenter shared].enableOnlineStatus) {
        [weakSelf subscribeOnlineStatus];
      }
    } else {
      completion(error, 0);
    }
  }];
}

- (void)getContactList:(nullable NSSet<NSString *> *)filters
            completion:(void (^)(NSArray<ContactSection *> *_Nullable, NSError *_Nullable))completion {
  // log removed


  // 优先从缓存中取
  if (![[NEFriendUserCache shared] isEmpty]) {
    NSDictionary<NSString *, NEUserWithFriend *> *friendDict = [[NEFriendUserCache shared] getFriendListNotInBlocklist];
    NSArray<NEUserWithFriend *> *friends = friendDict.allValues;
    NSArray<ContactSection *> *contactList = [self formatData:friends filters:filters];
    completion(contactList, nil);
    return;
  }

  // 缓存中没有则远端查询
  [self.contactRepo getContactList:^(NSArray<NEUserWithFriend *> *_Nullable friends, NSError *_Nullable error) {
    (void)friends;
    (void)error;
  }];
}

- (NSArray<ContactSection *> *)formatData:(nullable NSArray<NEUserWithFriend *> *)friends
                                  filters:(nullable NSSet<NSString *> *)filters {
  NSMutableArray<ContactSection *> *contactList = [NSMutableArray array];
  if (!friends) {
    return contactList;
  }

  NSMutableArray<NEUserWithFriend *> *users = [friends mutableCopy];
  self.initalDict = [NSMutableDictionary dictionary];

  if (filters) {
    NSMutableArray *filtered = [NSMutableArray array];
    for (NEUserWithFriend *userFriend in users) {
      NSString *uid = userFriend.user.accountId;
      if (uid && [filters containsObject:uid]) {
        continue;
      }
      [filtered addObject:userFriend];
    }
    users = filtered;
  }

  if (users.count == 0) {
    return contactList;
  }

  NSPredicate *digitRegular = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"[0-9]"];
  NSPredicate *azRegular = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"[A-Z]"];
  NSMutableArray<ContactInfo *> *digitList = [NSMutableArray array];
  NSMutableArray<ContactInfo *> *specialCharList = [NSMutableArray array];

  for (NEUserWithFriend *userFriend in users) {
    NSString *name = userFriend.user.name ?: userFriend.user.accountId;
    if (userFriend.friend.alias.length > 0) {
      name = userFriend.friend.alias;
    }

    NSString *inital = [name initalLetter] ?: @"#";
    ContactInfo *contactInfo = [[ContactInfo alloc] init];
    contactInfo.user = userFriend;

    if ([digitRegular evaluateWithObject:inital]) {
      [digitList addObject:contactInfo];
    } else if (![azRegular evaluateWithObject:inital]) {
      [specialCharList addObject:contactInfo];
    } else {
      NSMutableArray<ContactInfo *> *arr = self.initalDict[inital];
      if (arr) {
        [arr addObject:contactInfo];
      } else {
        self.initalDict[inital] = [NSMutableArray arrayWithObject:contactInfo];
      }
    }
  }

  [digitList sortUsingSelector:@selector(compare:)];
  [specialCharList sortUsingSelector:@selector(compare:)];

  for (NSString *key in self.initalDict) {
    NSMutableArray<ContactInfo *> *value = self.initalDict[key];
    [value sortUsingSelector:@selector(compare:)];
    [contactList addObject:[[ContactSection alloc] initWithInitial:key contacts:value]];
  }

  [contactList sortUsingSelector:@selector(compare:)];

  NSMutableArray<ContactInfo *> *specialList = [NSMutableArray arrayWithArray:digitList];
  [specialList addObjectsFromArray:specialCharList];
  if (specialList.count > 0) {
    [contactList addObject:[[ContactSection alloc] initWithInitial:@"#" contacts:specialList]];
  }

  return [contactList copy];
}

- (NSArray<ContactSection *> *)getFriendSections {
  NSMutableArray<ContactSection *> *friendSections = [NSMutableArray array];
  for (ContactSection *section in self.contactSections) {
    if (section.initial.length > 0) {
      [friendSections addObject:section];
    }
  }
  return friendSections;
}

- (void)getValidationMessage:(nullable void (^)(NSInteger, NSError *_Nullable))completion {
  // log removed

  __weak typeof(self) weakSelf = self;
  [self.contactRepo getUnreadApplicationCount:^(NSInteger count, NSError *_Nullable error) {
    if (![IMKitConfigCenter shared].enableTeamJoinAgreeModelAuth) {
      weakSelf.unreadCount = count;
      if (completion) {
        completion(count, error);
      }
      return;
    }

    V2NIMTeamJoinActionInfoQueryOption *option = [[V2NIMTeamJoinActionInfoQueryOption alloc] init];
    option.offset = 0;
    option.limit = neTeamJoinActionPageLimit;
    [[TeamRepo shared] getTeamJoinActionInfoList:option completion:^(V2NIMTeamJoinActionInfoResult *_Nullable result, NSError *_Nullable teamError) {
      NSArray<V2NIMTeamJoinActionInfo *> *actions = result.infos;
      if (actions) {
        NSMutableArray *unreadActions = [NSMutableArray array];
        for (V2NIMTeamJoinActionInfo *action in actions) {
          if (action.timestamp > neTeamJoinActionReadTime) {
            [unreadActions addObject:action];
          }
        }
        weakSelf.unreadCount = count + (NSInteger)unreadActions.count;
      } else {
        weakSelf.unreadCount = count;
      }
      if (completion) {
        completion(weakSelf.unreadCount, teamError ?: error);
      }
    }];
  }];
}

- (nullable ContactSection *)headerSection:(nullable NSArray<ContactHeadItem *> *)headerItem {
  // log removed

  if (!headerItem) {
    return nil;
  }
  NSMutableArray<ContactInfo *> *infos = [NSMutableArray array];
  for (ContactHeadItem *item in headerItem) {
    ContactInfo *info = [[ContactInfo alloc] init];
    info.user = [[NEUserWithFriend alloc] initWithAlias:item.name avatar:item.imageName];
    info.contactCellType = ContactCellTypeContactOthers;
    info.router = item.router;
    [infos addObject:info];
  }
  return [[ContactSection alloc] initWithInitial:@"" contacts:infos];
}

- (nullable NSArray<NSString *> *)getIndexs:(nullable NSArray<ContactSection *> *)contactSections {
  NSMutableArray<NSString *> *indexs = [NSMutableArray array];
  for (uint32_t c = 'A'; c <= 'Z'; c++) {
    [indexs addObject:[NSString stringWithFormat:@"%c", (char)c]];
  }
  [indexs addObject:@"#"];
  return [indexs copy];
}

#pragma mark - NEContactListener

- (void)onContactChange:(NSInteger)changeType
                contacts:(NSArray<NEUserWithFriend *> *)contacts {
  if (self.contactSections.count <= 1) {
    return;
  }

  BOOL needRefresh = NO;
  for (NEUserWithFriend *contact in contacts) {
    NSString *accid = contact.user.accountId;
    if (accid &&
        [[NEFriendUserCache shared] isFriend:accid] &&
        ![[NEFriendUserCache shared] isBlockAccount:accid]) {
      needRefresh = YES;
      break;
    }
  }

  if (needRefresh) {
    __weak typeof(self) weakSelf = self;
    [self loadData:nil completion:^(NSError *_Nullable error, NSInteger count) {
      [weakSelf.delegate reloadTableView];
    }];
  }
}

- (void)removeFromContacts:(NSString *)accountId {
  for (NSInteger sectionIdx = 0; sectionIdx < (NSInteger)self.contactSections.count; sectionIdx++) {
    ContactSection *section = self.contactSections[sectionIdx];
    for (NSInteger i = 0; i < (NSInteger)section.contacts.count; i++) {
      ContactInfo *contact = section.contacts[i];
      if ([contact.user.user.accountId isEqualToString:accountId]) {
        [section.contacts removeObjectAtIndex:i];
        if (section.contacts.count == 0) {
          [self.contactSections removeObjectAtIndex:sectionIdx];
        }
        [self.delegate reloadTableView];
        return;
      }
    }
  }
}

- (void)onFriendAdded:(V2NIMFriend *)friendInfo {
  __weak typeof(self) weakSelf = self;
  [self loadData:nil completion:^(NSError *_Nullable error, NSInteger count) {
    [weakSelf.delegate reloadTableView];
  }];
}

- (void)onFriendDeleted:(NSString *)accountId
           deletionType:(V2NIMFriendDeletionType)deletionType {
  if ([[NEFriendUserCache shared] isBlockAccount:accountId]) {
    return;
  }
  [self removeFromContacts:accountId];
}

- (void)onFriendAddApplication:(V2NIMFriendAddApplication *)application {
  [self getValidationMessage:nil];
}

- (void)onFriendAddRejected:(V2NIMFriendAddApplication *)rejectionInfo {
  [self getValidationMessage:nil];
}

- (void)onBlockListAdded:(V2NIMUser *)user {
  NSString *accountId = user.accountId;
  if (!accountId) return;
  [self removeFromContacts:accountId];
}

- (void)onBlockListRemoved:(NSString *)accountId {
  [[NEFriendUserCache shared] removeBlockAccount:accountId];
  if ([[NEFriendUserCache shared] isFriend:accountId]) {
    __weak typeof(self) weakSelf = self;
    [self loadData:nil completion:^(NSError *_Nullable error, NSInteger count) {
      [weakSelf.delegate reloadTableView];
    }];
  }
}

#pragma mark - NETeamListener

- (void)onReceive:(V2NIMTeamJoinActionInfo *)joinActionInfo {
  [self getValidationMessage:nil];
}

#pragma mark - NESubscribeListener

- (void)subscribeOnlineStatus {
  NSMutableArray<NSString *> *subscribeList = [NSMutableArray array];
  __block BOOL needRefresh = NO;
  for (ContactSection *section in self.contactSections) {
    for (ContactInfo *contact in section.contacts) {
      NSString *accountId = contact.user.user.accountId;
      if (accountId) {
        V2NIMUserStatus *event = [[NESubscribeManager shared] getSubscribeStatus:accountId];
        if (event) {
          self.onlineStatusDic[accountId] = @(event.statusType == V2NIM_USER_STATUS_TYPE_LOGIN);
          needRefresh = YES;
        } else {
          [subscribeList addObject:accountId];
        }
      }
    }
  }

  if (needRefresh) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self.delegate reloadTableView];
    });
  }

  if (subscribeList.count > 0) {
    [[NESubscribeManager shared] subscribeUsersOnlineState:subscribeList completion:^(NSError *_Nullable error) {
    }];
  }
}

- (void)unsubscribeOnlineStatus {
  NSMutableArray<NSString *> *subscribeList = [NSMutableArray array];
  for (ContactSection *section in self.contactSections) {
    for (ContactInfo *contact in section.contacts) {
      NSString *accountId = contact.user.user.accountId;
      if (accountId) {
        [subscribeList addObject:accountId];
      }
    }
  }

  [[NESubscribeManager shared] unSubscribeUsersOnlineState:subscribeList completion:^(NSError *_Nullable error) {
  }];
}

- (void)onUserStatusChanged:(NSArray<V2NIMUserStatus *> *)data {
  BOOL needRefresh = NO;
  for (V2NIMUserStatus *d in data) {
    if ([[NEFriendUserCache shared] isFriend:d.accountId]) {
      self.onlineStatusDic[d.accountId] = @(d.statusType == V2NIM_USER_STATUS_TYPE_LOGIN);
      needRefresh = YES;
    }
  }

  if (needRefresh) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [self.delegate reloadTableView];
    });
  }
}

@end
