// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEInvocation.h"

@implementation NEInvocation

- (instancetype)init:(id)target :(SEL)action {
  self = [super init];
  if (self) {
    _target = target;
    _action = action;
  }
  return self;
}

- (instancetype)initWithTarget:(id)target action:(SEL)action {
  return [self init:target :action];
}

- (void)invokeFrom:(id)sender {
  if (!self.target || !self.action) {
    return;
  }
  [UIApplication.sharedApplication sendAction:self.action to:self.target from:sender forEvent:nil];
}

@end
