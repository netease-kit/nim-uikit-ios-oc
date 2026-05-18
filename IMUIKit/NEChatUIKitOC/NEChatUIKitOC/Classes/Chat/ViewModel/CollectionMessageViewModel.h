// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <NIMSDK/NIMSDK.h>
#import <NEChatKitOC/NEChatKitOC.h>
#import "CollectionMessageModel.h"

NS_ASSUME_NONNULL_BEGIN

/// 收藏消息 ViewModel
@interface CollectionMessageViewModel : NSObject

@property (nonatomic, strong) NSMutableArray<CollectionMessageModel *> *collectionDatas;
/// 记录音频下载，防止重复下载
@property (nonatomic, strong) NSMutableSet<NSString *> *audioDownloadSet;
/// 记录最后点击的音频消息
@property (nonatomic, copy, nullable) NSString *lastClickAuidoMessageId;
/// 每页大小限制
@property (nonatomic, assign) NSInteger pageSize;

/// 加载收藏数据
/// - Parameter completion: 完成回调
- (void)loadData:(void (^)(NSError *_Nullable error, BOOL noMore))completion;

/// 反序列化收藏消息
/// - Parameter collections: 收藏内容列表
/// - Returns: 收藏消息模型列表
- (NSArray<CollectionMessageModel *> *)parseMessage:(NSArray<V2NIMCollection *> *)collections;

/// 获取请求大模型内容
- (V2NIMAIModelCallContent *)getAIModelCallContent:(nullable NSString *)text type:(V2NIMAIModelCallContentType)type;

/// 发送文本消息
- (void)sendTextMessage:(NSString *)text
         conversationId:(NSString *)conversationId
             completion:(void (^)(V2NIMSendMessageResult *_Nullable result, NSError *_Nullable error, NSUInteger progress))completion;

/// 转发收藏消息
- (void)forwardCollectionMessages:(V2NIMMessage *)message
                   conversationIds:(NSArray<NSString *> *)conversationIds
                           comment:(nullable NSString *)comment
                        completion:(void (^)(V2NIMSendMessageResult *_Nullable result, NSError *_Nullable error, NSUInteger progress))completion;

/// 下载文件
- (void)downloadFile:(NSString *)urlString
            filePath:(NSString *)filePath
            progress:(nullable void (^)(NSUInteger progress))progress
          completion:(nullable void (^)(NSString *_Nullable path, NSError *_Nullable error))completion;

/// 删除收藏
- (void)removeCollection:(V2NIMCollection *)collection completion:(void (^)(NSError *_Nullable error))completion;

/// 获取听筒模式
- (BOOL)getHandSetEnable;

@end

NS_ASSUME_NONNULL_END
