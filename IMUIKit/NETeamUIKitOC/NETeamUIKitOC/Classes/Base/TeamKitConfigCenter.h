// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <NIMSDK/NIMSDK.h>

NS_ASSUME_NONNULL_BEGIN

@interface TeamKitConfigCenter : NSObject

+ (instancetype)shared;

@property (nonatomic, assign) V2NIMTeamAgreeMode teamAgreeMode;
@property (nonatomic, assign) V2NIMTeamJoinMode teamJoinMode;

@end

NS_ASSUME_NONNULL_END
