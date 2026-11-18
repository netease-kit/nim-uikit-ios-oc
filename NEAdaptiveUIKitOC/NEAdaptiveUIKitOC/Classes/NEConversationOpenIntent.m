// Copyright (c) 2026 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEConversationOpenIntent.h"

@implementation NEConversationOpenIntent

- (instancetype)initWithKey:(NSString *)key
                      route:(NSString *)route
                 parameters:(NSDictionary<NSString *, id> *)parameters
 requiresPresentationAction:(BOOL)requiresPresentationAction {
  self = [super init];
  if (self) {
    _key = [key copy];
    _route = [route copy];
    _parameters = [parameters copy];
    _requiresPresentationAction = requiresPresentationAction;
  }
  return self;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<NEConversationOpenIntent: key=%@ route=%@ action=%d>",
                                    _key, _route, (int)_requiresPresentationAction];
}

@end
