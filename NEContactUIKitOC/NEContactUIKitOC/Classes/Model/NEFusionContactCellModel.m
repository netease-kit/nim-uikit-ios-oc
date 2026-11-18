// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEFusionContactCellModel.h"
#import <NEChatKit/NEChatKit.h>

@implementation NEFusionContactCellModel

- (instancetype)init {
  self = [super init];
  if (self) {
    _type = 0;
    _selected = NO;
  }
  return self;
}

- (NSString *)getAccountId {
  if (self.aiUser.accountId) {
    return self.aiUser.accountId;
  } else if (self.user.user.accountId) {
    return self.user.user.accountId;
  }
  return @"";
}

- (NSString *)getShowName {
  NSString *name = [self.user showName];
  if (name) {
    if (name.length > 0) {
      return name;
    }
    return self.user.user.accountId ?: @"";
  } else if (self.aiUser.name) {
    if (self.aiUser.name.length > 0) {
      return self.aiUser.name;
    }
    return self.aiUser.accountId ?: @"";
  }
  return @"";
}

- (NSString *)getShortName:(NSInteger)count {
  NSString *name = [self getShowName];
  if ((NSInteger)name.length > count) {
    return [name substringFromIndex:name.length - count];
  }
  return name;
}

@end
