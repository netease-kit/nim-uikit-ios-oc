// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <NIMSDK/NIMSDK.h>
#import "AIChatCellModel.h"

NS_ASSUME_NONNULL_BEGIN

/// AI助聊 ViewModel
@interface AIChatViewModel : NSObject

@property (nonatomic, strong, nullable) NSArray<AIChatCellModel *> *aiChatData;

/// 加载 AI 助聊语句
/// - Parameters:
///   - messages: 上下文消息
///   - completion: 回调
- (void)loadData:(nullable NSArray<V2NIMMessage *> *)messages
      completion:(void (^)(NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
