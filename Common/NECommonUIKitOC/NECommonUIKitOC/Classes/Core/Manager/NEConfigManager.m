// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEConfigManager.h"

@interface NEConfigManager ()
@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *configParameter;
@end

@implementation NEConfigManager

+ (NEConfigManager *)instance {
  static NEConfigManager *_instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _instance = [[NEConfigManager alloc] init];
  });
  return _instance;
}

- (instancetype)init {
  if (self = [super init]) {
    _configParameter = [NSMutableDictionary dictionary];
  }
  return self;
}

- (void)setParameter:(nullable id)value forKey:(NSString *)key {
  if (value) {
    self.configParameter[key] = value;
  } else {
    [self.configParameter removeObjectForKey:key];
  }
}

- (nullable id)getParameterForKey:(NSString *)key {
  return self.configParameter[key];
}

@end