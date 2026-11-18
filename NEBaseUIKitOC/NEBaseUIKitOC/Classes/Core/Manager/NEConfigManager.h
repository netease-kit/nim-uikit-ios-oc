// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 全局配置管理器，支持 key-value 存储配置参数
@interface NEConfigManager : NSObject

@property (nonatomic, class, readonly) NEConfigManager *instance;

- (void)setParameterWithKey:(NSString *)key value:(nullable id)value;
- (nullable id)getParameterWithKey:(NSString *)key;

- (void)setParameter:(nullable id)value forKey:(NSString *)key;
- (nullable id)getParameterForKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
