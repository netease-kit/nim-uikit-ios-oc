// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import "ChatViewModel.h"
#import "MediaSectionModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface TeamHistoryMessageViewModel : ChatViewModel

@property (nonatomic, strong) NSMutableArray<OperationItem *> *operationTypes;
@property (nonatomic, copy, nullable) NSString *pageToken;
@property (nonatomic, assign) BOOL allMessageShowTime;
@property (nonatomic, strong) UIColor *themeColor;

/// 媒体搜索结果（按时间分组）
@property (nonatomic, strong) NSMutableArray<MediaSectionModel *> *mediaMessageModels;

/// 获取快速搜索选项
- (void)getOperationTypes:(NSString *)conversationId;

/// 搜索历史消息
- (void)searchHistoryMessages:(V2NIMMessageSearchExParams *)params
                  firstSearch:(BOOL)firstSearch
                   completion:(void (^)(NSError *_Nullable error, NSInteger messageCount, BOOL hasMore))completion;

/// 搜索历史媒体消息（图片/视频/文件）
- (void)searchHistryMediaMessages:(BOOL)firstLoad
                       searchType:(MessageType)searchType
                       completion:(void (^)(NSError *_Nullable error, NSInteger messageCount, BOOL hasMore))completion;

/// 加载消息模型
- (void)loadMessageModel:(nullable V2NIMMessageSearchResult *)result params:(V2NIMMessageSearchExParams *)params;

@end

NS_ASSUME_NONNULL_END
