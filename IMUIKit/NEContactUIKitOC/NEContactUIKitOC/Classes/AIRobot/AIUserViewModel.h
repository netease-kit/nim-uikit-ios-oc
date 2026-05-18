// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>

@class NEAIUserModel;

NS_ASSUME_NONNULL_BEGIN

@interface AIUserViewModel : NSObject

/// AI list data source.
@property (nonatomic, strong) NSMutableArray<NEAIUserModel *> *datas;
/// Search result data source.
@property (nonatomic, strong) NSMutableArray<NEAIUserModel *> *searchDatas;

/// Fetch AI users.
- (void)getAIUsers:(void (^)(NSError *_Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
