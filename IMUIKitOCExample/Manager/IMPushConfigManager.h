// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <NIMSDK/NIMSDK.h>

NS_ASSUME_NONNULL_BEGIN

@interface IMPushConfigModel : NSObject <NSCoding>

@property (nonatomic, strong) NSMutableDictionary    *configMap;
@property (nonatomic, copy, nullable)   NSString     *customJson;
@property (nonatomic, strong) V2NIMMessagePushConfig *config;

@end

@interface IMPushConfigManager : NSObject

+ (instancetype)instance;

- (IMPushConfigModel *)getConfig;
- (V2NIMMessagePushConfig *)getPushConfig;
- (void)saveConfig:(IMPushConfigModel *)model;
- (void)clearConfig;

@end

NS_ASSUME_NONNULL_END
