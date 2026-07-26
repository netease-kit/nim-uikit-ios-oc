// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <NEChatKit/IMKitPluginManager.h>
#import <NEChatKit/XKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NEAISearchManager : NSObject <XKitService, IMKitPluginService>

@property (nonatomic, strong) NSString *serviceName;
@property (nonatomic, strong) NSString *versionName;
@property (nonatomic, strong) NSString *appKey;

+ (instancetype)shared;
- (void)setupInit;

@end

NS_ASSUME_NONNULL_END
