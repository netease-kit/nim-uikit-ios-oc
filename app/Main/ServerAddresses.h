// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>

@class IMPocConfigModel;

NS_ASSUME_NONNULL_BEGIN

@interface ServerAddresses : NSObject

+ (void)configServer;
+ (void)configCustomServer:(IMPocConfigModel *)model;
+ (nullable NSString *)customAppkeyFromConfig:(IMPocConfigModel *)model;

@end

NS_ASSUME_NONNULL_END
