// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>

@class TeamRepo;

NS_ASSUME_NONNULL_BEGIN

@interface TeamRouter : NSObject

@property (class, nonatomic, readonly, strong) TeamRepo *repo;
@property (class, nonatomic, copy) NSArray<NSString *> *iconUrls;
@property (class, nonatomic, copy) NSArray<NSString *> *iconUrlsFun;

+ (void)registerCommonWithIcUrls:(NSArray<NSString *> *)icUrls;
+ (void)register;
+ (void)registerFun;

@end

NS_ASSUME_NONNULL_END
