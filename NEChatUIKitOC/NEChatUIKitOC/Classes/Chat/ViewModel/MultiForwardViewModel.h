// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <NIMSDK/NIMSDK.h>
#import <NEChatKit/NEChatKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MultiForwardViewModelDelegate <NSObject>
@optional
- (void)getMessageModel:(id<MessageModel>)model;
@end

/// 合并转发消息 ViewModel
@interface MultiForwardViewModel : NSObject

@property (nonatomic, weak, nullable) id<MultiForwardViewModelDelegate> delegate;
@property (nonatomic, strong) NSMutableArray<id<MessageModel>> *messages;

/// 加载数据
/// - Parameters:
///   - messageAttachmentUrl: 附件 URL
///   - filePath: 本地文件路径
///   - md5: 文件 MD5
///   - completion: 完成回调
- (void)loadData:(nullable NSString *)messageAttachmentUrl
        filePath:(NSString *)filePath
             md5:(nullable NSString *)md5
      completion:(void (^)(NSError *_Nullable error))completion;

/// 根据消息生成消息模型
/// - Parameter message: 消息
/// - Returns: 消息模型
- (id<MessageModel>)modelFromMessage:(V2NIMMessage *)message;

/// 下载文件
/// - Parameters:
///   - urlString: 文件 URL
///   - filePath: 本地文件路径
///   - progress: 进度回调
///   - completion: 完成回调
- (void)downLoad:(NSString *)urlString
        filePath:(NSString *)filePath
        progress:(nullable void (^)(NSUInteger progress))progress
      completion:(nullable void (^)(NSString *_Nullable path, NSError *_Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
