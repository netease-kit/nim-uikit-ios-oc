// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NECompatibleAnimationKeypath.h"
#import <Lottie/Lottie.h>

@interface NECompatibleAnimationKeypath ()

@property (nonatomic, strong) LOTKeypath *lotKeypath;

@end

@implementation NECompatibleAnimationKeypath

- (instancetype)initWithKeypath:(NSString *)keypath {
  self = [super init];
  if (self) {
    _lotKeypath = [LOTKeypath keypathWithString:keypath];
  }
  return self;
}

- (instancetype)initWithKeys:(NSArray<NSString *> *)keys {
  self = [super init];
  if (self) {
    _lotKeypath = [LOTKeypath keypathWithString:[keys componentsJoinedByString:@"."]];
  }
  return self;
}

@end
