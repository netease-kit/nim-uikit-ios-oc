// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "ConversationUIConfig.h"

#pragma mark - ConversationProperties

@implementation ConversationProperties

- (instancetype)init {
  if (self = [super init]) {
    _avatarCornerRadius = 0.0;
    _avatarType = NEConversationAvatarTypeRectangle;
    _itemTitleSize = 0;
    _itemContentSize = 0;
    _itemDateSize = 0;
    _itemTitleColor = [UIColor darkTextColor];
    _itemContentColor = [UIColor lightGrayColor];
    _itemDateColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1.0]; // 0xcccccc
  }
  return self;
}

@end

#pragma mark - ConversationUIConfig

@implementation ConversationUIConfig

+ (instancetype)shared {
  static ConversationUIConfig *_shared = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _shared = [[ConversationUIConfig alloc] initPrivate];
  });
  return _shared;
}

- (instancetype)initPrivate {
  if (self = [super init]) {
    _showTitleBar = YES;
    _showTitleBarLeftIcon = YES;
    _showTitleBarRight2Icon = YES;
    _showTitleBarRightIcon = YES;
    _conversationProperties = [[ConversationProperties alloc] init];
  }
  return self;
}

@end
