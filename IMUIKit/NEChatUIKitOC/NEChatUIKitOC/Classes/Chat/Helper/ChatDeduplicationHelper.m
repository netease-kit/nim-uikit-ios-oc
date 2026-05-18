// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "ChatDeduplicationHelper.h"
#import <NEChatKitOC/NECoreIM2KitOC.h>
#import <NIMSDK/NIMSDK.h>

@implementation ChatDeduplicationHelper

+ (ChatDeduplicationHelper *)instance {
  static ChatDeduplicationHelper *_instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _instance = [[ChatDeduplicationHelper alloc] initPrivate];
  });
  return _instance;
}

- (instancetype)initPrivate {
  self = [super init];
  if (self) {
    _limit = 100;
    _blackListMessageIds = [NSMutableSet set];
    _recordAudioMessagePaths = [NSMutableSet set];
    _sendingMessageIds = [NSMutableSet set];
    _revokeMessageIds = [NSMutableSet set];
    [[IMKitClient instance] addLoginListener:self];
  }
  return self;
}

- (void)dealloc {
  [[IMKitClient instance] removeLoginListener:self];
}

#pragma mark - NEIMKitClientListener

- (void)onLoginStatus:(V2NIMLoginStatus)status {
  if (status == V2NIM_LOGIN_STATUS_LOGOUT) {
    [self clearCache];
  }
}

- (void)onKickedOffline:(V2NIMKickedOfflineDetail *)detail {
  [self clearCache];
}

#pragma mark - Public

- (void)clearCache {
  [self.blackListMessageIds removeAllObjects];
  [self.recordAudioMessagePaths removeAllObjects];
  [self.revokeMessageIds removeAllObjects];
}

- (BOOL)isMessageSended:(NSString *)messageId {
  if ([self.sendingMessageIds containsObject:messageId]) {
    return YES;
  }
  if ((NSInteger)self.sendingMessageIds.count > self.limit) {
    [self.sendingMessageIds removeAllObjects];
  }
  [self.sendingMessageIds addObject:messageId];
  return NO;
}

- (BOOL)isBlackTipSended:(NSString *)messageId {
  if ([self.blackListMessageIds containsObject:messageId]) {
    return YES;
  }
  if ((NSInteger)self.blackListMessageIds.count > self.limit) {
    [self.blackListMessageIds removeAllObjects];
  }
  [self.blackListMessageIds addObject:messageId];
  return NO;
}

- (void)removeBlackTipSendedId:(NSString *)messageId {
  if (!messageId) {
    return;
  }
  if ([self.blackListMessageIds containsObject:messageId]) {
    [self.blackListMessageIds removeObject:messageId];
  }
}

- (BOOL)isRecordAudioSended:(NSString *)path {
  if ([self.recordAudioMessagePaths containsObject:path]) {
    return YES;
  }
  if ((NSInteger)self.recordAudioMessagePaths.count > self.limit) {
    [self.recordAudioMessagePaths removeAllObjects];
  }
  return NO;
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
