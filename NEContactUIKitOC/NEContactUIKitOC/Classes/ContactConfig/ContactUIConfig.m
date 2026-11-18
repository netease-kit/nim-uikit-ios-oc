// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "ContactUIConfig.h"
#import <NEChatKit/UIColor+NECommon.h>
#import <NEBaseUIKitOC/NEBaseUIKitOC.h>

#pragma mark - ContactProperties

@implementation ContactProperties

- (instancetype)init {
  self = [super init];
  if (self) {
    _avatarCornerRadius = 0.0;
    _avatarType = NEContactAvatarTypeRectangle;
    _itemTitleSize = 0;
    _itemTitleColor = [UIColor ne_darkText];
    _divideLineColor = [UIColor ne_borderColor];
  }
  return self;
}

@end

#pragma mark - ContactUIConfig

@implementation ContactUIConfig

+ (ContactUIConfig *)shared {
  static ContactUIConfig *instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[ContactUIConfig alloc] init];
  });
  return instance;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _showTitleBar = YES;
    _showTitleBarRight2Icon = YES;
    _showTitleBarRightIcon = YES;
    _showHeader = YES;
    _contactProperties = [[ContactProperties alloc] init];
  }
  return self;
}

@end
