// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <NIMSDK/NIMSDK.h>

NS_ASSUME_NONNULL_BEGIN

@class AIChatCellModel;

@interface NECommonResult : NSObject
@property (nonatomic, assign) NSInteger code;
@property (nonatomic, copy, nullable) NSDictionary<NSString *, id> *originData;
@end

@interface AIChatDataLoader : NSObject
+ (void)loadData:(nullable NSArray<V2NIMMessage *> *)messages
      completion:(void (^)(NSArray<AIChatCellModel *> *_Nullable models,
                           NSError *_Nullable error))completion;
+ (nullable V2NIMMessage *)getLastTextMessage:(nullable NSArray<V2NIMMessage *> *)messages;
@end

NS_ASSUME_NONNULL_END
