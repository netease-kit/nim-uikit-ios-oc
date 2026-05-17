// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NSError+Chat.h"
#import "NEChatUIConstant.h"

@implementation NSError (Chat)

+ (NSError *)paramError {
  return [NSError errorWithDomain:@"com.qchat.doamin"
                             code:600
                         userInfo:@{@"message": chatLocalizable(@"param_error")}];
}

@end
