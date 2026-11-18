// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "ConversationDeduplicationHelper.h"

@implementation ConversationDeduplicationHelper

+ (ConversationDeduplicationHelper *)instance {
  static ConversationDeduplicationHelper *instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[ConversationDeduplicationHelper alloc] initPrivate];
  });
  return instance;
}

- (instancetype)initPrivate {
  self = [super init];
  if (self) {
    _limit = 100;
    _revokeMessageIds = [NSMutableSet set];
    [IMKitClient.instance addLoginListener:self];
  }
  return self;
}

- (void)dealloc {
  [IMKitClient.instance removeLoginListener:self];
}

- (void)onLoginStatus:(V2NIMLoginStatus)status {
  if (status == V2NIM_LOGIN_STATUS_LOGOUT) {
    [self clearCache];
  }
}

- (void)onKickedOffline:(V2NIMKickedOfflineDetail *)detail {
  [self clearCache];
}

- (void)clearCache {
  [self.revokeMessageIds removeAllObjects];
}

- (BOOL)isRevokeMessageSaved:(NSString *)messageId {
  if ([self.revokeMessageIds containsObject:messageId]) {
    return YES;
  }
  if ((NSInteger)self.revokeMessageIds.count > self.limit) {
    [self.revokeMessageIds removeAllObjects];
  }
  [self.revokeMessageIds addObject:messageId];
  return NO;
}

@end
