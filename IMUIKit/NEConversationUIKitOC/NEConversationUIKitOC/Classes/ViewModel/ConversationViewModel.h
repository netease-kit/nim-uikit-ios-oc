// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.
//
// ConversationViewModel.h
// 统一会话 ViewModel — 对齐 Swift ConversationViewModel / LocalConversationViewModel
// 通过 id<NEConversationDataSource> 支持 Cloud 和 Local 两种模式

#import <Foundation/Foundation.h>
#import "NEConversationDataSource.h"

@class NEConversationListModel;
@class NEAIUserModel;
@class V2NIMTeam;
@class V2NIMFriend;
@class V2NIMError;

NS_ASSUME_NONNULL_BEGIN

#pragma mark - ConversationViewModelDelegate

/// ViewModel → ViewController 回调协议
@protocol ConversationViewModelDelegate <NSObject>
@optional
- (void)reloadData;
- (void)reloadTableView;
/// 底部加载更多状态变更
- (void)loadMoreStateChange:(BOOL)finish;
@end

/// 分页回调
typedef void (^ConversationCallBack)(NSError * _Nullable error, NSNumber * _Nullable finished);

#pragma mark - ConversationViewModel

@interface ConversationViewModel : NSObject <NEConversationDataSourceListener>

/// ViewController 代理
@property (nonatomic, weak, nullable) id<ConversationViewModelDelegate> delegate;

/// 数据源（Cloud / Local），在 init 时注入
@property (nonatomic, strong, readonly) id<NEConversationDataSource> dataSource;

/// 会话列表起始索引（统一 int64_t）
@property (nonatomic, assign) int64_t offset;

/// 会话列表分页大小
@property (nonatomic, assign) NSInteger page;

/// 会话列表（UI 层直接绑定）
@property (nonatomic, strong, readonly) NSMutableArray<NEConversationListModel *> *conversationListData;

/// 顶部置顶数字人列表
@property (nonatomic, strong, readonly) NSMutableArray<NEAIUserModel *> *aiUserListData;

/// 所有会话数据记录 {conversationId: model}
@property (nonatomic, strong, readonly) NSMutableDictionary<NSString *, NEConversationListModel *> *conversationDic;

/// 是否同步完成
@property (nonatomic, assign) BOOL syncFinished;

/// 单聊在线状态记录 {conversationId: @YES/@NO}
@property (nonatomic, strong, readonly) NSMutableDictionary<NSString *, NSNumber *> *onlineStatusDic;

#pragma mark - 初始化

/// 使用指定数据源初始化
/// @param dataSource Cloud 或 Local DataSource
- (instancetype)initWithDataSource:(id<NEConversationDataSource>)dataSource;

/// 便捷初始化 — Cloud 模式
+ (instancetype)cloudViewModel;

/// 便捷初始化 — Local 模式
+ (instancetype)localViewModel;

#pragma mark - 数据获取

/// 分页获取会话列表
- (void)getConversationListByPage:(ConversationCallBack)completion;

/// 拉取 AI 用户列表（对齐 Swift requestData）
- (void)getAIUserList;

/// 断网重连后重新获取数据
- (void)retrieveConversationDatas;

#pragma mark - 数据操作

/// 添加或更新会话
/// @param conversationId 会话 ID
/// @param isAdd 是否为新增（YES: 插入排序，NO: 追加到末尾）
- (void)addOrUpdateConversationById:(NSString *)conversationId isAdd:(BOOL)isAdd;

/// 按排序权重插入
- (void)compareToInsert:(NEConversationListModel *)model;

/// 删除会话
- (void)deleteConversation:(NSString *)conversationId completion:(void (^)(NSError * _Nullable))completion;

/// 添加置顶
- (void)addStickTop:(NSString *)conversationId completion:(void (^)(NSError * _Nullable))completion;

/// 取消置顶
- (void)removeStickTop:(NSString *)conversationId completion:(void (^)(NSError * _Nullable))completion;

#pragma mark - 内部删除（群解散/退出场景）

- (void)didDeleteConversation:(NSString *)conversationId;

@end

NS_ASSUME_NONNULL_END
