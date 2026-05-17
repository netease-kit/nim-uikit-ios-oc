// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>

@class NEAIRobotModel;

NS_ASSUME_NONNULL_BEGIN

@interface AIRobotViewModel : NSObject

/// Max robot count. Can be overridden by integration code.
@property (class, nonatomic, assign) NSInteger maxRobotCount;

/// Robot list data source.
@property (nonatomic, strong) NSMutableArray<NEAIRobotModel *> *datas;
/// Search result data source.
@property (nonatomic, strong) NSMutableArray<NEAIRobotModel *> *searchDatas;

/// Fetch all robots with automatic pagination.
- (void)getRobots:(void (^)(NSError *_Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
