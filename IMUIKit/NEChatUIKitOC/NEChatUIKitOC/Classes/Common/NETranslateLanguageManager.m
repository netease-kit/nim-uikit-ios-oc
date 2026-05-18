// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NETranslateLanguageManager.h"

@implementation NETranslateLanguageManager

+ (NETranslateLanguageManager *)shared {
  static NETranslateLanguageManager *instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[NETranslateLanguageManager alloc] initPrivate];
  });
  return instance;
}

- (instancetype)initPrivate {
  self = [super init];
  if (self) {
    _languageDatas = [@[@"英语", @"日语", @"韩语", @"俄语", @"法语", @"德语"] mutableCopy];
  }
  return self;
}

@end
