// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <NIMSDK/NIMSDK.h>

NS_ASSUME_NONNULL_BEGIN

@interface CreateAIRobotViewModel : NSObject

/// Robot nickname.
@property (nonatomic, copy) NSString *name;
/// Robot accid.
@property (nonatomic, copy) NSString *accid;
/// Local avatar path.
@property (nonatomic, copy, nullable) NSString *avatarLocalPath;
/// The created bot instance for follow-up navigation.
@property (nonatomic, strong, nullable) V2NIMUserAIBot *createdBot;

/// Query the latest bot after editing.
- (void)fetchUpdatedBot:(NSString *)accid
             completion:(void (^)(V2NIMUserAIBot *_Nullable bot))completion;

/// Create a robot.
- (void)createRobot:(void (^)(NSError *_Nullable error))completion;

/// Update a robot.
- (void)updateRobot:(NSString *)accid
         completion:(void (^)(NSError *_Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
