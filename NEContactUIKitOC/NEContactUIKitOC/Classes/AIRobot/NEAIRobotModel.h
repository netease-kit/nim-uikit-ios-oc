// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <NIMSDK/NIMSDK.h>

NS_ASSUME_NONNULL_BEGIN

/// AI Bot display model.
@interface NEAIRobotModel : NSObject

/// Robot user info.
@property (nonatomic, strong, nullable) V2NIMUserAIBot *bot;

@end

NS_ASSUME_NONNULL_END
