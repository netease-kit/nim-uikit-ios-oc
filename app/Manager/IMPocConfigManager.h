// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 对齐 Swift IMPocConfigModel
@interface IMPocConfigModel : NSObject <NSCoding>

@property (nonatomic, strong) NSMutableDictionary *configMap;
@property (nonatomic, copy, nullable)   NSString  *customJson;
@property (nonatomic, strong) NSNumber            *enableCustomConfig;
@property (nonatomic, copy, nullable)   NSString  *accountId;
@property (nonatomic, copy, nullable)   NSString  *accountIdToken;

@end

/// 对齐 Swift IMPocConfigManager — 私有云配置持久化
@interface IMPocConfigManager : NSObject

+ (instancetype)instance;

- (IMPocConfigModel *)getConfig;
- (void)saveConfig:(IMPocConfigModel *)model;
- (void)clearConfig;

@end

NS_ASSUME_NONNULL_END
