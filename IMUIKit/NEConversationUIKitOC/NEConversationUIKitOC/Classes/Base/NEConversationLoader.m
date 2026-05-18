// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEConversationLoader.h"
#import "NEConversationLoaderService.h"

@implementation NEConversationLoader

+ (void)load {
  [[NEConversationLoaderService shared] setupInit];
}

@end
