// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "AddApplicationViewModel.h"
#import "ContactConst.h"

#import <NEChatKit/ContactRepo.h>
#import <NEChatKit/ChatConstant.h>
#import <NEChatKit/NEChatKitOC.h>

static NSString * const NEChatAddFriendRouterCompat = @"imkit://chat/addFriend";

@interface AddApplicationViewModel () <NEContactListener>
@property (nonatomic, assign) NSUInteger offset;
@property (nonatomic, assign) BOOL finished;
@property (nonatomic, assign) NSUInteger pageMaxLimit;
@property (nonatomic, strong) NSMutableSet<NSString *> *countedUnreadApplicationKeys;
@property (nonatomic, assign) BOOL loadingApplicationList;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *loadingListUnreadGroupCounts;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *loadingCallbackUnreadGroupCounts;
@end

@implementation AddApplicationViewModel

static NSMutableSet<NSString *> *neLocallyReadApplicationKeys;

+ (void)initialize {
  if (self == [AddApplicationViewModel class]) {
    neLocallyReadApplicationKeys = [NSMutableSet set];
  }
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _contactRepo = [ContactRepo shared];
    _friendAddApplications = [NSMutableArray array];
    _countedUnreadApplicationKeys = [NSMutableSet set];
    _loadingListUnreadGroupCounts = [NSMutableDictionary dictionary];
    _loadingCallbackUnreadGroupCounts = [NSMutableDictionary dictionary];
    _offset = 0;
    _finished = NO;
    _pageMaxLimit = 100;
    [_contactRepo addContactListener:self];
  }
  return self;
}

- (void)dealloc {
  [_contactRepo removeContactListener:self];
}

- (void)loadApplicationList:(BOOL)firstLoad completion:(void (^)(NSError *_Nullable))completion {
  NSUInteger offset = firstLoad ? 0 : self.offset;
  if (firstLoad) {
    self.finished = NO;
    self.loadingApplicationList = YES;
    [self.countedUnreadApplicationKeys removeAllObjects];
    [self.loadingListUnreadGroupCounts removeAllObjects];
    [self.loadingCallbackUnreadGroupCounts removeAllObjects];
    [self.friendAddApplications removeAllObjects];
  }

  if (self.finished) {
    self.loadingApplicationList = NO;
    [self.loadingListUnreadGroupCounts removeAllObjects];
    [self.loadingCallbackUnreadGroupCounts removeAllObjects];
    completion(nil);
    return;
  }

  V2NIMFriendAddApplicationQueryOption *option = [[V2NIMFriendAddApplicationQueryOption alloc] init];
  option.offset = offset;
  option.limit = self.pageMaxLimit;

  __weak typeof(self) weakSelf = self;
  [self.contactRepo getAddApplicationList:option completion:^(V2NIMFriendAddApplicationResult *_Nullable result, NSError *_Nullable error) {
    if (error) {
      weakSelf.loadingApplicationList = NO;
      [weakSelf.loadingListUnreadGroupCounts removeAllObjects];
      [weakSelf.loadingCallbackUnreadGroupCounts removeAllObjects];
      completion(error);
    } else if (result) {
      weakSelf.offset = result.offset;
      weakSelf.finished = result.finished;

      for (V2NIMFriendAddApplication *item in result.infos ?: @[]) {
        [weakSelf convertToNEAddApplication:item move:NO completion:^(NSError *_Nullable err) {}];
      }

      [weakSelf loadApplicationList:NO completion:completion];
    }
  }];
}

- (void)convertToNEAddApplication:(V2NIMFriendAddApplication *)item
                              move:(BOOL)move
                        completion:(void (^)(NSError *_Nullable))completion {
  BOOL isExist = NO;
  for (NSInteger index = 0; index < (NSInteger)self.friendAddApplications.count; index++) {
    NEAddApplication *neItem = self.friendAddApplications[index];
    if ([neItem isEqualTo:item]) {
      isExist = YES;
      if ([self shouldCountUnreadApplication:item fromCallback:move]) {
        neItem.unreadCount += 1;
      }
      if (move && index != 0) {
        [self.friendAddApplications removeObjectAtIndex:index];
        [self.friendAddApplications insertObject:neItem atIndex:0];
      }
      [self.delegate tableviewReload];
      break;
    }
  }

  if (isExist) {
    completion(nil);
    return;
  }

  NEAddApplication *friendAddApplication = [[NEAddApplication alloc] initWithApplication:item];
  friendAddApplication.unreadCount = [self shouldCountUnreadApplication:item fromCallback:move] ? 1 : 0;
  NSString *applicationAccid = friendAddApplication.v2Notification.applicantAccountId;

  if ([friendAddApplication.v2Notification.applicantAccountId isEqualToString:[[IMKitClient instance] account]]) {
    applicationAccid = friendAddApplication.v2Notification.recipientAccountId;
    if (friendAddApplication.v2Notification.status == V2NIM_FRIEND_ADD_APPLICATION_STATUS_AGREED) {
      friendAddApplication.detail = contactLocalizable(@"agreed_request");
    }
    if (friendAddApplication.v2Notification.status == V2NIM_FRIEND_ADD_APPLICATION_STATUS_REJECED) {
      friendAddApplication.detail = contactLocalizable(@"refused_request");
    }
  }

  friendAddApplication.displayUserId = applicationAccid;
  NSInteger friendAddApplicationsCount = (NSInteger)self.friendAddApplications.count;
  NSInteger insertIndex = move ? 0 : (self.friendAddApplications.count == 0 ? 0 : friendAddApplicationsCount);
  [self.friendAddApplications insertObject:friendAddApplication atIndex:insertIndex];

  if (applicationAccid) {
    __weak typeof(self) weakSelf = self;
    [self.contactRepo getUserWithFriend:@[applicationAccid] completion:^(NSArray<NEUserWithFriend *> *_Nullable users, NSError *_Nullable error) {
      NEUserWithFriend *user = users.firstObject;
      if (user) {
        friendAddApplication.displayUserWithFriend = user;
        [weakSelf.delegate tableviewReload];
      }
    }];
  }
}

