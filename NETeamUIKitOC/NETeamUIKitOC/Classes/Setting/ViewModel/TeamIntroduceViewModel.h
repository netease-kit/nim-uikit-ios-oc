// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <NIMSDK/NIMSDK.h>

@class TeamRepo;

NS_ASSUME_NONNULL_BEGIN

@interface TeamIntroduceViewModel : NSObject

@property (nonatomic, strong, readonly) TeamRepo *teamRepo;
@property (nonatomic, strong, nullable) V2NIMTeamMember *currentTeamMember;

- (void)getCurrentUserTeamMember:(nullable NSString *)teamId completion:(void (^)(NSError * _Nullable error))completion;
- (void)getCurrentUserTeamMember:(nullable NSString *)teamId :(void (^)(NSError * _Nullable error))completion;
- (void)updateTeamIntroduce:(NSString *)teamId introduce:(NSString *)introduce completion:(void (^)(NSError * _Nullable error))completion;
- (void)updateTeamIntroduce:(NSString *)teamId :(NSString *)introduce :(void (^)(NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
