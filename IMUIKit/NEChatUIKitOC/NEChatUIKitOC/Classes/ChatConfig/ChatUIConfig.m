
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "ChatUIConfig.h"
#import <NEChatKitOC/UIColor+NECommon.h>

#pragma mark - MessageProperties

@implementation MessageProperties

- (instancetype)init {
  self = [super init];
  if (self) {
    _avatarCornerRadius = 0;
    _avatarType = NEChatAvatarTypeRectangle;
    _signalBgColor = UIColor.ne_yellowBackgroundColor;
    _timeTextColor = UIColor.ne_emptyTitleColor;
    _timeTextSize = 14;
    _selfMessageTextSize = 16;
    _receiveMessageTextSize = 16;
    _selfMessageTextColor = UIColor.ne_darkText;
    _receiveMessageTextColor = UIColor.ne_darkText;
    _inputTextColor = UIColor.ne_darkText;
    _inputPlaceholderTextColor = nil;
    _selfMessageBgColor = [UIColor clearColor];
    _receiveMessageBgColor = [UIColor clearColor];
    _selfMessageBgImage = nil;
    _receiveMessageBgImage = nil;
    _backgroundImageCapInsets = UIEdgeInsetsMake(35, 25, 10, 25);
    _backgroundImageCapInsetsSet = YES;
    _userNickColor = [UIColor whiteColor];
    _userNickTextSize = 12;
    _pinMessageTextSize = 14;
    _showP2PMessageStatus = YES;
    _showTeamMessageStatus = YES;
    _showTeamMessageNick = YES;
    _showTitleBar = YES;
    _showTitleBarRightIcon = YES;
    _titleBarRightRes = nil;
    _titleBarRightClick = nil;
    _chatTableViewBackgroundColor = nil;
    _chatViewBackgroundSolid = NO;
  }
  return self;
}

@end

#pragma mark - ChatUIConfig

@interface ChatUIConfig ()

@property(nonatomic, assign) NSInteger revokeTimeGap;

@end

@implementation ChatUIConfig

+ (instancetype)shared {
  static ChatUIConfig *instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[ChatUIConfig alloc] init];
  });
  return instance;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _messageProperties = [[MessageProperties alloc] init];
    _fileSizeLimit = 200;
    _imageThumbSize = 350;
    _maxReadingNum = 200;
    _revokeEditTimeGap = 2;
    _revokeTimeGap = 10080;
  }
  return self;
}

- (void)setRevokeTimeGap:(NSInteger)time {
  _revokeTimeGap = MAX(time, 2);        // >= 2 min
  _revokeTimeGap = MIN(_revokeTimeGap, 10080); // <= 7 d
}

- (NSInteger)getReeditTimeGap {
  return _revokeTimeGap;
}

@end