- (void)setAddApplicationRead:(nullable void (^)(BOOL, NSError *_Nullable))completion {
  [self markCurrentApplicationsLocallyRead];

  __weak typeof(self) weakSelf = self;
  [self.contactRepo setAddApplicationRead:^(BOOL success, NSError *_Nullable error) {
    for (NEAddApplication *application in weakSelf.friendAddApplications) {
      application.unreadCount = 0;
    }
    [weakSelf.countedUnreadApplicationKeys removeAllObjects];
    [weakSelf.loadingListUnreadGroupCounts removeAllObjects];
    [weakSelf.loadingCallbackUnreadGroupCounts removeAllObjects];
    if (completion) {
      completion(success, error);
    }
    dispatch_async(dispatch_get_main_queue(), ^{
      [[NSNotificationCenter defaultCenter] postNotificationName:NENotificationClearValidationMessageUnreadCount object:nil];
    });
  }];
}

- (void)changeApplicationStatus:(V2NIMFriendAddApplication *)application
                          status:(V2NIMFriendAddApplicationStatus)status {
  NSInteger changedIndex = -1;
  for (NSInteger index = 0; index < (NSInteger)self.friendAddApplications.count; index++) {
    NEAddApplication *item = self.friendAddApplications[index];
    if ([item isEqualTo:application compareStatus:NO]) {
      item.handleStatus = status;
      item.unreadCount = 0;
      changedIndex = index;
      break;
    }
  }

  if (changedIndex > -1) {
    NSInteger index = changedIndex + 1;
    while (index < (NSInteger)self.friendAddApplications.count) {
      if ([self.friendAddApplications[index] isEqualTo:application compareStatus:YES]) {
        [self.friendAddApplications removeObjectAtIndex:index];
      } else {
        index++;
      }
    }
  }
}

- (BOOL)shouldCountUnreadApplication:(V2NIMFriendAddApplication *)application
                         fromCallback:(BOOL)fromCallback {
  if (!application || application.read) {
    return NO;
  }

  NSArray<NSString *> *keys = [self unreadApplicationKeys:application];
  @synchronized (neLocallyReadApplicationKeys) {
    for (NSString *key in keys) {
      if ([neLocallyReadApplicationKeys containsObject:key]) {
        return NO;
      }
    }
  }

  for (NSString *key in keys) {
    if ([self.countedUnreadApplicationKeys containsObject:key]) {
      return NO;
    }
  }

  NSString *groupKey = [self unreadApplicationGroupKey:application];
  if (self.loadingApplicationList && groupKey.length > 0) {
    NSMutableDictionary<NSString *, NSNumber *> *oppositeCounts =
      fromCallback ? self.loadingListUnreadGroupCounts : self.loadingCallbackUnreadGroupCounts;
    NSInteger oppositeCount = [oppositeCounts[groupKey] integerValue];
    if (oppositeCount > 0) {
      if (oppositeCount > 1) {
        oppositeCounts[groupKey] = @(oppositeCount - 1);
      } else {
        [oppositeCounts removeObjectForKey:groupKey];
      }
      [self markUnreadApplicationKeysCounted:keys];
      return NO;
    }
  }

  [self markUnreadApplicationKeysCounted:keys];

  if (self.loadingApplicationList && groupKey.length > 0) {
    NSMutableDictionary<NSString *, NSNumber *> *sameSourceCounts =
      fromCallback ? self.loadingCallbackUnreadGroupCounts : self.loadingListUnreadGroupCounts;
    NSInteger sameSourceCount = [sameSourceCounts[groupKey] integerValue];
    sameSourceCounts[groupKey] = @(sameSourceCount + 1);
  }

  return YES;
}

