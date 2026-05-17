// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <NIMSDK/NIMSDK.h>

NS_ASSUME_NONNULL_BEGIN

@interface TeamDetailViewModel : NSObject

- (void)applyJoinTeam:(NSString *)teamId completion:(void (^)(V2NIMTeam * _Nullable team, NSError * _Nullable error))completion;
- (void)getTeamInfo:(NSString *)teamId completion:(void (^)(V2NIMTeam * _Nullable team, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
