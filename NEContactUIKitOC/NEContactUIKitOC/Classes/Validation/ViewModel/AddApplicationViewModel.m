// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "AddApplicationViewModel.h"
#import "ContactConst.h"

#import <NEChatKit/ContactRepo.h>
#import <NEChatKit/ChatConstant.h>
#import <NEChatKit/NEChatKit.h>

static NSString * const NEChatAddFriendRouterCompat = @"imkit://chat/addFriend";

@interface AddApplicationViewModel () <NEContactListener>
@property (nonatomic, assign) NSUInteger offset;
@property (nonatomic, assign) BOOL finished;
@property (nonatomic, assign) NSUInteger pageMaxLimit;
@property (nonatomic, assign) BOOL loadingApplicationList;
@property (nonatomic, assign) BOOL shouldReloadApplicationList;
@end

@implementation AddApplicationViewModel

static NSString * const NEAddApplicationClearTimestampPrefix = @"NEContactUIKit.friendAddApplication.clearTimestamp.";
static NSString * const NEAddApplicationPendingClearTimestampPrefix = @"NEContactUIKit.friendAddApplication.pendingClearTimestamp.";
static NSString * const NEAddApplicationLastReadTimestampPrefix = @"NEContactUIKit.friendAddApplication.lastReadTimestamp.";