- (void)markCurrentApplicationsLocallyRead {
  @synchronized (neLocallyReadApplicationKeys) {
    for (NEAddApplication *application in self.friendAddApplications) {
      for (NSString *key in [self unreadApplicationKeys:application.v2Notification]) {
        [neLocallyReadApplicationKeys addObject:key];
      }
    }
  }
}

- (void)markUnreadApplicationKeysCounted:(NSArray<NSString *> *)keys {
  for (NSString *key in keys) {
    [self.countedUnreadApplicationKeys addObject:key];
  }
}

- (NSArray<NSString *> *)unreadApplicationKeys:(V2NIMFriendAddApplication *)application {
  NSMutableArray<NSString *> *keys = [NSMutableArray array];

  if (application.serverId.length > 0) {
    [keys addObject:[NSString stringWithFormat:@"server:%@", application.serverId]];
  }

  NSTimeInterval eventTime = application.updateTimestamp > 0 ? application.updateTimestamp : application.timestamp;
  if (eventTime > 0) {
    [keys addObject:[NSString stringWithFormat:@"time:%@:%@:%ld:%.6f",
                                               application.applicantAccountId ?: @"",
                                               application.recipientAccountId ?: @"",
                                               (long)application.status,
                                               eventTime]];
  }

  V2NIMPostscript *postscript = application.postscriptHistory.lastObject;
  if (postscript.time > 0) {
    [keys addObject:[NSString stringWithFormat:@"postscript:%@:%@:%ld:%@:%.6f:%@",
                                               application.applicantAccountId ?: @"",
                                               application.recipientAccountId ?: @"",
                                               (long)application.status,
                                               postscript.fromAccount ?: @"",
                                               postscript.time,
                                               postscript.content ?: @""]];
  }

  return [keys copy];
}

- (NSString *)unreadApplicationGroupKey:(V2NIMFriendAddApplication *)application {
  if (!application) {
    return nil;
  }
  return [NSString stringWithFormat:@"%@:%@:%ld",
                                    application.applicantAccountId ?: @"",
                                    application.recipientAccountId ?: @"",
                                    (long)application.status];
}

- (void)agreeRequest:(V2NIMFriendAddApplication *)application
          completion:(void (^)(NSError *_Nullable))completion {
  __weak typeof(self) weakSelf = self;
  [self.contactRepo acceptAddApplication:application completion:^(NSError *_Nullable error) {
    if (error) {
      NSLog(@"%@", error.localizedDescription);
    } else {
      NSString *accid = application.applicantAccountId;
      if (accid) {
        NSString *conversationId = [V2NIMConversationIdUtil p2pConversationId:accid];
        if (conversationId) {
          [[Router shared] use:NEChatAddFriendRouterCompat
                  parameters:@{@"text": contactLocalizable(@"let_us_chat"),
                                @"conversationId": conversationId}
                     closure:nil];
        }
      }
      [weakSelf changeApplicationStatus:application status:V2NIM_FRIEND_ADD_APPLICATION_STATUS_AGREED];
    }
    completion(error);
  }];
}

- (void)refuseRequest:(V2NIMFriendAddApplication *)application
           completion:(void (^)(NSError *_Nullable))completion {
  __weak typeof(self) weakSelf = self;
  [self.contactRepo rejectAddApplication:application postscript:nil completion:^(NSError *_Nullable error) {
    if (error) {
      NSLog(@"%@", error.localizedDescription);
    } else {
      [weakSelf changeApplicationStatus:application status:V2NIM_FRIEND_ADD_APPLICATION_STATUS_REJECED];
    }
    completion(error);
  }];
}

- (void)clearNotification:(void (^)(NSError *_Nullable))completion {
  __weak typeof(self) weakSelf = self;
  [self.contactRepo clearNotification:^(NSError *_Nullable error) {
    if (error) {
      NSLog(@"%@", error.localizedDescription);
    }
    [weakSelf.friendAddApplications removeAllObjects];
    completion(error);
  }];
}

#pragma mark - NEContactListener

- (void)onFriendAddApplication:(V2NIMFriendAddApplication *)application {
  [self convertToNEAddApplication:application move:YES completion:^(NSError *_Nullable error) {
    if (error) {
      NSLog(@"%@", error.localizedDescription);
    }
  }];
}

- (void)onFriendAddRejected:(V2NIMFriendAddApplication *)rejectionInfo {
  for (NEAddApplication *item in self.friendAddApplications) {
    if ([item.v2Notification.applicantAccountId isEqualToString:[[IMKitClient instance] account]] &&
        [item.v2Notification.recipientAccountId isEqualToString:rejectionInfo.operatorAccountId]) {
      item.handleStatus = V2NIM_FRIEND_ADD_APPLICATION_STATUS_REJECED;
      item.unreadCount = 0;
    }
  }
  [self.delegate tableviewReload];
}

@end
