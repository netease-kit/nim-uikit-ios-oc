// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <NEChatKit/ChatKitClient.h>

/// 组件被链接时即上报 MapKitOC 初始化数据点。
@interface NEMapKitOCInitLoader : NSObject
@end

@implementation NEMapKitOCInitLoader

+ (void)load {
  NSString *version = [ChatKitClient componentVersionForBundle:[NSBundle bundleForClass:self]
                                                      fallback:@""];
  [[ChatKitClient shared] buryDataPoints:@"MapKitOC" version:version];
}

@end
