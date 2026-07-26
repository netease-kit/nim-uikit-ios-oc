// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <NIMSDK/NIMSDK.h>
#import <NEChatKit/NEChatKitOC.h>
#import "NEPinMessageModel.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PinMessageViewModelDelegate <NSObject>
/// 表格刷新回调
/// - Parameter needLoad: 是否需要重新加载数据
- (void)tableViewReload:(BOOL)needLoad;
@end

/// 消息标记 ViewModel
@interface PinMessageViewModel : NSObject <NEChatListener>

@property (nonatomic, strong) NSMutableArray<NEPinMessageModel *> *items;
@property (nonatomic, weak, nullable) id<PinMessageViewModelDelegate> delegate;
@property (nonatomic, copy, nullable) NSString *conversationId;

/// 获取标记消息列表
/// - Parameters:
///   - conversationId: 会话 id
///   - completion: 完成回调
- (void)getPinitems:(NSString *)conversationId completion:(void (^)(NSError *_Nullable error))completion;

/// 加载标记消息更多信息（发送者信息）
/// - Parameters:
///   - items: 标记消息列表
///   - completion: 完成回调
- (void)loadMoreWithModel:(nullable NSArray<NEPinMessageModel *> *)items completion:(void (^)(void))completion;

/// 移除标记
/// - Parameters:
///   - message: 消息
///   - completion: 完成回调
- (void)removePinMessage:(V2NIMMessage *)message completion:(void (^)(NSError *_Nullable error))completion;

/// 获取请求大模型的内容
- (V2NIMAIModelCallContent *)getAIModelCallContent:(nullable NSString *)text type:(V2NIMAIModelCallContentType)type;

/// 发送文本消息
- (void)sendTextMessage:(NSString *)text
         conversationId:(NSString *)conversationId
             completion:(void (^)(V2NIMSendMessageResult *_Nullable result, NSError *_Nullable error, NSUInteger progress))completion;

/// 转发消息
- (void)forwardMessages:(V2NIMMessage *)message
         conversationIds:(NSArray<NSString *> *)conversationIds
                comment:(nullable NSString *)comment
             completion:(void (^)(V2NIMSendMessageResult *_Nullable result, NSError *_Nullable error, NSUInteger progress))completion;

/// 下载文件
- (void)downLoad:(NSString *)urlString
        filePath:(NSString *)filePath
        progress:(nullable void (^)(NSUInteger progress))progress
      completion:(nullable void (^)(NSString *_Nullable path, NSError *_Nullable error))completion;

/// 获取听筒模式
- (BOOL)getHandSetEnable;

@end

NS_ASSUME_NONNULL_END