- (instancetype)init {
  self = [super init];
  if (self) {
    _contactRepo = [ContactRepo shared];
    _friendAddApplications = [NSMutableArray array];
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
    [self.friendAddApplications removeAllObjects];
    [self retryPendingClearIfNeeded];
  }

  if (self.finished) {
    [self finishLoadingApplicationList];
    completion(nil);
    [self reloadApplicationListIfNeeded];
    return;
  }

  V2NIMFriendAddApplicationQueryOption *option = [[V2NIMFriendAddApplicationQueryOption alloc] init];
  option.offset = offset;
  option.limit = self.pageMaxLimit;

  __weak typeof(self) weakSelf = self;
  [self.contactRepo getAddApplicationList:option completion:^(V2NIMFriendAddApplicationResult *_Nullable result, NSError *_Nullable error) {
    if (error) {
      [weakSelf finishLoadingApplicationList];
      completion(error);
      [weakSelf reloadApplicationListIfNeeded];
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

- (void)loadApplicationList:(BOOL)firstLoad :(void (^)(NSError *_Nullable))completion {
  [self loadApplicationList:firstLoad completion:completion];
}

- (void)convertToNEAddApplication:(V2NIMFriendAddApplication *)item
                              move:(BOOL)move
                        completion:(void (^)(NSError *_Nullable))completion {
  if ([self isLocallyCleared:item]) {
    if (completion) completion(nil);
    return;
  }
  BOOL isExist = NO;
  for (NSInteger index = 0; index < (NSInteger)self.friendAddApplications.count; index++) {
    NEAddApplication *neItem = self.friendAddApplications[index];
    if ([neItem isEqualTo:item]) {
      isExist = YES;
      neItem.unreadCount += [self unreadCountForApplication:item];
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
  friendAddApplication.unreadCount = [self unreadCountForApplication:item];
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

- (void)convertToNEAddApplication:(V2NIMFriendAddApplication *)item
                                  :(BOOL)move
                                  :(void (^)(NSError *_Nullable))completion {
  [self convertToNEAddApplication:item move:move completion:completion];
}

- (void)setAddApplicationRead:(nullable void (^)(BOOL, NSError *_Nullable))completion {
  NSTimeInterval readTime = [NSDate date].timeIntervalSince1970;
  NSString *readKey = [self lastReadTimestampKey];
  __weak typeof(self) weakSelf = self;
  [self.contactRepo setAddApplicationRead:^(BOOL success, NSError *_Nullable error) {
    if (success) {
      [[NSUserDefaults standardUserDefaults] setDouble:readTime forKey:readKey];
    }
    for (NEAddApplication *application in weakSelf.friendAddApplications) {
      application.unreadCount = 0;
    }
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

- (void)changeApplicationStatus:(V2NIMFriendAddApplication *)application
                               :(V2NIMFriendAddApplicationStatus)status {
  [self changeApplicationStatus:application status:status];
}

- (NSString *)lastReadTimestampKey {
  return [NEAddApplicationLastReadTimestampPrefix stringByAppendingString:[[IMKitClient instance] account] ?: @""];
}

- (NSTimeInterval)lastReadTimestamp {
  return [[NSUserDefaults standardUserDefaults] doubleForKey:[self lastReadTimestampKey]];
}

/// 单条申请的未读数：统计上次离开验证消息页之后到达的验证消息条数。
/// 不依赖 status / SDK read：已是好友时服务端会自动同意，记录可能直接是 AGREED 且 read=1，
/// 但消息本身仍是用户没看过的验证消息。
- (NSUInteger)unreadCountForApplication:(V2NIMFriendAddApplication *)application {
  if (!application) {
    return 0;
  }
  NSTimeInterval lastRead = [self lastReadTimestamp];
  NSUInteger unread = 0;
  for (V2NIMPostscript *postscript in application.postscriptHistory) {
    if (postscript.time > lastRead) {
      unread += 1;
    }
  }
  if (unread == 0 && application.timestamp > lastRead) {
    unread = 1;
  }
  return unread;
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

- (void)agreeRequestWithApplication:(V2NIMFriendAddApplication *)application
                                    :(void (^)(NSError *_Nullable))completion {
  [self agreeRequest:application completion:completion];
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

- (void)refuseRequestWithApplication:(V2NIMFriendAddApplication *)application
                                     :(void (^)(NSError *_Nullable))completion {
  [self refuseRequest:application completion:completion];
}

- (void)clearNotification:(void (^)(NSError *_Nullable))completion {
  V2NIMFriendClearAddApplicationOption *option = [[V2NIMFriendClearAddApplicationOption alloc] init];
  NSTimeInterval timestamp = MAX(option.timestamp, [self locallyClearedTimestamp]);
  [self setLocallyClearedTimestamp:timestamp];
  [self setPendingClearTimestamp:timestamp];
  [self.friendAddApplications removeAllObjects];
  [self.delegate tableviewReload];

  __weak typeof(self) weakSelf = self;
  [self clearApplicationsBefore:timestamp completion:^(NSError *_Nullable error) {
    if (error) {
      NSLog(@"%@", error.localizedDescription);
    } else {
      [weakSelf markPendingClearCompleted:timestamp];
    }
    if (completion) completion(error);
  }];
}

- (void)finishLoadingApplicationList {
  self.loadingApplicationList = NO;
}

- (void)refreshApplicationListForNewEvent {
  if (self.loadingApplicationList) {
    self.shouldReloadApplicationList = YES;
    return;
  }

  __weak typeof(self) weakSelf = self;
  [self loadApplicationList:YES completion:^(NSError *_Nullable error) {
    if (error) {
      NSLog(@"refreshApplicationListForNewEvent CALLBACK error: %@", error.localizedDescription);
    }
    [weakSelf.delegate tableviewReload];
  }];
}

- (void)reloadApplicationListIfNeeded {
  if (!self.shouldReloadApplicationList) return;
  self.shouldReloadApplicationList = NO;
  [self refreshApplicationListForNewEvent];
}

- (NSString *)localClearTimestampKey {
  return [NEAddApplicationClearTimestampPrefix stringByAppendingString:[[IMKitClient instance] account] ?: @""];
}

- (NSString *)pendingClearTimestampKey {
  return [NEAddApplicationPendingClearTimestampPrefix stringByAppendingString:[[IMKitClient instance] account] ?: @""];
}

- (NSTimeInterval)locallyClearedTimestamp {
  return [[NSUserDefaults standardUserDefaults] doubleForKey:[self localClearTimestampKey]];
}

- (void)setLocallyClearedTimestamp:(NSTimeInterval)timestamp {
  [[NSUserDefaults standardUserDefaults] setDouble:timestamp forKey:[self localClearTimestampKey]];
}

- (NSTimeInterval)pendingClearTimestamp {
  return [[NSUserDefaults standardUserDefaults] doubleForKey:[self pendingClearTimestampKey]];
}

- (void)setPendingClearTimestamp:(NSTimeInterval)timestamp {
  [[NSUserDefaults standardUserDefaults] setDouble:timestamp forKey:[self pendingClearTimestampKey]];
}

- (BOOL)isLocallyCleared:(V2NIMFriendAddApplication *)application {
  NSTimeInterval clearTimestamp = [self locallyClearedTimestamp];
  if (clearTimestamp <= 0 || !application) return NO;

  V2NIMPostscript *postscript = application.postscriptHistory.lastObject;
  NSTimeInterval latestPostscriptTimestamp = postscript.time;
  NSTimeInterval eventTimestamp = MAX(application.timestamp, MAX(application.updateTimestamp, latestPostscriptTimestamp));
  return eventTimestamp == 0 || eventTimestamp <= clearTimestamp;
}

- (void)retryPendingClearIfNeeded {
  NSTimeInterval timestamp = [self pendingClearTimestamp];
  if (timestamp <= 0) return;

  __weak typeof(self) weakSelf = self;
  [self clearApplicationsBefore:timestamp completion:^(NSError *_Nullable error) {
    if (!error) [weakSelf markPendingClearCompleted:timestamp];
  }];
}

- (void)clearApplicationsBefore:(NSTimeInterval)timestamp
                     completion:(void (^)(NSError *_Nullable error))completion {
  V2NIMFriendClearAddApplicationOption *option = [[V2NIMFriendClearAddApplicationOption alloc] init];
  option.timestamp = timestamp;
  option.type = V2NIM_FRIEND_ADD_APPLICATION_TYPE_ALL;
  [self.contactRepo clearAllAddApplicationEx:option completion:completion];
}

- (void)markPendingClearCompleted:(NSTimeInterval)timestamp {
  if ([self pendingClearTimestamp] <= timestamp) {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[self pendingClearTimestampKey]];
  }
}

#pragma mark - NEContactListener

- (void)onFriendAddApplication:(V2NIMFriendAddApplication *)application {
  // 统一整表重拉：未读数按拉取到的每条未读记录计算，
  dispatch_async(dispatch_get_main_queue(), ^{
    [self refreshApplicationListForNewEvent];
  });
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
