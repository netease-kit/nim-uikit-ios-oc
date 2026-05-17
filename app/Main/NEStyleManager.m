// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEStyleManager.h"

static NSString *const kIMUIKitStyleKey = @"imuikit_style_key";

@implementation NEStyleManager

+ (instancetype)instance {
  static NEStyleManager *manager = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    manager = [[NEStyleManager alloc] init];
  });
  return manager;
}

- (BOOL)isNormalStyle {
  NSNumber *style = [NSUserDefaults.standardUserDefaults objectForKey:kIMUIKitStyleKey];
  if (style && style.integerValue == 2) {
    return NO;
  }
  return YES;
}

- (void)setNormalStyle {
  [NSUserDefaults.standardUserDefaults setObject:@(1) forKey:kIMUIKitStyleKey];
  [NSUserDefaults.standardUserDefaults synchronize];
}

- (void)setFunStyle {
  [NSUserDefaults.standardUserDefaults setObject:@(2) forKey:kIMUIKitStyleKey];
  [NSUserDefaults.standardUserDefaults synchronize];
}

@end
