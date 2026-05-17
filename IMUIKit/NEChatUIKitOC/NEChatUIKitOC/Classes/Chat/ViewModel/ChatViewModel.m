// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "ChatViewModel.h"
#import <AVFoundation/AVFoundation.h>
#import <NEChatKitOC/NEChatKitOC.h>
#import <NEChatKitOC/NECoreIM2KitOC.h>
#import <NEChatKitOC/NECustomUtils.h>
#import <NEChatKitOC/NECommonKitOC.h>
#import <NECommonUIKitOC/NECommonUIConstant.h>
#import <NIMSDK/NIMSDK.h>
#import "NEChatUIConstant.h"
#import "ChatMessageHelper.h"
#import "MessageContentModel.h"
#import "MessageAudioModel.h"
#import "MessageRichTextModel.h"
#import "MessageTipsModel.h"
#import "MessageUtils.h"
#import "ChatDeduplicationHelper.h"
#import "NotificationMessageUtils.h"
#import "OperationItem+NEChatUIKit.h"
#import "ReplyMessageUtil.h"
#import <NEChatKitOC/NEPathUtils.h>

static NSString *const TAG = @"ChatViewModel";
extern NSString *const yxAtMsg;

@interface ChatViewModel ()
@property (nonatomic, copy) NSString *conversationId;
@property (nonatomic, strong, nullable, getter=chatNewMsg) V2NIMMessage *newMsg;
@property (nonatomic, strong, nullable) V2NIMMessage *oldMsg;
@property (nonatomic, assign) NSInteger loadDataRequestId;
@property (nonatomic, strong) NSMutableDictionary<NSString *, V2NIMMessage *> *pendingSendSuccessMessages;

- (BOOL)isCurrentConversationMessage:(nullable V2NIMMessage *)message;
- (BOOL)hasCurrentMessageWithClientId:(nullable NSString *)messageClientId;
- (BOOL)canCachePendingSendSuccessMessage:(nullable V2NIMMessage *)message;
- (nullable V2NIMMessage *)pendingSendSuccessMessageForClientId:(nullable NSString *)messageClientId;
- (void)cachePendingSendSuccessMessage:(nullable V2NIMMessage *)message;
- (void)removePendingSendSuccessMessageWithClientId:(nullable NSString *)messageClientId;
- (BOOL)isSameMessage:(nullable V2NIMMessage *)message asMessage:(nullable V2NIMMessage *)target;
- (BOOL)isSameSendingMessage:(nullable V2NIMMessage *)message asMessage:(nullable V2NIMMessage *)target;
- (NSInteger)indexOfFallbackSendingMessageForSendResult:(nullable V2NIMMessage *)message;
- (BOOL)isMessage:(nullable V2NIMMessage *)message matchedWithRefer:(nullable V2NIMMessageRefer *)messageRefer;
- (BOOL)isCurrentLoadDataRequest:(NSInteger)requestId;
- (NSInteger)indexOfMessage:(nullable V2NIMMessage *)message;
- (void)getHistoryMessage:(V2NIMQueryDirection)order
                  message:(nullable V2NIMMessage *)message
        loadDataRequestId:(NSInteger)requestId
               completion:(void (^)(NSError *_Nullable error, NSInteger count, NSArray<V2NIMMessage *> *messages))completion;
- (void)getHistoryMessage:(V2NIMQueryDirection)order
                  message:(nullable V2NIMMessage *)message
                    limit:(NSInteger)limit
        loadDataRequestId:(NSInteger)requestId
               completion:(void (^)(NSError *_Nullable error, NSInteger count, NSArray<V2NIMMessage *> *messages))completion;
- (void)loadMoreWithMessage:(NSArray<V2NIMMessage *> *)messageArray
               notifyReload:(BOOL)notifyReload
          loadDataRequestId:(NSInteger)requestId
                 completion:(nullable void (^)(void))completion;
- (void)loadMoreWithMessage:(NSArray<V2NIMMessage *> *)messageArray
               notifyReload:(BOOL)notifyReload
                 completion:(nullable void (^)(void))completion;
@end

@implementation ChatViewModel

- (instancetype)init {
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithConversationId:(NSString *)conversationId {
    [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s, conversationId:%@", __FUNCTION__, conversationId]];
    self = [super init];
    if (self) {
        [ChatRepo setConversationId:conversationId];
        [ChatRepo setSessionId:[V2NIMConversationIdUtil conversationTargetId:conversationId] ?: @""];
        _conversationId = conversationId ?: @"";
        _anchor = nil;
        [self commonInit];
        [self addListener];
        [self getAIUserList];
    }
    return self;
}

- (instancetype)initWithConversationId:(NSString *)conversationId anchor:(nullable V2NIMMessage *)anchor {
    [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s, conversationId:%@", __FUNCTION__, conversationId]];
    self = [super init];
    if (self) {
        [ChatRepo setConversationId:conversationId];
        [ChatRepo setSessionId:[V2NIMConversationIdUtil conversationTargetId:conversationId] ?: @""];
        _conversationId = conversationId ?: @"";
        _anchor = anchor;
        [self commonInit];
        if (anchor != nil) {
            _isHistoryChat = YES;
        }
        [self addListener];
        [self getAIUserList];
    }
    return self;
}

- (void)setAnchor:(nullable V2NIMMessage *)anchor {
    if ([self isSameMessage:_anchor asMessage:anchor]) {
        _anchor = anchor;
        return;
    }
    _anchor = anchor;
    self.loadDataRequestId += 1;
}

- (void)commonInit {
    _messages = [NSMutableArray array];
    _messageClientIds = [NSMutableArray array];
    _selectedMessages = [NSMutableArray array];
    _deletingMsgDic = [NSMutableSet set];
    _pendingSendSuccessMessages = [NSMutableDictionary dictionary];
    _messagPageNum = 100;
    _aiMessagNum = 30;
    _aiUserRequestSuccess = 200;
    _translationLanguageRequestId = @"";
    _networkBroken = NO;
    _isReplying = NO;
    _isHistoryChat = NO;
    if (!_conversationId) {
        _conversationId = @"";
    }
}

- (void)setSelectedMessages:(NSMutableArray<V2NIMMessage *> *)selectedMessages {
    _selectedMessages = selectedMessages;
    if ([self.delegate respondsToSelector:@selector(selectedMessagesChanged:)]) {
        [self.delegate selectedMessagesChanged:selectedMessages.count];
    }
}

- (void)dealloc {
    [[ChatRepo shared] removeChatListener:self];
    [[ChatRepo shared] removeMessageSendListener:self];
    if ([IMKitConfigCenter shared].enableAIUser) {
        [[AIRepo shared] removeAIListener:self];
    }
}

#pragma mark - Public Methods

- (void)addListener {
    [[ChatRepo shared] addChatListener:self];
    [[ChatRepo shared] addMessageSendListener:self];
    if ([IMKitConfigCenter shared].enableAIUser) {
        [[AIRepo shared] addAIListener:self];
    }
}

- (void)getAIUserList {
    if ([IMKitConfigCenter shared].enableAIUser) {
        [[NEAIUserManager shared] getAIUserList];
    }
}

- (void)clearUnreadCount {
    if ([NIMSDK sharedSDK].v2Option.enableV2CloudConversation == NO) {
        [[LocalConversationRepo shared] clearUnreadCountByIds:@[[ChatRepo conversationId]] completion:^(id result, NSError *error) {
            [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s error%@", __FUNCTION__, error.localizedDescription ?: @""]];
        }];
        [[LocalConversationRepo shared] markConversationRead:[ChatRepo conversationId] completion:^(id result, NSError *error) {
            [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s mark conversation read error: %@", __FUNCTION__, error.localizedDescription ?: @""]];
        }];
        return;
    }
    [[ConversationRepo shared] clearUnreadCountByIds:@[[ChatRepo conversationId]] completion:^(id result, NSError *error) {
        [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s error%@", __FUNCTION__, error.localizedDescription ?: @""]];
    }];
    [[ConversationRepo shared] markConversationRead:[ChatRepo conversationId] completion:^(id result, NSError *error) {
        [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s mark conversation read error: %@", __FUNCTION__, error.localizedDescription ?: @""]];
    }];
}

- (void)loadData:(void (^)(NSError *_Nullable, NSInteger, NSInteger, NSInteger))completion {
    [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s", __FUNCTION__]];

    NSInteger requestId = ++self.loadDataRequestId;
    V2NIMMessage *requestAnchor = self.anchor;
    if (requestAnchor == nil) {
        [self.messages removeAllObjects];
        [self.delegate tableViewReload];
        self.isHistoryChat = NO;

        __weak typeof(self) weakSelf = self;
        [self getHistoryMessage:V2NIMQueryDirectionQUERY_DIRECTION_DESC message:nil loadDataRequestId:requestId completion:^(NSError *error, NSInteger count, NSArray<V2NIMMessage *> *msgs) {
            if (![weakSelf isCurrentLoadDataRequest:requestId]) {
                return;
            }
            [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"CALLBACK getMessageList %@", error.localizedDescription ?: @"no error"]];
            NSMutableArray<V2NIMMessage *> *loadMessages = [NSMutableArray arrayWithArray:msgs ?: @[]];
            void (^finishLoad)(NSError *_Nullable, NSInteger) = ^(NSError *finishError, NSInteger finishCount) {
                if (![weakSelf isCurrentLoadDataRequest:requestId]) {
                    return;
                }
                completion(finishError, finishCount, 0, 0);
                if ([weakSelf isCurrentLoadDataRequest:requestId]) {
                    [weakSelf loadMoreWithMessage:loadMessages notifyReload:YES loadDataRequestId:requestId completion:nil];
                }
            };

            if (error || msgs.count <= 0 || count >= weakSelf.messagPageNum || weakSelf.oldMsg == nil) {
                finishLoad(error, count);
                return;
            }

            NSInteger remainLimit = weakSelf.messagPageNum - count;
            if (remainLimit <= 0) {
                finishLoad(error, count);
                return;
            }

            V2NIMMessage *oldestMessage = weakSelf.oldMsg;
            [weakSelf getHistoryMessage:V2NIMQueryDirectionQUERY_DIRECTION_DESC message:oldestMessage limit:remainLimit loadDataRequestId:requestId completion:^(NSError *moreError, NSInteger moreCount, NSArray<V2NIMMessage *> *moreMsgs) {
                if (![weakSelf isCurrentLoadDataRequest:requestId]) {
                    return;
                }
                if (moreMsgs.count > 0) {
                    [loadMessages addObjectsFromArray:moreMsgs];
                }
                finishLoad(error ?: moreError, count + moreCount);
            }];
        }];
    } else {
        self.isHistoryChat = YES;
        self.newMsg = requestAnchor;
        self.oldMsg = requestAnchor;

        dispatch_group_t group = dispatch_group_create();
        __block NSInteger moreEnd = 0;
        __block NSInteger newEnd = 0;
        __block NSInteger anchorIndex = 0;
        __block NSMutableArray<V2NIMMessage *> *newDatas = [NSMutableArray array];
        __block NSMutableArray<V2NIMMessage *> *loadMessages = [NSMutableArray array];
        __block NSError *err = nil;
        __block BOOL hasLoad = NO;

        for (NSInteger i = 0; i < self.messages.count; i++) {
            id<MessageModel> model = self.messages[i];
            if ([self isSameMessage:model.message asMessage:requestAnchor]) {
                hasLoad = YES;
                anchorIndex = i;
                break;
            }
        }

        if (!hasLoad) {
            [self.messages removeAllObjects];
            [self.delegate tableViewReload];

            __weak typeof(self) weakSelf = self;
            dispatch_group_enter(group);
            [self getHistoryMessage:V2NIMQueryDirectionQUERY_DIRECTION_DESC message:requestAnchor loadDataRequestId:requestId completion:^(NSError *error, NSInteger value, NSArray<V2NIMMessage *> *msgs) {
                if (![weakSelf isCurrentLoadDataRequest:requestId]) {
                    dispatch_group_leave(group);
                    return;
                }
                moreEnd = value;
                if (error) err = error;
                anchorIndex = msgs.count;
                [loadMessages addObjectsFromArray:msgs];

                dispatch_group_enter(group);
                if (requestAnchor) {
                    [loadMessages addObject:requestAnchor];
                    [weakSelf modelFromMessage:requestAnchor completion:^(id<MessageModel> model) {
                        if ([weakSelf isCurrentLoadDataRequest:requestId]) {
                            NSInteger index = [weakSelf insertToMessages:model];
                            if (index >= 0) {
                                anchorIndex = index;
                            }
                        }
                        dispatch_group_leave(group);
                    }];
                }

                dispatch_group_enter(group);
                [weakSelf getHistoryMessage:V2NIMQueryDirectionQUERY_DIRECTION_ASC message:requestAnchor loadDataRequestId:requestId completion:^(NSError *error2, NSInteger value2, NSArray<V2NIMMessage *> *msgs2) {
                    if (![weakSelf isCurrentLoadDataRequest:requestId]) {
                        dispatch_group_leave(group);
                        return;
                    }
                    [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"CALLBACK pullRemoteRefresh %@", error2.localizedDescription ?: @"no error"]];
                    newEnd = value2;
                    if (err == nil) err = error2;
                    [newDatas addObjectsFromArray:msgs2];
                    [loadMessages addObjectsFromArray:newDatas];
                    dispatch_group_leave(group);
                }];
                dispatch_group_leave(group);
            }];
        }

        __weak typeof(self) weakSelf = self;
        dispatch_group_notify(group, dispatch_get_main_queue(), ^{
            if (![weakSelf isCurrentLoadDataRequest:requestId]) {
                return;
            }
            NSInteger currentAnchorIndex = [weakSelf indexOfMessage:requestAnchor];
            if (currentAnchorIndex != NSNotFound) {
                anchorIndex = currentAnchorIndex;
            }
            completion(err, moreEnd, newEnd, anchorIndex);

            if (loadMessages.count > 0) {
                [weakSelf loadMoreWithMessage:loadMessages notifyReload:YES loadDataRequestId:requestId completion:nil];
            }
        });
    }
}

- (void)loadReply:(id<MessageModel> )model completion:(void (^)(void))completion {
    if (model.replyedModel != nil &&
        (model.replyedModel.message.messageServerId == nil || model.replyedModel.message.messageServerId.length == 0) &&
        model.message != nil) {
        [self getReplyMessage:model.message completion:^(id<MessageModel> replyedModel) {
            if ([replyedModel isKindOfClass:[MessageContentModel class]]) {
                NSString *replyText = [ReplyMessageUtil textForReplyModel:(MessageContentModel *)replyedModel];
                if (![model.replyText isEqualToString:replyText]) {
                    model.replyedModel = replyedModel;
                } else {
                    model.replyText = chatLocalizable(@"message_not_found");
                }
            } else {
                model.replyText = chatLocalizable(@"message_not_found");
            }
            completion();
        }];
    } else {
        completion();
    }
}

- (BOOL)isSameMessage:(nullable V2NIMMessage *)message asMessage:(nullable V2NIMMessage *)target {
    if (message == nil || target == nil) {
        return NO;
    }
    if (message == target) {
        return YES;
    }
    if (message.messageClientId.length > 0 &&
        [message.messageClientId isEqualToString:target.messageClientId]) {
        return YES;
    }
    if (message.messageServerId.length > 0 &&
        [message.messageServerId isEqualToString:target.messageServerId]) {
        return YES;
    }
    return NO;
}

- (BOOL)isSameSendingMessage:(nullable V2NIMMessage *)message asMessage:(nullable V2NIMMessage *)target {
    if (message == nil || target == nil) {
        return NO;
    }
    if (message == target) {
        return YES;
    }
    if (message.messageClientId.length > 0 &&
        [message.messageClientId isEqualToString:target.messageClientId]) {
        return YES;
    }
    return NO;
}

- (BOOL)isSendResultMessage:(nullable V2NIMMessage *)message matchedWithFallbackSendingMessage:(nullable V2NIMMessage *)target {
    if (message == nil || target == nil) {
        return NO;
    }
    if (target.sendingState != V2NIM_MESSAGE_SENDING_STATE_SENDING) {
        return NO;
    }
    if (![self isCurrentConversationMessage:target]) {
        return NO;
    }
    if (![ChatMessageHelper isSelf:target] || ![ChatMessageHelper isSelf:message]) {
        return NO;
    }
    if (message.conversationId.length > 0 &&
        target.conversationId.length > 0 &&
        ![message.conversationId isEqualToString:target.conversationId]) {
        return NO;
    }
    if (message.messageType != target.messageType) {
        return NO;
    }
    if (message.createTime > 0 && target.createTime > 0) {
        NSTimeInterval timeDiff = message.createTime - target.createTime;
        if (timeDiff < 0) {
            timeDiff = -timeDiff;
        }
        if (timeDiff > 10) {
            return NO;
        }
    }

    if (message.messageType == V2NIM_MESSAGE_TYPE_TEXT) {
        return message.text.length == 0 ||
            target.text.length == 0 ||
            [message.text isEqualToString:target.text];
    }
    if (message.text.length > 0 &&
        target.text.length > 0 &&
        ![message.text isEqualToString:target.text]) {
        return NO;
    }

    return YES;
}

- (NSInteger)indexOfFallbackSendingMessageForSendResult:(nullable V2NIMMessage *)message {
    NSInteger matchedIndex = NSNotFound;
    NSInteger count = (NSInteger)self.messages.count;
    for (NSInteger i = count - 1; i >= 0; i--) {
        id<MessageModel> model = self.messages[i];
        if (![self isSendResultMessage:message matchedWithFallbackSendingMessage:model.message]) {
            continue;
        }
        if (matchedIndex != NSNotFound) {
            return NSNotFound;
        }
        matchedIndex = i;
    }
    return matchedIndex;
}

- (BOOL)isMessage:(nullable V2NIMMessage *)message matchedWithRefer:(nullable V2NIMMessageRefer *)messageRefer {
    if (message == nil || messageRefer == nil) {
        return NO;
    }
    if (messageRefer.conversationId.length > 0 &&
        message.conversationId.length > 0 &&
        ![message.conversationId isEqualToString:messageRefer.conversationId]) {
        return NO;
    }
    if (messageRefer.messageClientId.length > 0 &&
        [message.messageClientId isEqualToString:messageRefer.messageClientId]) {
        return YES;
    }
    if (messageRefer.messageServerId.length > 0 &&
        [message.messageServerId isEqualToString:messageRefer.messageServerId]) {
        return YES;
    }
    return NO;
}

- (BOOL)isCurrentConversationMessage:(nullable V2NIMMessage *)message {
    if (message == nil) {
        return NO;
    }
    if (message.conversationId.length > 0) {
        return [message.conversationId isEqualToString:self.conversationId];
    }
    return [self hasCurrentMessageWithClientId:message.messageClientId];
}

- (BOOL)hasCurrentMessageWithClientId:(nullable NSString *)messageClientId {
    if (messageClientId.length <= 0) {
        return NO;
    }
    for (id<MessageModel> model in [self.messages copy]) {
        if ([model.message.messageClientId isEqualToString:messageClientId]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)canCachePendingSendSuccessMessage:(nullable V2NIMMessage *)message {
    if (message.messageClientId.length <= 0) {
        return NO;
    }
    if (message.conversationId.length > 0) {
        return [message.conversationId isEqualToString:self.conversationId];
    }
    return [ChatMessageHelper isSelf:message];
}

- (nullable V2NIMMessage *)pendingSendSuccessMessageForClientId:(nullable NSString *)messageClientId {
    if (messageClientId.length <= 0) {
        return nil;
    }
    return self.pendingSendSuccessMessages[messageClientId];
}

- (void)cachePendingSendSuccessMessage:(nullable V2NIMMessage *)message {
    if (![self canCachePendingSendSuccessMessage:message]) {
        return;
    }
    self.pendingSendSuccessMessages[message.messageClientId] = message;
}

- (void)removePendingSendSuccessMessageWithClientId:(nullable NSString *)messageClientId {
    if (messageClientId.length <= 0) {
        return;
    }
    [self.pendingSendSuccessMessages removeObjectForKey:messageClientId];
}

- (BOOL)isCurrentLoadDataRequest:(NSInteger)requestId {
    return requestId == self.loadDataRequestId;
}

- (NSInteger)indexOfMessage:(nullable V2NIMMessage *)message {
    if (!message) {
        return NSNotFound;
    }
    for (NSInteger i = 0; i < self.messages.count; i++) {
        id<MessageModel> model = self.messages[i];
        if ([self isSameMessage:model.message asMessage:message]) {
            return i;
        }
    }
    return NSNotFound;
}

- (void)loadMoreWithMessage:(NSArray<V2NIMMessage *> *)messageArray {
    [self loadMoreWithMessage:messageArray notifyReload:YES completion:nil];
}

- (void)loadMoreWithMessage:(NSArray<V2NIMMessage *> *)messageArray
               notifyReload:(BOOL)notifyReload
                 completion:(nullable void (^)(void))completion {
    [self loadMoreWithMessage:messageArray notifyReload:notifyReload loadDataRequestId:0 completion:completion];
}

- (void)loadMoreWithMessage:(NSArray<V2NIMMessage *> *)messageArray
               notifyReload:(BOOL)notifyReload
          loadDataRequestId:(NSInteger)requestId
                 completion:(nullable void (^)(void))completion {
    [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    dispatch_group_t group = dispatch_group_create();

    __weak typeof(self) weakSelf = self;
    dispatch_group_enter(group);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *conversationId = [ChatRepo conversationId];

        dispatch_group_enter(group);
        [weakSelf getMessageReceipts:messageArray completion:^(NSArray<NSIndexPath *> *reloadIndexs, NSError *error) {
            dispatch_group_enter(group);
            [[ChatRepo shared] getPinnedMessageList:conversationId completion:^(NSArray *pinList, NSError *error) {
                NSMutableSet<NSString *> *userIds = [NSMutableSet set];
                for (id pin in pinList ?: @[]) {
                    if ([pin respondsToSelector:@selector(operatorId)]) {
                        [userIds addObject:[pin operatorId]];
                    }
                }
                NSArray<id<MessageModel> > *senderModels = [weakSelf.messages copy];
                for (id<MessageModel> model in senderModels) {
                    NSString *senderId = [ChatMessageHelper getSenderId:model.message];
                    if (senderId) [userIds addObject:senderId];
                }

                dispatch_group_enter(group);
                [weakSelf loadShowName:userIds.allObjects teamId:[ChatRepo sessionId] completion:^{
                    NSArray<id<MessageModel> > *models = [weakSelf.messages copy];
                    for (id<MessageModel> model in models) {
                        NSString *uid = [ChatMessageHelper getSenderId:model.message];
                        if (uid) {
                            NSString *fullName = [weakSelf getShowName:uid showAlias:YES];
                            NEUserWithFriend *userFriend = [ChatMessageHelper getUserFromCache:uid];
                            model.avatar = userFriend.user.avatar;
                            model.fullName = fullName;
                            model.shortName = [NEFriendUserCache getShortName:[userFriend showName:NO] ?: @""];
                        }
                        for (id pin in pinList ?: @[]) {
                            V2NIMMessageRefer *messageRefer = nil;
                            if ([pin respondsToSelector:@selector(messageRefer)]) {
                                messageRefer = [pin messageRefer];
                            }
                            if ([weakSelf isMessage:model.message matchedWithRefer:messageRefer]) {
                                model.isPined = YES;
                                if ([pin respondsToSelector:@selector(operatorId)]) {
                                    model.pinAccount = [pin operatorId];
                                    model.pinShowName = [weakSelf getShowName:[pin operatorId] showAlias:YES];
                                }
                                break;
                            }
                        }
                        dispatch_group_enter(group);
                        [weakSelf loadReply:model completion:^{
                            dispatch_group_leave(group);
                        }];
                    }
                    dispatch_group_leave(group);
                }];
                dispatch_group_leave(group);
            }];
            dispatch_group_leave(group);
        }];
        dispatch_group_leave(group);
    });

    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        if (requestId > 0 && ![weakSelf isCurrentLoadDataRequest:requestId]) {
            return;
        }
        if (notifyReload) {
            [weakSelf.delegate tableViewReload];
        }
        if (completion) {
            completion();
        }
    });

    [self downloadAudioFile:[self.messages copy]];
    [self loadTopMessage];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableSet<NSString *> *accids = [NSMutableSet set];
        NSArray<id<MessageModel> > *models = [weakSelf.messages copy];
        for (id<MessageModel> model in models) {
            if (model.message.messageType == V2NIM_MESSAGE_TYPE_NOTIFICATION) {
                V2NIMMessageNotificationAttachment *attach = (V2NIMMessageNotificationAttachment *)model.message.attachment;
                if ([attach.targetIds count] > 0) {
                    [accids addObjectsFromArray:attach.targetIds];
                }
            }
        }
        if (accids.count > 0) {
            [weakSelf loadShowName:accids.allObjects teamId:[ChatRepo sessionId] completion:^{
                NSArray<id<MessageModel> > *tipModels = [weakSelf.messages copy];
                for (id<MessageModel> model in tipModels) {
                    if ([model isKindOfClass:[MessageTipsModel class]]) {
                        [(MessageTipsModel *)model resetMessage:model.message];
                    }
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (requestId > 0 && ![weakSelf isCurrentLoadDataRequest:requestId]) {
                        return;
                    }
                    if (notifyReload) {
                        [weakSelf.delegate tableViewReload];
                    }
                });
            }];
        }
    });
}

- (void)updateMessageInfo:(nullable NSString *)accid {
    if (!accid) return;
    NSString *showName = [self getShowName:accid showAlias:YES];
    NSMutableArray<NSIndexPath *> *indexPaths = [NSMutableArray array];
    for (NSInteger i = 0; i < self.messages.count; i++) {
        id<MessageModel> model = self.messages[i];
        if ([[ChatMessageHelper getSenderId:model.message] isEqualToString:accid]) {
            NEUserWithFriend *user = [ChatMessageHelper getUserFromCache:accid];
            model.fullName = showName;
            model.avatar = user.user.avatar;
            model.shortName = [NEFriendUserCache getShortName:[user showName:NO] ?: @""];
            [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        }
        if (model.isPined && [model.pinAccount isEqualToString:accid]) {
            model.pinShowName = showName;
            [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        }
    }
    if ([accid isEqualToString:[ChatMessageHelper getSenderId:self.topMessage]]) {
        [self.delegate updateTopName:showName];
    }
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.delegate onLoadMoreWithMessage:indexPaths];
    });
}

- (id<MessageModel>)modelFromMessage:(V2NIMMessage *)message preservingModel:(nullable id<MessageModel>)oldModel {
    id<MessageModel> model = [self modelFromMessage:message];
    if (!oldModel) {
        return model;
    }

    model.shortName = oldModel.shortName;
    model.fullName = oldModel.fullName;
    model.avatar = oldModel.avatar;
    model.isPined = oldModel.isPined;
    model.pinAccount = oldModel.pinAccount;
    model.pinShowName = oldModel.pinShowName;
    model.readCount = oldModel.readCount;
    model.unreadCount = oldModel.unreadCount;
    model.showSelect = oldModel.showSelect;
    model.isSelected = oldModel.isSelected;
    model.replyedModel = oldModel.replyedModel;
    if (oldModel.isRevoked) {
        model.isRevoked = YES;
    }
    model.isReedit = oldModel.isReedit;
    model.revokeTime = oldModel.revokeTime;
    if (oldModel.inMultiForward) {
        model.inMultiForward = YES;
    }
    model.timeContent = oldModel.timeContent;
    return model;
}

- (NSInteger)insertToMessages:(id<MessageModel> )newModel {
    if (self.messages.count == 0) {
        [self.messages addObject:newModel];
        return 0;
    }
    double newTime = newModel.message.createTime;
    double lastTime = self.messages.lastObject.message.createTime;
    if (newTime >= lastTime) {
        [self.messages addObject:newModel];
        return self.messages.count - 1;
    }
    NSInteger index = -1;
    for (NSInteger i = 0; i < self.messages.count; i++) {
        if (newTime < self.messages[i].message.createTime) {
            [self.messages insertObject:newModel atIndex:i];
            index = i;
            break;
        }
    }
    return index;
}

- (void)getHistoryMessage:(V2NIMQueryDirection)order message:(nullable V2NIMMessage *)message completion:(void (^)(NSError *_Nullable, NSInteger, NSArray<V2NIMMessage *> *))completion {
    [self getHistoryMessage:order message:message loadDataRequestId:0 completion:completion];
}

- (void)getHistoryMessage:(V2NIMQueryDirection)order
                  message:(nullable V2NIMMessage *)message
        loadDataRequestId:(NSInteger)requestId
               completion:(void (^)(NSError *_Nullable, NSInteger, NSArray<V2NIMMessage *> *))completion {
    [self getHistoryMessage:order message:message limit:self.messagPageNum loadDataRequestId:requestId completion:completion];
}

- (void)getHistoryMessage:(V2NIMQueryDirection)order
                  message:(nullable V2NIMMessage *)message
                    limit:(NSInteger)limit
        loadDataRequestId:(NSInteger)requestId
               completion:(void (^)(NSError *_Nullable, NSInteger, NSArray<V2NIMMessage *> *))completion {
    V2NIMMessageListOption *opt = [[V2NIMMessageListOption alloc] init];
    opt.limit = limit;
    opt.anchorMessage = message;
    opt.conversationId = [ChatRepo conversationId];
    opt.direction = order;
    if (message) {
        if (order == V2NIMQueryDirectionQUERY_DIRECTION_DESC) {
            opt.endTime = message.createTime;
        } else {
            opt.beginTime = message.createTime;
        }
    }
    __weak typeof(self) weakSelf = self;
    [[ChatRepo shared] getMessageListWithOption:opt completion:^(NSArray<V2NIMMessage *> *msgs, NSError *error) {
        BOOL shouldApply = requestId <= 0 || [weakSelf isCurrentLoadDataRequest:requestId];
        if (!shouldApply) {
            completion(error, 0, @[]);
            return;
        }
        if (msgs.count > 0) {
            if (order == V2NIMQueryDirectionQUERY_DIRECTION_DESC) {
                weakSelf.oldMsg = msgs.lastObject;
            } else {
                weakSelf.newMsg = msgs.lastObject;
            }
            for (V2NIMMessage *msg in msgs) {
                if (msg.messageClientId) {
                    [weakSelf.messageClientIds addObject:msg.messageClientId];
                }
                if ([ChatMessageHelper isAISender:msg]) {
                    [weakSelf setErrorText:msg];
                }
                id<MessageModel> model = [weakSelf modelFromMessage:msg];
                BOOL exists = NO;
                NSArray<id<MessageModel> > *messageSnapshot = [weakSelf.messages copy];
                for (id<MessageModel> m in messageSnapshot) {
                    if ([m.message.messageClientId isEqualToString:model.message.messageClientId]) {
                        exists = YES; break;
                    }
                }
                if (!exists) {
                    [weakSelf insertToMessages:model];
                }
            }
            [weakSelf addTimeForHistoryMessage:YES];
            completion(error, msgs.count, msgs);
        } else {
            if (weakSelf.messages.count == 0 && [[NEAIUserManager shared] isAIUser:[ChatRepo sessionId]]) {
                NSString *welcomeText = [[NEAIUserManager shared] getWelcomeText:[ChatRepo sessionId]];
                if (welcomeText) {
                    [weakSelf insertTextMessage:welcomeText conversationId:[ChatRepo conversationId] senderId:[ChatRepo sessionId]];
                }
                completion(error, 1, @[]);
            } else {
                completion(error, 0, @[]);
            }
        }
    }];
}

- (void)dropDownRemoteRefresh:(void (^)(NSError *_Nullable, NSInteger, NSArray<V2NIMMessage *> *))completion {
    [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    if (self.oldMsg == nil) {
        BOOL found = NO;
        NSArray<id<MessageModel> > *messageSnapshot = [self.messages copy];
        for (id<MessageModel> msg in messageSnapshot) {
            if (msg.message) { self.oldMsg = msg.message; found = YES; break; }
        }
    } else {
        BOOL found = NO;
        NSArray<id<MessageModel> > *messageSnapshot = [self.messages copy];
        for (id<MessageModel> msg in messageSnapshot) {
            if ([msg.message.messageClientId isEqualToString:self.oldMsg.messageClientId]) { found = YES; break; }
        }
        if (!found) {
            self.oldMsg = nil;
            NSArray<id<MessageModel> > *messageSnapshot = [self.messages copy];
            for (id<MessageModel> msg in messageSnapshot) {
                if (msg.message) { self.oldMsg = msg.message; break; }
            }
        }
    }
    if (self.messages.count == 0) self.oldMsg = nil;

    __weak typeof(self) weakSelf = self;
    [self getHistoryMessage:V2NIMQueryDirectionQUERY_DIRECTION_DESC message:self.oldMsg completion:^(NSError *error, NSInteger count, NSArray<V2NIMMessage *> *msgs) {
        completion(error, count, msgs);
        if (count > 0) {
            [weakSelf loadMoreWithMessage:msgs];
        }
    }];
}

- (void)pullRemoteRefresh:(void (^)(NSError *_Nullable, NSInteger, NSArray<V2NIMMessage *> *))completion {
    [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    __weak typeof(self) weakSelf = self;
    [self getHistoryMessage:V2NIMQueryDirectionQUERY_DIRECTION_ASC message:self.newMsg completion:^(NSError *error, NSInteger count, NSArray<V2NIMMessage *> *msgs) {
        completion(error, count, msgs);
        [weakSelf loadMoreWithMessage:msgs];
    }];
}

- (void)downloadAudioFile:(NSArray<id<MessageModel> > *)models {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (id<MessageModel> model in models) {
            if (model.type == MessageTypeAudio) {
                V2NIMMessageAudioAttachment *audioAttach = (V2NIMMessageAudioAttachment *)model.message.attachment;
                NSString *path = audioAttach.path ?: [ChatMessageHelper createFilePath:model.message];
                if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
                    if (audioAttach.url) {
                        [weakSelf downLoad:audioAttach.url filePath:path progress:nil completion:^(NSString *p, NSError *error) {
                            if (!error) {
                                [NEALog infoLog:TAG desc:@"CALLBACK downLoad"];
                            }
                        }];
                    }
                }
            }
        }
    });
}

- (void)loadTopMessage {
    // 子类重写（P2P/Team 各有实现）
}

- (void)sendMessage:(V2NIMMessage *)message conversationId:(nullable NSString *)conversationId params:(nullable V2NIMSendMessageParams *)params completion:(void (^)(V2NIMMessage *_Nullable, NSError *_Nullable, NSUInteger))completion {
    [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s, text: %@", __FUNCTION__, message.text]];
    __weak typeof(self) weakSelf = self;
    [[ChatRepo shared] sendMessage:message conversationId:conversationId ?: [ChatRepo conversationId] params:params completion:^(V2NIMSendMessageResult *result, NSError *error, NSUInteger pro) {
        if ([IMKitConfigCenter shared].enableAntiSpamTipMessage) {
            [weakSelf checkAntiSpam:result];
        }
        completion(result.message ?: message, error, pro);
    }];
}

- (void)checkAntiSpam:(nullable V2NIMSendMessageResult *)result {
    if (result.antispamResult) {
        NSString *pattern = @"\\\\*\"label\\\\*\"\\s*:\\s*(\\d+)";
        NSArray *labels = [NECommonUtil extractLabelsWithRegex:result.antispamResult pattern:pattern];
        if (labels.count > 0) {
            NSInteger errorCode = [labels.firstObject integerValue];
            NSString *tipText = antispamResultCodeDic()[@(errorCode)];
            if (tipText) {
                if (result.message.createTime > 0) {
                    [self insertTipMessage:[NSString stringWithFormat:chatLocalizable(@"failed_message_reson"), tipText] createTime:@(result.message.createTime + 1) conversationId:nil senderId:nil];
                } else {
                    [self insertTipMessage:[NSString stringWithFormat:chatLocalizable(@"failed_message_reson"), tipText] createTime:nil conversationId:nil senderId:nil];
                }
            }
        }
    }
}

- (V2NIMAIModelCallContent *)getAIModelCallContent:(nullable NSString *)text type:(V2NIMAIModelCallContentType)type {
    V2NIMAIModelCallContent *content = [[V2NIMAIModelCallContent alloc] init];
    content.msg = text ?: @"";
    content.type = type;
    return content;
}

- (nullable NSArray<V2NIMAIModelCallMessage *> *)getAIMessages {
    if (![[NEAIUserManager shared] isAIUser:[ChatRepo sessionId]]) return nil;
    NSInteger startIdx = MAX(0, (NSInteger)self.messages.count - self.aiMessagNum);
    NSArray *messageModels = [self.messages subarrayWithRange:NSMakeRange(startIdx, self.messages.count - startIdx)];
    NSMutableArray *aiMessageModels = [NSMutableArray array];
    for (id<MessageModel> m in messageModels) {
        if (m.type == MessageTypeText || m.type == MessageTypeAIStreamText || m.type == MessageTypeRichText) {
            [aiMessageModels addObject:m];
        }
    }
    BOOL firstUserMessage = NO;
    NSMutableArray<V2NIMAIModelCallMessage *> *aiMessages = [NSMutableArray array];
    for (NSInteger i = 0; i < aiMessageModels.count; i++) {
        id<MessageModel> model = aiMessageModels[i];
        BOOL isUserMessage = (model.message.aiConfig == nil || model.message.aiConfig.aiStatus != V2NIM_MESSAGE_AI_STATUS_RESPONSE);
        if (isUserMessage) firstUserMessage = YES;
        if (!firstUserMessage) continue;

        V2NIMAIModelCallMessage *aiMessage = [[V2NIMAIModelCallMessage alloc] init];
        aiMessage.type = V2NIM_AI_MODEL_CONTENT_TYPE_TEXT;
        aiMessage.role = isUserMessage ? V2NIM_AI_MODEL_ROLE_TYPE_USER : V2NIM_AI_MODEL_ROLE_TYPE_ASSISTANT;

        if ((model.type == MessageTypeText || model.type == MessageTypeAIStreamText) && model.message.text.length > 0) {
            aiMessage.msg = model.message.text;
            [aiMessages addObject:aiMessage];
        } else if (model.type == MessageTypeRichText && [model isKindOfClass:[MessageRichTextModel class]]) {
            MessageRichTextModel *m = (MessageRichTextModel *)model;
            if (m.titleText.length > 0) {
                aiMessage.msg = [m.titleText stringByAppendingString:m.message.text ?: @""];
                [aiMessages addObject:aiMessage];
            }
        }
    }
    return aiMessages.count > 0 ? aiMessages : nil;
}

- (V2NIMSendMessageParams *)getSendMessageParams:(nullable NSString *)aiUserAccid message:(V2NIMMessage *)message {
    NSString *accid = aiUserAccid;
    BOOL needMessages = NO;
    if ([[NEAIUserManager shared] isAIUser:[ChatRepo sessionId]]) {
        accid = [ChatRepo sessionId];
        needMessages = YES;
    }
    V2NIMSendMessageParams *params = [[ChatRepo shared] getSendMessageParams];
    if (accid && [[NEAIUserManager shared] isAIUser:accid]) {
        V2NIMMessageAIConfigParams *aiConfig = [[V2NIMMessageAIConfigParams alloc] init];
        aiConfig.accountId = accid;
        aiConfig.aiStream = [IMKitConfigCenter shared].enableAIStream;
        if (message.messageType == V2NIM_MESSAGE_TYPE_TEXT && message.text) {
            aiConfig.content = [self getAIModelCallContent:message.text type:V2NIM_AI_MODEL_CONTENT_TYPE_TEXT];
            if (needMessages) aiConfig.messages = [self getAIMessages];
        }
        if (message.messageType == V2NIM_MESSAGE_TYPE_CUSTOM) {
            NSInteger type = [NECustomUtils typeOfCustomMessage:message.attachment];
            if (type == customRichTextType) {
                NSString *title = [NECustomUtils titleOfRichText:message.attachment] ?: @"";
                NSString *body = [NECustomUtils bodyOfRichText:message.attachment] ?: @"";
                NSString *text = [title stringByAppendingString:body];
                aiConfig.content = [self getAIModelCallContent:text type:V2NIM_AI_MODEL_CONTENT_TYPE_TEXT];
                if (needMessages) aiConfig.messages = [self getAIMessages];
            }
        }
        params.aiConfig = aiConfig;
    }
    return params;
}

- (V2NIMSendMessageParams *)getReplyMessageParams:(nullable NSString *)aiUserAccid replyMessage:(V2NIMMessage *)replyMessage message:(V2NIMMessage *)message {
    V2NIMSendMessageParams *params = [[ChatRepo shared] getSendMessageParams];
    if (aiUserAccid) {
        V2NIMMessageAIConfigParams *aiConfig = [[V2NIMMessageAIConfigParams alloc] init];
        aiConfig.accountId = aiUserAccid;
        aiConfig.aiStream = [IMKitConfigCenter shared].enableAIStream;
        if (replyMessage.messageType == V2NIM_MESSAGE_TYPE_TEXT) {
            V2NIMAIModelCallMessage *aiMessage = [[V2NIMAIModelCallMessage alloc] init];
            aiMessage.msg = replyMessage.text ?: @"";
            aiMessage.type = V2NIM_AI_MODEL_CONTENT_TYPE_TEXT;
            aiMessage.role = V2NIM_AI_MODEL_ROLE_TYPE_USER;
            aiConfig.messages = @[aiMessage];
        }
        if (replyMessage.messageType == V2NIM_MESSAGE_TYPE_CUSTOM) {
            NSInteger type = [NECustomUtils typeOfCustomMessage:replyMessage.attachment];
            if (type == customRichTextType) {
                NSString *title = [NECustomUtils titleOfRichText:replyMessage.attachment] ?: @"";
                NSString *body = [NECustomUtils bodyOfRichText:replyMessage.attachment] ?: @"";
                V2NIMAIModelCallMessage *aiMessage = [[V2NIMAIModelCallMessage alloc] init];
                aiMessage.msg = [title stringByAppendingString:body];
                aiMessage.type = V2NIM_AI_MODEL_CONTENT_TYPE_TEXT;
                aiMessage.role = V2NIM_AI_MODEL_ROLE_TYPE_USER;
                aiConfig.messages = @[aiMessage];
            }
        }
        aiConfig.content = [self getAIModelCallContent:message.text type:V2NIM_AI_MODEL_CONTENT_TYPE_TEXT];
        params.aiConfig = aiConfig;
    }
    return params;
}

- (V2NIMSendMessageParams *)getForwardMessageParams:(nullable NSString *)aiUserAccid forwardMessage:(V2NIMMessage *)forwardMessage {
    V2NIMSendMessageParams *params = [[ChatRepo shared] getSendMessageParams];
    if (aiUserAccid) {
        V2NIMMessageAIConfigParams *aiConfig = [[V2NIMMessageAIConfigParams alloc] init];
        aiConfig.accountId = aiUserAccid;
        aiConfig.aiStream = [IMKitConfigCenter shared].enableAIStream;
        if (forwardMessage.messageType == V2NIM_MESSAGE_TYPE_TEXT) {
            aiConfig.content = [self getAIModelCallContent:forwardMessage.text type:V2NIM_AI_MODEL_CONTENT_TYPE_TEXT];
        }
        if (forwardMessage.messageType == V2NIM_MESSAGE_TYPE_CUSTOM) {
            NSInteger type = [NECustomUtils typeOfCustomMessage:forwardMessage.attachment];
            if (type == customRichTextType) {
                NSString *title = [NECustomUtils titleOfRichText:forwardMessage.attachment] ?: @"";
                NSString *body = [NECustomUtils bodyOfRichText:forwardMessage.attachment] ?: @"";
                aiConfig.content = [self getAIModelCallContent:[title stringByAppendingString:body] type:V2NIM_AI_MODEL_CONTENT_TYPE_TEXT];
            }
        }
        params.aiConfig = aiConfig;
    }
    return params;
}

- (void)sendTextMessage:(NSString *)text conversationId:(nullable NSString *)conversationId remoteExt:(nullable NSDictionary *)remoteExt aiUserAccid:(nullable NSString *)aiUserAccid completion:(void (^)(V2NIMMessage *_Nullable, NSError *_Nullable))completion {
    [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s, text.count: %lu", __FUNCTION__, (unsigned long)text.length]];
    if (text.length <= 0) { completion(nil, nil); return; }
    V2NIMMessage *message = [MessageUtils textMessageWithText:text remoteExt:remoteExt];
    NSString *accid = aiUserAccid;
    if ([[NEAIUserManager shared] isAIUser:[ChatRepo sessionId]]) accid = [ChatRepo sessionId];
    V2NIMSendMessageParams *params = [self getSendMessageParams:accid message:message];
    [self sendMessage:message conversationId:conversationId params:params completion:^(V2NIMMessage *msg, NSError *error, NSUInteger pro) {
        completion(msg, error);
    }];
}

- (void)sendTextMessage:(NSString *)text remoteExt:(nullable NSDictionary *)remoteExt aiUserAccid:(nullable NSString *)aiUserAccid completion:(void (^)(V2NIMMessage *_Nullable, NSError *_Nullable))completion {
    [self sendTextMessage:text conversationId:nil remoteExt:remoteExt aiUserAccid:aiUserAccid completion:completion];
}

- (void)sendRichTextMessage:(V2NIMMessage *)message title:(nullable NSString *)title body:(nullable NSString *)body aiUserAccid:(nullable NSString *)aiUserAccid completion:(void (^)(V2NIMMessage *_Nullable, NSError *_Nullable))completion {
    [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    V2NIMSendMessageParams *params = [self getSendMessageParams:aiUserAccid message:message];
    [self sendMessage:message conversationId:[ChatRepo conversationId] params:params completion:^(V2NIMMessage *msg, NSError *error, NSUInteger pro) {
        completion(msg, error);
    }];
}

- (void)sendAudioMessage:(NSString *)filePath conversationId:(nullable NSString *)conversationId completion:(void (^)(NSError *_Nullable))completion {
    if ([[ChatDeduplicationHelper instance] isRecordAudioSended:filePath]) {
        [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s, duplicate send audio", __FUNCTION__]];
        return;
    }
    [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s, filePath: %@", __FUNCTION__, filePath]];
    V2NIMMessage *message = [MessageUtils audioMessageWithFilePath:filePath name:nil sceneName:nil duration:0];
    V2NIMSendMessageParams *params = [self getSendMessageParams:nil message:message];
    [self sendMessage:message conversationId:conversationId params:params completion:^(V2NIMMessage *msg, NSError *error, NSUInteger pro) {
        completion(error);
    }];
}

- (void)sendImageMessage:(NSString *)path name:(nullable NSString *)name width:(int32_t)width height:(int32_t)height conversationId:(nullable NSString *)conversationId completion:(void (^)(NSError *_Nullable))completion {
    [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s, image path: %@", __FUNCTION__, path]];
    V2NIMMessage *message = [MessageUtils imageMessageWithPath:path name:name sceneName:nil width:width height:height];
    message.text = name;
    V2NIMSendMessageParams *params = [self getSendMessageParams:nil message:message];
    [self sendMessage:message conversationId:conversationId params:params completion:^(V2NIMMessage *msg, NSError *error, NSUInteger pro) {
        completion(error);
    }];
}

- (void)sendVideoMessage:(NSURL *)url name:(nullable NSString *)name width:(int32_t)width height:(int32_t)height duration:(int32_t)duration conversationId:(nullable NSString *)conversationId completion:(void (^)(V2NIMMessage *_Nullable, NSError *_Nullable, NSUInteger))completion {
    [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s, video url: %@", __FUNCTION__, url.path]];
    __weak typeof(self) weakSelf = self;
    [self convertVideoToMP4:url completion:^(NSURL *outputUrl, NSError *error) {
        if (outputUrl.path) {
            V2NIMMessage *message = [MessageUtils videoMessageWithFilePath:outputUrl.path name:name sceneName:nil width:width height:height duration:duration];
            message.text = name;
            V2NIMSendMessageParams *params = [weakSelf getSendMessageParams:nil message:message];
            [weakSelf sendMessage:message conversationId:conversationId params:params completion:^(V2NIMMessage *msg, NSError *err, NSUInteger pro) {
                completion(msg, err, pro);
            }];
        } else {
            [NEALog errorLog:@"chat view model" desc:@"convert mov to mp4 failed"];
            completion(nil, [NSError errorWithDomain:@"convert mov to mp4 failed" code:414 userInfo:nil], 0);
        }
    }];
}

- (void)convertVideoToMP4:(NSURL *)videoURL completion:(void (^)(NSURL *_Nullable, NSError *_Nullable))completion {
    if ([[videoURL.pathExtension lowercaseString] isEqualToString:@"mp4"]) {
        completion(videoURL, nil);
        return;
    }
    NSString *outputFileName = [NIMKitFileLocationHelper genFilenameWithExt:@"mp4"];
    NSString *outputPath = [NIMKitFileLocationHelper filepathForVideo:outputFileName];
    if (!outputPath) return;
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:videoURL options:nil];
    AVAssetExportSession *session = [AVAssetExportSession exportSessionWithAsset:asset presetName:AVAssetExportPresetHighestQuality];
    NSURL *outputUrl = [NSURL fileURLWithPath:outputPath];
    session.outputURL = outputUrl;
    session.outputFileType = AVFileTypeMPEG4;
    session.shouldOptimizeForNetworkUse = YES;
    [session exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (session.status == AVAssetExportSessionStatusCompleted) {
                completion(outputUrl, nil);
            } else {
                completion(videoURL, nil);
            }
        });
    }];
}

- (void)sendLocationMessage:(ChatLocaitonModel *)model conversationId:(nullable NSString *)conversationId completion:(void (^)(NSError *_Nullable))completion {
    [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s, title: %@", __FUNCTION__, model.title]];
    V2NIMMessage *message = [MessageUtils locationMessageWithLat:model.lat lng:model.lng address:[model.title stringByAppendingString:model.address]];
    message.text = model.title;
    V2NIMSendMessageParams *params = [self getSendMessageParams:nil message:message];
    [self sendMessage:message conversationId:conversationId params:params completion:^(V2NIMMessage *msg, NSError *error, NSUInteger pro) {
        completion(error);
    }];
}

- (void)sendLocationMessage:(ChatLocaitonModel *)model completion:(void (^)(NSError *_Nullable))completion {
    [self sendLocationMessage:model conversationId:nil completion:completion];
}

- (void)sendFileMessage:(NSString *)filePath displayName:(nullable NSString *)displayName conversationId:(nullable NSString *)conversationId completion:(void (^)(V2NIMMessage *_Nullable, NSError *_Nullable, NSUInteger))completion {
    [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s, filePath: %@", __FUNCTION__, filePath]];
    V2NIMMessage *message = [MessageUtils fileMessageWithFilePath:filePath displayName:displayName sceneName:nil];
    message.text = displayName;
    V2NIMSendMessageParams *params = [self getSendMessageParams:nil message:message];
    [self sendMessage:message conversationId:conversationId params:params completion:^(V2NIMMessage *msg, NSError *error, NSUInteger pro) {
        completion(msg, error, pro);
    }];
}

- (void)sendCustomMessage:(NSString *)text rawAttachment:(NSString *)rawAttachment conversationId:(nullable NSString *)conversationId completion:(void (^)(NSError *_Nullable))completion {
    [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s, text: %@", __FUNCTION__, text]];
    V2NIMMessage *message = [MessageUtils customMessageWithText:text rawAttachment:rawAttachment];
    V2NIMSendMessageParams *params = [self getSendMessageParams:nil message:message];
    [self sendMessage:message conversationId:conversationId params:params completion:^(V2NIMMessage *msg, NSError *error, NSUInteger pro) {
        completion(error);
    }];
}

- (void)insertTextMessage:(NSString *)text conversationId:(NSString *)conversationId senderId:(nullable NSString *)senderId {
    [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s, text: %@", __FUNCTION__, text]];
    V2NIMMessage *message = [MessageUtils textMessageWithText:text remoteExt:nil];
    __weak typeof(self) weakSelf = self;
    [[ChatRepo shared] insertMessageToLocal:message conversationId:conversationId senderId:senderId completion:^(id result, NSError *error) {
        if ([[ChatRepo conversationId] isEqualToString:conversationId]) {
            [weakSelf modelFromMessage:message completion:^(id<MessageModel> model) {
                NSInteger index = [weakSelf insertToMessages:model];
                [weakSelf.delegate sending:message index:[NSIndexPath indexPathForRow:index inSection:0]];
            }];
        }
    }];
    if ([NIMSDK sharedSDK].v2Option.enableV2CloudConversation == NO) {
        [[LocalConversationRepo shared] createConversation:conversationId completion:^(id conversation, NSError *error) {
            [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s insertTextMessage %@", __FUNCTION__, error.localizedDescription ?: @""]];
        }];
        return;
    }
    [[ConversationRepo shared] createConversation:conversationId completion:^(id conversation, NSError *error) {
        [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s insertTextMessage %@", __FUNCTION__, error.localizedDescription ?: @""]];
    }];
}

- (void)insertTipMessage:(NSString *)text createTime:(nullable NSNumber *)createTime conversationId:(nullable NSString *)conversationId senderId:(nullable NSString *)senderId {
    [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s, text: %@", __FUNCTION__, text]];
    NSString *cid = conversationId ?: [ChatRepo conversationId];
    V2NIMMessage *tip = [MessageUtils tipMessageWithText:text];
    __weak typeof(self) weakSelf = self;
    [[ChatRepo shared] insertMessageToLocal:tip conversationId:cid senderId:senderId createTime:createTime completion:^(id result, NSError *error) {
        if ([cid isEqualToString:[ChatRepo conversationId]]) {
            [weakSelf modelFromMessage:tip completion:^(id<MessageModel> model) {
                NSInteger index = [weakSelf insertToMessages:model];
                [weakSelf.delegate sending:tip index:[NSIndexPath indexPathForRow:index inSection:0]];
            }];
        }
    }];
}

- (void)markRead:(NSArray<V2NIMMessage *> *)messages completion:(void (^)(NSError *_Nullable))completion {
    // 子类重写（P2P 发送 P2P 已读回执，Team 发送群已读回执）
    completion(nil);
}

- (void)markReadMessages:(NSArray<V2NIMMessage *> *)messages completion:(void (^)(NSError *_Nullable))completion {
    [self markRead:messages completion:completion];
}

- (void)getMessageReceipts:(NSArray<V2NIMMessage *> *)messages completion:(void (^)(NSArray<NSIndexPath *> *, NSError *_Nullable))completion {
    // 子类重写（Team 获取群消息已读回执）
    completion(@[], nil);
}

- (void)deleteMessage:(void (^)(NSError *_Nullable))completion {
    V2NIMMessage *message = self.operationModel.message;
    NSString *messageId = message.messageClientId;
    if (!message || !messageId) {
        [NEALog errorLog:TAG desc:[NSString stringWithFormat:@"%s, message is nil", __FUNCTION__]];
        return;
    }
    [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s, messageClientId: %@", __FUNCTION__, messageId]];
    if (self.operationModel.isRevoked) return;
    if ([self.deletingMsgDic containsObject:messageId]) return;
    [self.deletingMsgDic addObject:messageId];

    __weak typeof(self) weakSelf = self;
    BOOL isLocal = !(message.messageServerId.length > 0);
    BOOL isZero = [message.messageServerId isEqualToString:@"0"];
    if (isLocal || isZero) {
        [[ChatRepo shared] deleteMessage:message onlyDeleteLocal:YES completion:^(NSError *error) {
            if (!error) {
                [weakSelf deleteMessageUpdateUI:@[message]];
                [weakSelf.deletingMsgDic removeObject:messageId];
            }
            completion(error);
        }];
        return;
    }
    [[ChatRepo shared] deleteMessage:message onlyDeleteLocal:NO completion:^(NSError *error) {
        if (!error) {
            [weakSelf deleteMessageUpdateUI:@[message]];
            [weakSelf.deletingMsgDic removeObject:messageId];
        }
        completion(error);
    }];
}

- (void)deleteMessages:(NSArray<V2NIMMessage *> *)messages completion:(void (^)(NSError *_Nullable))completion {
    NSArray<V2NIMMessage *> *messageSnapshot = [messages copy] ?: @[];
    [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s, message count: %lu", __FUNCTION__, (unsigned long)messageSnapshot.count]];
    NSMutableArray *localMsgs = [NSMutableArray array];
    NSMutableArray *remoteMsgs = [NSMutableArray array];
    for (V2NIMMessage *msg in messageSnapshot) {
        NSString *messageId = msg.messageClientId;
        if (!messageId) continue;
        if ([self.deletingMsgDic containsObject:messageId]) continue;
        [self.deletingMsgDic addObject:messageId];
        if (!(msg.messageServerId.length > 0)) {
            [localMsgs addObject:msg];
        } else {
            [remoteMsgs addObject:msg];
        }
    }
    __weak typeof(self) weakSelf = self;
    NSArray<V2NIMMessage *> *localSnapshot = [localMsgs copy];
    NSArray<V2NIMMessage *> *remoteSnapshot = [remoteMsgs copy];
    [[ChatRepo shared] deleteMessages:localSnapshot onlyDeleteLocal:YES completion:^(NSError *error) {
        if (!error) {
            [weakSelf deleteMessageUpdateUI:localSnapshot];
            for (V2NIMMessage *msg in localSnapshot) {
                if (msg.messageClientId) [weakSelf.deletingMsgDic removeObject:msg.messageClientId];
            }
        }
        completion(error);
    }];
    [[ChatRepo shared] deleteMessages:remoteSnapshot onlyDeleteLocal:NO completion:^(NSError *error) {
        if (!error) {
            [weakSelf deleteMessageUpdateUI:remoteSnapshot];
            for (V2NIMMessage *msg in remoteSnapshot) {
                if (msg.messageClientId) [weakSelf.deletingMsgDic removeObject:msg.messageClientId];
            }
        }
        completion(error);
    }];
}

- (void)replyMessageWithoutThread:(V2NIMMessage *)message replyMessage:(V2NIMMessage *)replyMessage aiUserAccid:(nullable NSString *)aiUserAccid completion:(void (^)(V2NIMMessage *_Nullable, NSError *_Nullable))completion {
    [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    NSDictionary *yxReplyMsg = [ChatMessageHelper createReplyDic:replyMessage];
    NSMutableDictionary *remoteExt = [NSMutableDictionary dictionaryWithDictionary:[NECommonUtil getDictionaryFromJSONString:message.serverExtension ?: @""] ?: @{}];
    remoteExt[keyReplyMsgKey] = yxReplyMsg;
    message.serverExtension = [NECommonUtil getJSONStringFromDictionary:remoteExt];
    V2NIMSendMessageParams *params = [self getReplyMessageParams:aiUserAccid replyMessage:replyMessage message:message];
    [self sendMessage:message conversationId:[ChatRepo conversationId] params:params completion:^(V2NIMMessage *msg, NSError *error, NSUInteger pro) {
        completion(msg, error);
    }];
}

- (void)replyMessageWithThread:(V2NIMMessage *)message replyMessage:(V2NIMMessage *)replyMessage aiUserAccid:(nullable NSString *)aiUserAccid completion:(void (^)(V2NIMMessage *_Nullable, NSError *_Nullable))completion {
    [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    NSDictionary *yxReplyMsg = [ChatMessageHelper createReplyDic:replyMessage];
    NSMutableDictionary *localExt = [NSMutableDictionary dictionaryWithDictionary:[NECommonUtil getDictionaryFromJSONString:message.localExtension ?: @""] ?: @{}];
    localExt[keyReplyMsgKey] = yxReplyMsg;
    message.localExtension = [NECommonUtil getJSONStringFromDictionary:localExt];
    V2NIMSendMessageParams *params = [self getReplyMessageParams:aiUserAccid replyMessage:replyMessage message:message];
    __weak typeof(self) weakSelf = self;
    [[ChatRepo shared] replyMessage:message replyMessage:replyMessage params:params completion:^(V2NIMSendMessageResult *result, NSError *error, NSUInteger pro) {
        completion(result.message, error);
    }];
}

- (void)revokeMessage:(V2NIMMessage *)message completion:(void (^)(NSError *_Nullable))completion {
    [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    NSMutableDictionary *muta = [NSMutableDictionary dictionary];
    NSDictionary *serverExt = [self getDictionaryFromJSONString:message.serverExtension ?: @""];
    if (serverExt) [muta addEntriesFromDictionary:serverExt];
    if (message.threadReply.messageClientId.length > 0) {
        muta[keyReplyMsgKey] = [ChatMessageHelper createReplyDic:message.threadReply];
    }
    muta[revokeLocalMessage] = @YES;
    muta[revokeLocalMessageTime] = @([[NSDate date] timeIntervalSince1970]);
    if (message.messageType == V2NIM_MESSAGE_TYPE_TEXT) {
        muta[revokeLocalMessageContent] = message.text;
    }
    if (message.messageType == V2NIM_MESSAGE_TYPE_CUSTOM) {
        NSString *title = [NECustomUtils titleOfRichText:message.attachment];
        NSString *body = [NECustomUtils bodyOfRichText:message.attachment];
        if (title.length > 0) muta[revokeLocalMessageTitle] = title;
        if (body.length > 0) muta[revokeLocalMessageContent] = body;
    }
    V2NIMMessageRevokeParams *revokeParams = [[V2NIMMessageRevokeParams alloc] init];
    revokeParams.serverExtension = [self getJSONStringFromDictionary:muta];
    __weak typeof(self) weakSelf = self;
    [[ChatRepo shared] revokeMessage:message params:revokeParams completion:^(NSError *error) {
        if (!error) [weakSelf revokeMessageUpdateUI:message];
        completion(error);
    }];
}

- (NSString *)getShowName:(NSString *)accountId showAlias:(BOOL)showAlias {
    NSString *aiName = [[NEAIUserManager shared] getShowName:accountId];
    if (aiName) return aiName;
    return [[NEFriendUserCache shared] getShowName:accountId showAlias:showAlias];
}

- (void)loadShowName:(NSArray<NSString *> *)accountIds teamId:(nullable NSString *)teamId completion:(void (^)(void))completion {
    // 子类重写（Team 需要加载群昵称）
    completion();
}

- (nullable NSMutableArray<OperationItem *> *)avalibleOperationsForMessage:(nullable MessageContentModel *)model {
    [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s, pinAccount: %@", __FUNCTION__, model.pinAccount ?: @"nil"]];
    if (!model || !model.message) {
        return nil;
    }

    NSMutableArray<OperationItem *> *items = [NSMutableArray array];
    if (model.message.sendingState == V2NIM_MESSAGE_SENDING_STATE_SENDING) {
        if (model.message.messageType == V2NIM_MESSAGE_TYPE_TEXT) {
            [items addObjectsFromArray:@[[OperationItem copyItem], [OperationItem deleteItem], [OperationItem selectItem]]];
        } else {
            return [@[[OperationItem deleteItem], [OperationItem selectItem]] mutableCopy];
        }
        return items;
    }
    if (model.message.sendingState == V2NIM_MESSAGE_SENDING_STATE_FAILED ||
        model.message.messageType == V2NIM_MESSAGE_TYPE_CALL ||
        model.message.messageStatus.errorCode != operationSuccess) {
        if (model.message.messageType == V2NIM_MESSAGE_TYPE_TEXT) {
            [items addObjectsFromArray:@[[OperationItem copyItem], [OperationItem deleteItem], [OperationItem selectItem]]];
        } else {
            return [@[[OperationItem deleteItem], [OperationItem selectItem]] mutableCopy];
        }
        return items;
    }
    OperationItem *pinItem = model.isPined ? [OperationItem removePinItem] : [OperationItem pinItem];
    OperationItem *topItem = [model.message.messageClientId isEqualToString:self.topMessage.messageClientId] ? [OperationItem untopItem] : [OperationItem topItem];
    switch (model.message.messageType) {
        case V2NIM_MESSAGE_TYPE_LOCATION:
            [items addObjectsFromArray:@[[OperationItem replayItem],[OperationItem forwardItem],pinItem,[OperationItem deleteItem],[OperationItem selectItem],[OperationItem collectionItem],topItem]]; break;
        case V2NIM_MESSAGE_TYPE_TEXT:
            items = [@[[OperationItem copyItem],[OperationItem replayItem],[OperationItem forwardItem],pinItem,[OperationItem deleteItem],[OperationItem selectItem],[OperationItem collectionItem],topItem] mutableCopy]; break;
        case V2NIM_MESSAGE_TYPE_IMAGE:
        case V2NIM_MESSAGE_TYPE_VIDEO:
        case V2NIM_MESSAGE_TYPE_FILE:
            items = [@[[OperationItem replayItem],[OperationItem forwardItem],pinItem,[OperationItem deleteItem],[OperationItem selectItem],[OperationItem collectionItem],topItem] mutableCopy]; break;
        case V2NIM_MESSAGE_TYPE_AUDIO: {
            OperationItem *earItem = [[SettingRepo shared] getHandsetMode] ? [OperationItem earpieceItem] : [OperationItem speakerItem];
            items = [@[earItem,[OperationItem replayItem],pinItem,[OperationItem deleteItem],[OperationItem selectItem],[OperationItem collectionItem],topItem] mutableCopy];
        } break;
        case V2NIM_MESSAGE_TYPE_CUSTOM:
            if (model.customType > 0) {
                if (model.customType == customRichTextType) items = [@[[OperationItem copyItem]] mutableCopy];
                [items addObjectsFromArray:@[[OperationItem replayItem],[OperationItem forwardItem],pinItem,[OperationItem deleteItem],[OperationItem selectItem],[OperationItem collectionItem],topItem]];
            } else {
                items = [@[[OperationItem deleteItem],[OperationItem selectItem],[OperationItem collectionItem]] mutableCopy];
            } break;
        default:
            items = [@[[OperationItem replayItem],pinItem,[OperationItem deleteItem],[OperationItem selectItem]] mutableCopy]; break;
    }
    if (model.message.messageType == V2NIM_MESSAGE_TYPE_AUDIO && [model isKindOfClass:[MessageAudioModel class]] && ((MessageAudioModel *)model).text == nil) {
        [items addObject:[OperationItem audioToTextItem]];
    }
    if ([ChatMessageHelper isSelf:model.message]) {
        if (model.message.messageType == V2NIM_MESSAGE_TYPE_CUSTOM && model.unkonwMessage) return items;
        for (NSInteger i = 0; i < items.count; i++) {
            if (items[i].type == OperationTypeDelete) {
                [items insertObject:[OperationItem recallItem] atIndex:i + 1]; break;
            }
        }
    }
    if (![IMKitConfigCenter shared].enableCollectionMessage) {
        [items filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(OperationItem *item, NSDictionary *b) { return item.type != OperationTypeCollection; }]];
    }
    if (![IMKitConfigCenter shared].enablePinMessage) {
        [items filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(OperationItem *item, NSDictionary *b) { return item.type != OperationTypePin && item.type != OperationTypeRemovePin; }]];
    }
    if (![IMKitConfigCenter shared].enableTopMessage || model.message.conversationType == V2NIM_CONVERSATION_TYPE_P2P) {
        [items filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(OperationItem *item, NSDictionary *b) { return item.type != OperationTypeTop && item.type != OperationTypeUntop; }]];
    }
    return items;
}

- (void)addTimeForHistoryMessage:(BOOL)forward {
    [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    for (NSInteger i = 0; i < self.messages.count; i++) {
        id<MessageModel> model = self.messages[i];
        if (i == 0 && model.message.createTime > 0) {
            NSDate *date = [NSDate dateWithTimeIntervalSince1970:model.message.createTime];
            model.timeContent = [ChatMessageHelper ne_stringFromDate:date];
            continue;
        }
        if (model.message && [NotificationMessageUtils isDiscussSeniorTeamNoti:model.message]) continue;
        if (i == 0) continue;
        id<MessageModel> lastModel = self.messages[i - 1];
        double lastTime = lastModel.message.createTime;
        double curTime = model.message.createTime;
        double dur = forward ? curTime - lastTime : lastTime - curTime;
        if ((dur / 60) > 5) {
            NSDate *date = [NSDate dateWithTimeIntervalSince1970:curTime];
            model.timeContent = [ChatMessageHelper ne_stringFromDate:date];
        }
    }
}

- (void)modelFromMessage:(V2NIMMessage *)message completion:(void (^)(id<MessageModel> ))completion {
    [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s, messageClientId: %@", __FUNCTION__, message.messageClientId]];
    __weak typeof(self) weakSelf = self;
    [ChatMessageHelper modelFromMessage:message completion:^(id<MessageModel> model) {
        if ([ChatMessageHelper isRevokeMessage:model.message]) {
            NSString *content = [ChatMessageHelper getRevokeMessageContent:model];
            if (content) { model.isReedit = YES; model.message.text = content; }
            model.isRevoked = YES;
        }
        NSString *uid = [ChatMessageHelper getSenderId:message];
        if (uid) {
            NSString *fullName = [weakSelf getShowName:uid showAlias:YES];
            NEUserWithFriend *user = [ChatMessageHelper getUserFromCache:uid];
            model.avatar = user.user.avatar;
            model.fullName = fullName;
            model.shortName = [NEFriendUserCache getShortName:[user showName:NO] ?: @""];
        }
        id<MessageModel> replyModel = [weakSelf getReplyMessageFromLocal:message];
        if (replyModel) model.replyedModel = replyModel;
        if ([weakSelf.delegate respondsToSelector:@selector(getMessageModel:)]) [weakSelf.delegate getMessageModel:model];
        completion(model);
    }];
}

- (id<MessageModel> )modelFromMessage:(V2NIMMessage *)message {
    [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s, messageClientId: %@", __FUNCTION__, message.messageClientId]];
    id<MessageModel> model = [ChatMessageHelper modelFromMessage:message];
    if ([ChatMessageHelper isRevokeMessage:model.message]) {
        NSString *content = [ChatMessageHelper getRevokeMessageContent:model];
        if (content) { model.isReedit = YES; model.message.text = content; }
        model.isRevoked = YES;
    }
    NSString *uid = [ChatMessageHelper getSenderId:message];
    if (uid) {
        NSString *fullName = [self getShowName:uid showAlias:YES];
        NEUserWithFriend *user = [ChatMessageHelper getUserFromCache:uid];
        model.avatar = user.user.avatar;
        model.fullName = fullName;
        model.shortName = [NEFriendUserCache getShortName:[user showName:NO] ?: @""];
    }
    id<MessageModel> replyModel = [self getReplyMessageFromLocal:message];
    if (replyModel) {
        model.replyedModel = replyModel;
        if (!replyModel.message) model.replyText = chatLocalizable(@"message_not_found");
    }
    if ([self.delegate respondsToSelector:@selector(getMessageModel:)]) [self.delegate getMessageModel:model];
    return model;
}

- (nullable id<MessageModel> )getReplyMessageFromLocal:(V2NIMMessage *)message {
    NSString *replyId = nil;
    NSDictionary *replyDic = [ChatMessageHelper getReplyDictionary:message];
    replyId = replyDic[@"idClient"];
    if (message.threadReply.messageClientId.length > 0) replyId = message.threadReply.messageClientId;
    if (!replyId.length) return nil;
    NSArray<id<MessageModel> > *messageSnapshot = [self.messages copy];
    for (id<MessageModel> model in messageSnapshot) {
        if ([model.message.messageClientId isEqualToString:replyId] && !model.isRevoked) return model;
    }
    MessageTextModel *textModel = [[MessageTextModel alloc] initWithMessage:nil];
    NSString *replySenderId = replyDic[@"from"];
    if (replySenderId) textModel.fullName = replySenderId;
    return textModel;
}

- (void)getReplyMessage:(V2NIMMessage *)message completion:(void (^)(id<MessageModel> _Nullable))completion {
    NSString *replyId = nil;
    NSDictionary *replyDic = [ChatMessageHelper getReplyDictionary:message];
    replyId = replyDic[@"idClient"];
    if (message.threadReply.messageClientId.length > 0) replyId = message.threadReply.messageClientId;
    if (!replyId.length) { completion(nil); return; }
    NSArray<id<MessageModel> > *messageSnapshot = [self.messages copy];
    for (id<MessageModel> model in messageSnapshot) {
        if ([model.message.messageClientId isEqualToString:replyId] && !model.isRevoked) { completion(model); return; }
    }
    V2NIMMessageRefer *refer = [ChatMessageHelper createMessageRefer:replyDic];
    if (message.threadReply.senderId.length > 0) refer.senderId = message.threadReply.senderId;
    if (message.threadReply.receiverId.length > 0) refer.receiverId = message.threadReply.receiverId;
    if (message.threadReply.messageClientId.length > 0) refer.messageClientId = message.threadReply.messageClientId;
    if (message.threadReply.messageServerId.length > 0) refer.messageServerId = message.threadReply.messageServerId;
    refer.conversationType = message.threadReply.conversationType;
    if (message.threadReply.conversationId.length > 0) refer.conversationId = message.threadReply.conversationId;
    if (message.threadReply.createTime > 0) refer.createTime = message.threadReply.createTime;
    __weak typeof(self) weakSelf = self;
    [[ChatRepo shared] getMessageListByRefers:@[refer] completion:^(NSArray<V2NIMMessage *> *msgs, NSError *error) {
        if (msgs.firstObject) {
            [weakSelf modelFromMessage:msgs.firstObject completion:^(id<MessageModel> model) { completion(model); }];
        } else {
            completion(nil);
        }
    }];
}

- (NSDictionary *)deleteMessageModel:(V2NIMMessage *)message {
    NSMutableArray<NSNumber *> *deleteIndexs = [NSMutableArray array];
    NSMutableArray<NSNumber *> *reloadIndexs = [NSMutableArray array];
    if (message.messageClientId.length == 0) {
        return @{@"deleteIndexs": deleteIndexs, @"reloadIndexs": reloadIndexs};
    }
    NSInteger index = -1;
    BOOL hasFind = NO;
    for (NSInteger i = 0; i < self.messages.count; i++) {
        id<MessageModel> model = self.messages[i];
        if (hasFind) {
            NSString *replyId = nil;
            NSDictionary *remoteExt = [self getDictionaryFromJSONString:model.message.serverExtension ?: @""];
            id yxReplyMsg = remoteExt[keyReplyMsgKey];
            if ([yxReplyMsg isKindOfClass:[NSDictionary class]]) {
                id idClient = [(NSDictionary *)yxReplyMsg objectForKey:@"idClient"];
                if ([idClient isKindOfClass:[NSString class]]) {
                    replyId = idClient;
                }
            }
            if (model.message.threadReply.messageClientId.length > 0) replyId = model.message.threadReply.messageClientId;
            if (replyId.length > 0 && [replyId isEqualToString:message.messageClientId]) {
                self.messages[i].replyText = chatLocalizable(@"message_not_found");
                [reloadIndexs addObject:@(i)];
            }
        } else {
            if ([model.message.messageClientId isEqualToString:message.messageClientId]) {
                index = i; hasFind = YES;
            }
        }
    }
    if (index >= 0) [deleteIndexs addObject:@(index)];
    return @{@"deleteIndexs": deleteIndexs, @"reloadIndexs": reloadIndexs};
}

- (void)deleteMessageUpdateUI:(NSArray<V2NIMMessage *> *)messages {
    NSArray<V2NIMMessage *> *messageSnapshot = [messages copy] ?: @[];
    if (![NSThread isMainThread]) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf deleteMessageUpdateUI:messageSnapshot];
        });
        return;
    }
    [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s, messages count: %lu", __FUNCTION__, (unsigned long)messageSnapshot.count]];
    NSMutableSet<NSNumber *> *deleteIdxSet = [NSMutableSet set];
    NSMutableSet<NSNumber *> *reloadIdxSet = [NSMutableSet set];
    for (V2NIMMessage *message in messageSnapshot) {
        NSDictionary *result = [self deleteMessageModel:message];
        for (NSNumber *n in result[@"deleteIndexs"]) [deleteIdxSet addObject:n];
        for (NSNumber *n in result[@"reloadIndexs"]) [reloadIdxSet addObject:n];
    }
    NSMutableArray<NSIndexPath *> *deletePaths = [NSMutableArray array];
    NSMutableArray<NSIndexPath *> *reloadPaths = [NSMutableArray array];
    for (NSNumber *n in deleteIdxSet) {
        if (n.integerValue >= 0 && n.integerValue < self.messages.count) {
            [deletePaths addObject:[NSIndexPath indexPathForRow:n.integerValue inSection:0]];
        }
    }
    for (NSNumber *n in reloadIdxSet) {
        if (n.integerValue >= 0 && n.integerValue < self.messages.count) {
            [reloadPaths addObject:[NSIndexPath indexPathForRow:n.integerValue inSection:0]];
        }
    }
    [self.delegate onDeleteMessage:messageSnapshot deleteIndexs:deletePaths reloadIndex:reloadPaths];
}

- (void)revokeMessageUpdateUI:(V2NIMMessage *)message {
    [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    NSInteger index = -1;
    NSMutableArray<NSIndexPath *> *indexs = [NSMutableArray array];
    BOOL hasFind = NO;
    for (NSInteger i = 0; i < self.messages.count; i++) {
        id<MessageModel> model = self.messages[i];
        if (hasFind) {
            NSString *replyId = nil;
            NSDictionary *remoteExt = [self getDictionaryFromJSONString:model.message.serverExtension ?: @""];
            NSDictionary *yxReplyMsg = remoteExt[keyReplyMsgKey];
            if (yxReplyMsg) replyId = yxReplyMsg[@"idClient"];
            if (model.message.threadReply.messageClientId.length > 0) replyId = model.message.threadReply.messageClientId;
            if (replyId.length > 0 && [replyId isEqualToString:message.messageClientId]) {
                self.messages[i].replyText = chatLocalizable(@"message_not_found");
                [indexs addObject:[NSIndexPath indexPathForRow:i inSection:0]];
            }
        } else {
            if ([model.message.messageServerId isEqualToString:message.messageServerId]) {
                index = i; hasFind = YES;
            }
        }
    }
    if (![IMKitConfigCenter shared].enableInsertLocalMsgWhenRevoke) {
        [self deleteMessageUpdateUI:@[message]]; return;
    }
    if (index >= 0) {
        self.messages[index].isRevoked = YES;
        self.messages[index].replyedModel = nil;
        self.messages[index].isPined = NO;
        if ((message.aiConfig == nil || message.aiConfig.aiStatus != V2NIM_MESSAGE_AI_STATUS_RESPONSE)) {
            NSString *content = [ChatMessageHelper getRevokeMessageContent:self.messages[index]];
            if (content) { self.messages[index].isReedit = YES; self.messages[index].message.text = content; }
        }
        if ([message.senderId isEqualToString:[[IMKitClient instance] account]]) {
            self.messages[index].message.aiConfig.accountId = [[IMKitClient instance] account];
            if ([self.messages[index] isKindOfClass:[MessageContentModel class]]) {
                ((MessageContentModel *)self.messages[index]).fullNameHeight = 0;
            }
            NEUserWithFriend *selfInfo = [[NEFriendUserCache shared] getFriendInfo:[[IMKitClient instance] account]];
            self.messages[index].avatar = selfInfo.user.avatar;
            self.messages[index].shortName = [selfInfo shortName:NO count:2];
            self.messages[index].fullName = [selfInfo showName];
        }
        NSIndexPath *revokeIndexPath = [NSIndexPath indexPathForRow:index inSection:0];
        if (![indexs containsObject:revokeIndexPath]) {
            [indexs addObject:revokeIndexPath];
        }
    }
    [self.delegate onRevokeMessage:message atIndexs:indexs];
}

- (void)downLoad:(NSString *)urlString filePath:(NSString *)filePath progress:(nullable void (^)(NSUInteger))progress completion:(nullable void (^)(NSString *_Nullable, NSError *_Nullable))completion {
    [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s, url: %@", __FUNCTION__, urlString]];
    [[ResourceRepo shared] downLoadFile:urlString filePath:filePath progress:progress completion:completion];
}

- (void)forwardMessages:(NSArray<NSString *> *)conversationIds isMultiForward:(BOOL)isMultiForward depth:(NSInteger)depth comment:(nullable NSString *)comment completion:(void (^)(NSError *_Nullable))completion {
    [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s, messages.count: %lu", __FUNCTION__, (unsigned long)self.selectedMessages.count]];
    NSArray *forwardMessages = [self.selectedMessages sortedArrayUsingComparator:^NSComparisonResult(V2NIMMessage *m1, V2NIMMessage *m2) {
        return m1.createTime < m2.createTime ? NSOrderedAscending : NSOrderedDescending;
    }];
    if (isMultiForward) {
        [self forwardMultiMessage:forwardMessages conversationIds:conversationIds depth:depth comment:comment completion:completion];
    } else {
        [self forwardMessage:self.selectedMessages conversationIds:conversationIds comment:comment completion:completion];
    }
}

- (void)forwardMessage:(NSArray<V2NIMMessage *> *)forwardMessages conversationIds:(NSArray<NSString *> *)conversationIds comment:(nullable NSString *)comment completion:(void (^)(NSError *_Nullable))completion {
    for (NSString *conversationId in conversationIds) {
        for (V2NIMMessage *message in forwardMessages) {
            V2NIMMessage *fwdMsg = [MessageUtils forwardMessageWithMessage:message];
            [ChatMessageHelper clearForwardReplyMark:fwdMsg];
            V2NIMSendMessageParams *params = [[ChatRepo shared] getSendMessageParams];
            NSString *sessionId = [V2NIMConversationIdUtil conversationTargetId:conversationId];
            if (sessionId && [[NEAIUserManager shared] isAIUser:sessionId]) {
                params = [self getForwardMessageParams:sessionId forwardMessage:fwdMsg];
            }
            [[ChatRepo shared] sendMessage:fwdMsg conversationId:conversationId params:params completion:^(V2NIMSendMessageResult *r, NSError *e, NSUInteger p) {}];
        }
        if (comment.length > 0) {
            __weak typeof(self) weakSelf = self;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                V2NIMMessage *message = [MessageUtils textMessageWithText:comment remoteExt:nil];
                V2NIMSendMessageParams *params = [[ChatRepo shared] getSendMessageParams];
                NSString *sessionId = [V2NIMConversationIdUtil conversationTargetId:conversationId];
                if (sessionId && [[NEAIUserManager shared] isAIUser:sessionId]) {
                    params = [weakSelf getForwardMessageParams:sessionId forwardMessage:message];
                }
                [weakSelf sendMessage:message conversationId:conversationId params:params completion:^(V2NIMMessage *m, NSError *e, NSUInteger p) { completion(e); }];
            });
        } else {
            completion(nil);
        }
    }
}

- (void)forwardMultiMessage:(NSArray<V2NIMMessage *> *)forwardMessages conversationIds:(NSArray<NSString *> *)conversationIds depth:(NSInteger)depth comment:(nullable NSString *)comment completion:(void (^)(NSError *_Nullable))completion {
    if (forwardMessages.count <= 0) {
        if (comment.length > 0) {
            for (NSString *conversationId in conversationIds) {
                V2NIMMessage *message = [MessageUtils textMessageWithText:comment remoteExt:nil];
                V2NIMSendMessageParams *params = [[ChatRepo shared] getSendMessageParams];
                [self sendMessage:message conversationId:conversationId params:params completion:^(V2NIMMessage *m, NSError *e, NSUInteger p) { completion(e); }];
            }
        } else { completion(nil); }
        return;
    }
    NSString *fromSession = [ChatRepo conversationId];
    NSString *header = [ChatMessageHelper buildHeader:forwardMessages.count];
    __weak typeof(self) weakSelf = self;
    [ChatMessageHelper buildBody:forwardMessages completion:^(NSString *body, NSArray<NSDictionary *> *abstracts) {
        NSString *multiForwardMsg = [header stringByAppendingString:body];
        NSString *fileName = [NSString stringWithFormat:@"%@%ld", multiForwardFileName, (long)[[NSDate date] timeIntervalSince1970]];
        NSString *fileDir = [NEPathUtils getDirectoryForDocuments:[NSString stringWithFormat:@"%@file/", imkitDir]];
        if (!fileDir) {
            completion([NSError errorWithDomain:chatLocalizable(@"forward_failed") code:414 userInfo:nil]);
            return;
        }
        NSString *filePath = [fileDir stringByAppendingString:fileName];

        NSError *writeError = nil;
        [multiForwardMsg writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&writeError];
        if (writeError) {
            completion([NSError errorWithDomain:chatLocalizable(@"forward_failed") code:414 userInfo:nil]);
            NSLog(@"Error writing string to file: %@", writeError);
            return;
        }

        V2NIMUploadFileTask *fileTask = [[ResourceRepo shared] createUploadFileTask:filePath sceneName:nil];
        [[ResourceRepo shared] uploadFile:fileTask progress:nil completion:^(NSString *url, NSError *error) {
            if (error) {
                completion(error);
                return;
            }
            if (!url) {
                completion([NSError errorWithDomain:chatLocalizable(@"forward_failed") code:414 userInfo:nil]);
                return;
            }

            NSURL *fileURL = [NSURL fileURLWithPath:filePath];
            NSString *md5 = fileURL ? [ChatMessageHelper getFileChecksum:fileURL] : nil;

            // 删除本地文件
            NSError *removeError = nil;
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:&removeError];
            if (removeError) {
                NSLog(@"无法删除合并转发文件：%@", removeError);
            }

            NSMutableDictionary *data = [NSMutableDictionary dictionary];
            data[@"sessionId"] = [V2NIMConversationIdUtil conversationTargetId:fromSession] ?: @"";
            data[@"url"] = url;
            if (md5) data[@"md5"] = md5;
            data[@"depth"] = @(depth);
            data[@"abstracts"] = abstracts;
            data[@"sessionName"] = [ChatMessageHelper getSessionName:fromSession showAlias:NO];

            NSMutableDictionary *jsonData = [NSMutableDictionary dictionary];
            jsonData[@"data"] = data;
            jsonData[@"messageType"] = @"custom";
            jsonData[@"type"] = @(customMultiForwardType);

            // 转发到会话
            for (NSString *conversationId in conversationIds) {
                NSString *sessionId = [V2NIMConversationIdUtil conversationTargetId:conversationId];
                NSString *text = forwardMessages.firstObject.text ?: [NSString stringWithFormat:@"[%@]", chatLocalizable(@"chat_history")];
                NSString *rawAttachment = [weakSelf getJSONStringFromDictionary:jsonData];
                V2NIMMessage *message = [MessageUtils customMessageWithText:text rawAttachment:rawAttachment];

                V2NIMSendMessageParams *params = [[ChatRepo shared] getSendMessageParams];
                if (sessionId && [[NEAIUserManager shared] isAIUser:sessionId]) {
                    params = [weakSelf getForwardMessageParams:sessionId forwardMessage:message];
                }
                [weakSelf sendMessage:message conversationId:conversationId params:params completion:^(V2NIMMessage *m, NSError *e, NSUInteger p) {
                    completion(e);
                }];

                // 发送留言
                if (comment.length > 0) {
                    // 延迟 0.2s 发送，确保留言位置在最后
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        V2NIMMessage *commentMsg = [MessageUtils textMessageWithText:comment remoteExt:nil];

                        V2NIMSendMessageParams *commentParams = [[ChatRepo shared] getSendMessageParams];
                        NSString *cSessionId = [V2NIMConversationIdUtil conversationTargetId:conversationId];
                        if (cSessionId && [[NEAIUserManager shared] isAIUser:cSessionId]) {
                            commentParams = [weakSelf getForwardMessageParams:cSessionId forwardMessage:commentMsg];
                        }

                        [weakSelf sendMessage:commentMsg conversationId:conversationId params:commentParams completion:^(V2NIMMessage *m, NSError *e, NSUInteger p) {
                            completion(e);
                        }];
                    });
                } else {
                    completion(nil);
                }
            }
        }];
    }];
}

- (void)addPinMessage:(V2NIMMessage *)message completion:(void (^)(NSError *_Nullable, NSInteger))completion {
    [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    __weak typeof(self) weakSelf = self;
    [[ChatRepo shared] pinMessage:message serverExt:@"" completion:^(NSError *error) {
        NSInteger index = -1;
        if (!error) {
            for (NSInteger i = 0; i < weakSelf.messages.count; i++) {
                id<MessageModel> currentModel = weakSelf.messages[i];
                if ([message.messageClientId isEqualToString:currentModel.message.messageClientId] && !currentModel.isPined) {
                    currentModel.isPined = YES;
                    currentModel.pinAccount = [[IMKitClient instance] account];
                    currentModel.pinShowName = [weakSelf getShowName:[[IMKitClient instance] account] showAlias:YES];
                    index = i; break;
                }
            }
        }
        completion(error, index);
    }];
}

- (void)removePinMessage:(V2NIMMessage *)message completion:(void (^)(NSError *_Nullable, NSInteger))completion {
    [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    __weak typeof(self) weakSelf = self;
    [[ChatRepo shared] unpinMessage:message serverExt:@"" completion:^(NSError *error) {
        if (!error) {
            NSInteger index = [weakSelf removeLocalPinMessage:message];
            completion(nil, index);
        } else {
            completion(error, -1);
        }
    }];
}

- (void)topMessage:(void (^)(NSError *_Nullable))completion {
    [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s, messageClientId: %@", __FUNCTION__, self.operationModel.message.messageClientId]];
    // 子类重写（Team 置顶消息）
}

- (void)untopMessage:(void (^)(NSError *_Nullable))completion {
    [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s, messageClientId: %@", __FUNCTION__, self.topMessage.messageClientId]];
    // 子类重写（Team 取消置顶消息）
}

- (void)topMessageAction:(void (^)(NSError *_Nullable))completion {
    [self topMessage:completion];
}

- (void)untopMessageAction:(void (^)(NSError *_Nullable))completion {
    [self untopMessage:completion];
}

- (void)collectMessage:(MessageContentModel *)model conversationName:(NSString *)conversationName completion:(void (^)(NSError *_Nullable))completion {
    if (!model.message) return;
    NSInteger collectionType = model.message.messageType + collectionTypeOffset;
    NSMutableDictionary *collectionDic = [NSMutableDictionary dictionary];
    NSString *messageString = [V2NIMMessageConverter messageSerialization:model.message];
    if (messageString) {
        V2NIMMessage *collectionMessage = [V2NIMMessageConverter messageDeserialization:messageString];
        if (collectionMessage) {
            NSMutableDictionary *remoteExt = [NSMutableDictionary dictionaryWithDictionary:[self getDictionaryFromJSONString:collectionMessage.serverExtension ?: @""] ?: @{}];
            [remoteExt removeObjectForKey:yxAtMsg];
            collectionMessage.serverExtension = [self getJSONStringFromDictionary:remoteExt];
            NSString *saveString = [V2NIMMessageConverter messageSerialization:collectionMessage];
            if (saveString) collectionDic[@"message"] = saveString;
        }
    }
    collectionDic[@"conversationName"] = conversationName;
    NSString *accountId = [ChatMessageHelper getSenderId:model.message];
    if (accountId) {
        V2NIMAIUser *aiUser = [[NEAIUserManager shared] getAIUserById:accountId];
        if (aiUser.name) { collectionDic[@"senderName"] = aiUser.name; }
        else if (model.fullName) { collectionDic[@"senderName"] = model.fullName; }
    } else if (model.fullName) { collectionDic[@"senderName"] = model.fullName; }
    if (model.avatar) collectionDic[@"avatar"] = model.avatar;
    NSString *content = [self getJSONStringFromDictionary:collectionDic];
    V2NIMAddCollectionParams *params = [[V2NIMAddCollectionParams alloc] init];
    params.collectionType = (int32_t)collectionType;
    params.collectionData = content;
    params.uniqueId = model.message.messageServerId;
    [[ChatRepo shared] addCollection:params completion:^(id collection, NSError *error) { completion(error); }];
}

- (void)voiceToText:(MessageContentModel *)model completion:(void (^)(NSString *_Nullable, NSError *_Nullable))completion {
    [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    V2NIMMessageAudioAttachment *attachment = (V2NIMMessageAudioAttachment *)model.message.attachment;
    if (!attachment) return;
    V2NIMVoiceToTextParams *params = [[V2NIMVoiceToTextParams alloc] init];
    params.duration = attachment.duration;
    if (attachment.url) params.voiceUrl = attachment.url;
    else if (attachment.path && [[NSFileManager defaultManager] fileExistsAtPath:attachment.path]) params.voicePath = attachment.path;
    __weak typeof(self) weakSelf = self;
    [[ChatRepo shared] voiceToText:params completion:^(NSString *text, NSError *error) {
        completion(text, error);
        if (text.length > 0 && [model isKindOfClass:[MessageAudioModel class]]) {
            MessageAudioModel *m = (MessageAudioModel *)model;
            m.text = text;
            for (NSInteger i = 0; i < weakSelf.messages.count; i++) {
                id<MessageModel> currentModel = weakSelf.messages[i];
                if ([currentModel isKindOfClass:[MessageAudioModel class]] && currentModel == m) {
                    [weakSelf.delegate onMessageStatusChange:currentModel.message atIndexs:@[[NSIndexPath indexPathForRow:i inSection:0]]];
                    break;
                }
            }
        }
    }];
}

- (void)stopAIStreamMessage:(V2NIMMessage *)message {
    [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    __weak typeof(self) weakSelf = self;
    [[ChatRepo shared] stopAIStreamMessage:message completion:^(NSError *error) {
        if ([weakSelf.delegate respondsToSelector:@selector(showErrorToast:defaultToast:)]) {
            [weakSelf.delegate showErrorToast:error defaultToast:chatLocalizable(@"request_exception")];
        }
    }];
}

- (void)regenAIMessage:(V2NIMMessage *)message {
    [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    __weak typeof(self) weakSelf = self;
    [[ChatRepo shared] regenAIMessage:message completion:^(NSError *error) {
        if ([weakSelf.delegate respondsToSelector:@selector(showErrorToast:defaultToast:)]) {
            [weakSelf.delegate showErrorToast:error defaultToast:chatLocalizable(@"request_exception")];
        }
    }];
}

- (BOOL)getHandSetEnable {
    return [[SettingRepo shared] getHandsetMode];
}

- (void)setHandSetEnable:(BOOL)ear {
    [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    [[SettingRepo shared] setHandsetMode:ear];
}

- (NSInteger)removeLocalPinMessage:(V2NIMMessage *)message {
    for (NSInteger i = 0; i < self.messages.count; i++) {
        if ([message.messageClientId isEqualToString:self.messages[i].message.messageClientId] && self.messages[i].isPined) {
            self.messages[i].isPined = NO;
            self.messages[i].pinAccount = nil;
            return i;
        }
    }
    return -1;
}

- (void)sendingMsg:(V2NIMMessage *)message {
    [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s, messageClientId: %@", __FUNCTION__, message.messageClientId]];
    if (![self isCurrentConversationMessage:message]) return;
    V2NIMMessage *pendingSuccess = [self pendingSendSuccessMessageForClientId:message.messageClientId];
    V2NIMMessage *displayMessage = pendingSuccess ?: message;
    for (NSInteger i = 0; i < self.messages.count; i++) {
        if ([self isSameSendingMessage:message asMessage:self.messages[i].message]) {
            if (self.messages[i].message.sendingState == V2NIM_MESSAGE_SENDING_STATE_SUCCEEDED &&
                message.sendingState == V2NIM_MESSAGE_SENDING_STATE_SENDING) {
                [self.delegate sendSuccess:self.messages[i].message index:[NSIndexPath indexPathForRow:i inSection:0]];
                return;
            }
            self.messages[i].message = displayMessage;
            [self removePendingSendSuccessMessageWithClientId:message.messageClientId];
            [self.delegate sendSuccess:displayMessage index:[NSIndexPath indexPathForRow:i inSection:0]];
            return;
        }
    }
    if (self.newMsg == nil) self.newMsg = displayMessage;
    id<MessageModel> model = [self modelFromMessage:displayMessage];
    [ChatMessageHelper addTimeMessage:model lastModel:self.messages.lastObject];
    NSInteger index = [self insertToMessages:model];
    [self removePendingSendSuccessMessageWithClientId:message.messageClientId];
    if (self.isHistoryChat) {
        if ([self.delegate respondsToSelector:@selector(dataReload)]) [self.delegate dataReload];
    } else {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        [self.delegate sending:displayMessage index:indexPath];
        if (pendingSuccess) {
            [self.delegate sendSuccess:displayMessage index:indexPath];
        }
    }
}

- (void)sendMsgSuccess:(V2NIMMessage *)message {
    [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    NSInteger fallbackIndex = NSNotFound;
    BOOL isCurrentMessage = [self isCurrentConversationMessage:message];
    if (!isCurrentMessage) {
        fallbackIndex = [self indexOfFallbackSendingMessageForSendResult:message];
    }
    if (fallbackIndex == NSNotFound && !isCurrentMessage) {
        [self cachePendingSendSuccessMessage:message];
        return;
    }
    NSInteger failedIndex = -1;
    NSInteger index = -1;
    for (NSInteger i = 0; i < self.messages.count; i++) {
        id<MessageModel> oldModel = self.messages[i];
        if ([self isSameSendingMessage:message asMessage:oldModel.message]) {
            if (self.messages[i].message.sendingState != V2NIM_MESSAGE_SENDING_STATE_SUCCEEDED) failedIndex = i;
            index = i;
            if (message.messageType == V2NIM_MESSAGE_TYPE_CALL) {
                self.messages[i] = [self modelFromMessage:message preservingModel:oldModel];
            } else {
                self.messages[i].message = message;
            }
            [self removePendingSendSuccessMessageWithClientId:message.messageClientId];
            break;
        }
    }
    if (index < 0 && fallbackIndex == NSNotFound) {
        fallbackIndex = [self indexOfFallbackSendingMessageForSendResult:message];
    }
    if (index < 0 && fallbackIndex != NSNotFound) {
        id<MessageModel> oldModel = self.messages[fallbackIndex];
        if (oldModel.message.sendingState != V2NIM_MESSAGE_SENDING_STATE_SUCCEEDED) {
            failedIndex = fallbackIndex;
        }
        index = fallbackIndex;
        self.messages[fallbackIndex] = [self modelFromMessage:message preservingModel:oldModel];
        [self removePendingSendSuccessMessageWithClientId:oldModel.message.messageClientId];
        [self removePendingSendSuccessMessageWithClientId:message.messageClientId];
    }
    if (index < 0) {
        [self cachePendingSendSuccessMessage:message];
        return;
    }
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    if (failedIndex >= 0) {
        indexPath = [NSIndexPath indexPathForRow:failedIndex inSection:0];
        if (failedIndex != self.messages.count - 1) {
            for (NSInteger i = 0; i < self.messages.count; i++) {
                if (message.createTime < self.messages[i].message.createTime) {
                    if (i - 1 != failedIndex) {
                        NSInteger toIndex = i;
                        [self exchangeMessageModel:failedIndex toIndex:toIndex];
                        [self.delegate sendSuccess:message index:[NSIndexPath indexPathForRow:toIndex inSection:0]];
                        return;
                    }
                    else break;
                } else if (i == self.messages.count - 1) {
                    if (i != failedIndex) {
                        NSInteger toIndex = i;
                        [self exchangeMessageModel:failedIndex toIndex:toIndex];
                        [self.delegate sendSuccess:message index:[NSIndexPath indexPathForRow:toIndex inSection:0]];
                        return;
                    }
                }
            }
        }
    }
    if (indexPath.row >= 0) [self.delegate sendSuccess:message index:indexPath];
}

- (void)sendMsgFailed:(V2NIMMessage *)message error:(nullable NSError *)error {
    if (!message.messageClientId) return;
    [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s, messageClientId: %@", __FUNCTION__, message.messageClientId]];
    if (error) {
        if (error.code == inBlackListCode && message.conversationId) {
            if ([[ChatDeduplicationHelper instance] isBlackTipSended:message.messageClientId]) return;
            __weak typeof(self) weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf insertTipMessage:chatLocalizable(@"black_list_tip") createTime:@(message.createTime + 1) conversationId:message.conversationId senderId:nil];
                if ([message.conversationId isEqualToString:weakSelf.conversationId]) {
                    [weakSelf sendMsgSuccess:message];
                }
            });
            return;
        }
    } else {
        [self sendMsgSuccess:message];
    }
}

- (void)exchangeMessageModel:(NSInteger)fromIndex toIndex:(NSInteger)toIndex {
    if (fromIndex < 0 || fromIndex >= self.messages.count ||
        toIndex < 0 || toIndex >= self.messages.count) {
        return;
    }
    id<MessageModel> resendModel = self.messages[fromIndex];
    if (fromIndex + 1 < self.messages.count) {
        [ChatMessageHelper addTimeMessage:self.messages[fromIndex + 1] lastModel:fromIndex > 0 ? self.messages[fromIndex - 1] : nil];
    }
    if (toIndex > 0) [ChatMessageHelper addTimeMessage:resendModel lastModel:self.messages[toIndex]];
    if (toIndex + 1 < self.messages.count) [ChatMessageHelper addTimeMessage:self.messages[toIndex + 1] lastModel:resendModel];
    [self.messages removeObjectAtIndex:fromIndex];
    [self.messages insertObject:resendModel atIndex:toIndex];
    [self.delegate onResendSuccess:[NSIndexPath indexPathForRow:fromIndex inSection:0] toIndexPath:[NSIndexPath indexPathForRow:toIndex inSection:0]];
}

- (void)setErrorText:(nullable V2NIMMessage *)message {
    if (!message) return;
    NSString *content = [ChatMessageHelper getAIErrorMessage:message.messageStatus.errorCode];
    if (content) message.text = content;
}

- (void)modifyMessage:(V2NIMMessage *)message params:(V2NIMModifyMessageParams *)params completion:(void (^)(V2NIMMessage *_Nullable, NSError *_Nullable))completion {
    __weak typeof(self) weakSelf = self;
    [[ChatRepo shared] modifyMessage:message params:params completion:^(V2NIMMessage *resultMessage, NSError *error) {
        if (resultMessage) [weakSelf modifyMessageUpdateUI:resultMessage];
        completion(resultMessage, error);
    }];
}

- (void)modifyMessageUpdateUI:(V2NIMMessage *)modifyMessage {
    for (NSInteger i = 0; i < self.messages.count; i++) {
        if ([self.messages[i] isKindOfClass:[MessageContentModel class]]) {
            MessageContentModel *model = (MessageContentModel *)self.messages[i];
            if ([model.message.messageClientId isEqualToString:modifyMessage.messageClientId]) {
                [model resetMessage:modifyMessage];
                if ([self.delegate respondsToSelector:@selector(getMessageModel:)]) [self.delegate getMessageModel:model];
                self.messages[i] = model;
                [self.delegate onModefiedMessage:[NSIndexPath indexPathForRow:i inSection:0]];
                break;
            }
        }
    }
}

- (void)translateLanguage:(NSString *)sourceText targetLanguage:(NSString *)targetLanguage completion:(void (^)(NSError *_Nullable))completion {
    [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"translateLanguage ai translate source : %@", sourceText]];

    V2NIMProxyAIModelCallParams *request = [[V2NIMProxyAIModelCallParams alloc] init];
    self.translationLanguageRequestId = [[NSUUID UUID] UUIDString];
    request.requestId = self.translationLanguageRequestId;

    V2NIMAIModelCallContent *content = [[V2NIMAIModelCallContent alloc] init];
    content.msg = sourceText;
    content.type = V2NIM_AI_MODEL_CONTENT_TYPE_TEXT;
    request.content = content;

    V2NIMAIModelConfigParams *configParams = [[V2NIMAIModelConfigParams alloc] init];
    configParams.temperature = [[NEAIUserManager shared] getTranslateTemperature];
    request.modelConfigParams = configParams;

    if (self.translationAIUser.accountId) {
        request.accountId = self.translationAIUser.accountId;
    }

    NSString *promptKey = [[NEAIUserManager shared] getTranslatePromptKey];
    NSDictionary *promptVariables = @{promptKey: targetLanguage};
    NSString *jsonString = [self getJSONStringFromDictionary:promptVariables];
    request.promptVariables = jsonString;

    [[AIRepo shared] proxyAIModelCall:request completion:^(NSError *error) {
        completion(error);
    }];
}

#pragma mark - Helper

- (NSDictionary *)getDictionaryFromJSONString:(NSString *)jsonString {
    return [NECommonUtil getDictionaryFromJSONString:jsonString];
}

- (NSString *)getJSONStringFromDictionary:(NSDictionary *)dictionary {
    return [NECommonUtil getJSONStringFromDictionary:dictionary];
}

#pragma mark - NEMessageListener

- (MessageSendParams *)beforeSend:(MessageSendParams *)param {
    if ([self.delegate respondsToSelector:@selector(beforeSend:)]) return [self.delegate beforeSend:param];
    return param;
}

- (void)beforeSendAsync:(MessageSendParams *)param completion:(void (^)(MessageSendParams *_Nullable))completion {
    if ([self.delegate respondsToSelector:@selector(beforeSendAsync:completion:)]) {
        [self.delegate beforeSendAsync:param completion:completion];
    } else {
        completion(param);
    }
}

- (void)sendMessageCallback:(nullable V2NIMSendMessageResult *)result error:(nullable NSError *)error progress:(NSUInteger)progress {
    if ([self.delegate respondsToSelector:@selector(sendMessageCallback:error:progress:)]) {
        [self.delegate sendMessageCallback:result error:error progress:progress];
    }
}

#pragma mark - NEChatListener

- (void)onSendMessage:(V2NIMMessage *)message {
    if (!NSThread.isMainThread) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf onSendMessage:message];
        });
        return;
    }
    switch (message.sendingState) {
        case V2NIM_MESSAGE_SENDING_STATE_SENDING: [self sendingMsg:message]; break;
        case V2NIM_MESSAGE_SENDING_STATE_FAILED: [self sendMsgFailed:message error:nil]; break;
        case V2NIM_MESSAGE_SENDING_STATE_SUCCEEDED: [self sendMsgSuccess:message]; break;
        default: break;
    }
}

- (void)sendMessageFailed:(V2NIMMessage *)message error:(NSError *)error {
    [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s, messageClientId: %@, error: %@", __FUNCTION__, message.messageClientId, error.localizedDescription]];
    [self sendMsgFailed:message error:error];
}

- (void)onReceiveMessages:(NSArray<V2NIMMessage *> *)messages {
    [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s, messages.count: %lu", __FUNCTION__, (unsigned long)messages.count]];
    for (V2NIMMessage *msg in messages) {
        if (![msg.conversationId isEqualToString:[ChatRepo conversationId]]) continue;
        if (!(msg.messageServerId.length > 0) && msg.messageType != V2NIM_MESSAGE_TYPE_CUSTOM) continue;
        if (msg.messageClientId && [self.messageClientIds containsObject:msg.messageClientId]) continue;
        if ([ChatMessageHelper isRevokeMessage:msg]) continue;
        if (self.isHistoryChat) { [self.delegate onRecvMessages:messages indexs:@[]]; return; }
        self.newMsg = msg;
        if ([ChatMessageHelper isAISender:msg]) [self setErrorText:msg];
        __weak typeof(self) weakSelf = self;
        [self modelFromMessage:msg completion:^(id<MessageModel> model) {
            [ChatMessageHelper addTimeMessage:model lastModel:weakSelf.messages.lastObject];
            [weakSelf downloadAudioFile:@[model]];
            [weakSelf loadReply:model completion:^{
                if (msg.messageClientId.length > 0 && ![weakSelf.messageClientIds containsObject:msg.messageClientId]) {
                    [weakSelf.messageClientIds addObject:msg.messageClientId];
                }
                NSInteger index = [weakSelf insertToMessages:model];
                if (index >= 0) {
                    [weakSelf.delegate onRecvMessages:@[msg] indexs:@[[NSIndexPath indexPathForRow:index inSection:0]]];
                }
                [weakSelf loadMoreWithMessage:@[msg]];
            }];
        }];
    }
}

- (void)onReceiveMessagesModified:(NSArray<V2NIMMessage *> *)messages {
    NSArray<V2NIMMessage *> *messageSnapshot = [messages copy];
    for (V2NIMMessage *msg in messageSnapshot) {
        if (![[V2NIMConversationIdUtil conversationTargetId:msg.conversationId ?: @""] isEqualToString:[ChatRepo sessionId]]) return;
        for (NSInteger i = 0; i < self.messages.count; i++) {
            id<MessageModel> currentModel = self.messages[i];
            if ([currentModel isKindOfClass:[MessageContentModel class]]) {
                MessageContentModel *model = (MessageContentModel *)currentModel;
                if ([model.message.messageClientId isEqualToString:msg.messageClientId]) {
                    [model resetMessage:msg];
                    if (i > 0) [ChatMessageHelper addTimeMessage:model lastModel:self.messages[i - 1]];
                    if ([self.delegate respondsToSelector:@selector(getMessageModel:)]) [self.delegate getMessageModel:model];
                    self.messages[i] = model;
                    [self.delegate onModefiedMessage:[NSIndexPath indexPathForRow:i inSection:0]];
                    break;
                }
            }
        }
    }
}

- (void)onMessageRevokeNotifications:(NSArray<V2NIMMessageRevokeNotification *> *)revokeNotifications {
    NSArray<V2NIMMessageRevokeNotification *> *notificationSnapshot = [revokeNotifications copy];
    for (V2NIMMessageRevokeNotification *revokeNoti in notificationSnapshot) {
        if (![revokeNoti.messageRefer.conversationId isEqualToString:[ChatRepo conversationId]]) continue;
        if (revokeNoti.messageRefer.messageClientId.length == 0) continue;
        if ([self.topMessage.messageClientId isEqualToString:revokeNoti.messageRefer.messageClientId]) {
            self.topMessage = nil;
            [self.delegate setTopValueWithName:nil content:nil url:nil isVideo:NO hideClose:NO];
        }
        NSArray<id<MessageModel> > *messageSnapshot = [self.messages copy];
        for (id<MessageModel> model in messageSnapshot) {
            if (![model.message.messageClientId isEqualToString:revokeNoti.messageRefer.messageClientId]) {
                continue;
            }
            if (!model.isRevoked) {
                model.message.localExtension = revokeNoti.serverExtension;
                [self revokeMessageUpdateUI:model.message];
            }
            break;
        }
    }
}

- (void)onMessageDeletedNotifications:(NSArray<V2NIMMessageDeletedNotification *> *)messageDeletedNotification {
    NSMutableArray *deleteMessages = [NSMutableArray array];
    NSArray<V2NIMMessageDeletedNotification *> *notificationSnapshot = [messageDeletedNotification copy];
    for (V2NIMMessageDeletedNotification *notification in notificationSnapshot) {
        if (![notification.messageRefer.conversationId isEqualToString:[ChatRepo conversationId]]) continue;
        if (notification.messageRefer.messageClientId.length == 0) continue;
        if ([self.topMessage.messageClientId isEqualToString:notification.messageRefer.messageClientId]) {
            self.topMessage = nil;
            [self.delegate setTopValueWithName:nil content:nil url:nil isVideo:NO hideClose:NO];
        }
        NSArray<id<MessageModel> > *messageSnapshot = [self.messages copy];
        for (id<MessageModel> model in messageSnapshot) {
            if ([model.message.messageClientId isEqualToString:notification.messageRefer.messageClientId]) {
                [deleteMessages addObject:model.message]; break;
            }
        }
    }
    [self deleteMessageUpdateUI:deleteMessages];
}

- (void)onClearHistoryNotifications:(NSArray *)clearHistoryNotification {
    [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s, count: %lu", __FUNCTION__, (unsigned long)clearHistoryNotification.count]];
}
- (void)onMessagePinNotification:(V2NIMMessagePinNotification *)pinNotification {
    [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"onMessagePinNotification, messageId:%@, pinStatus:%ld", pinNotification.pin.messageRefer.messageClientId, (long)pinNotification.pinState]];

    if (pinNotification.pinState == V2NIM_MESSAGE_PIN_STEATE_PINNED) {
        // 置顶
        NSInteger index = -1;
        for (NSInteger i = 0; i < self.messages.count; i++) {
            id<MessageModel> model = self.messages[i];
            if ([self isMessage:model.message matchedWithRefer:pinNotification.pin.messageRefer]) {
                model.isPined = YES;
                NSString *pinID = pinNotification.pin.operatorId ?: [[IMKitClient instance] account];
                model.pinAccount = pinID;

                NEUserWithFriend *userCache = [ChatMessageHelper getUserFromCache:pinID];
                if (userCache) {
                    model.pinShowName = [self getShowName:pinID showAlias:YES];
                } else {
                    __weak typeof(self) weakSelf = self;
                    NSString *messageServerId = model.message.messageServerId;
                    NSString *messageClientId = model.message.messageClientId;
                    [self loadShowName:@[pinID] teamId:[ChatRepo sessionId] completion:^{
                        NSInteger currentIndex = -1;
                        for (NSInteger j = 0; j < weakSelf.messages.count; j++) {
                            id<MessageModel> currentModel = weakSelf.messages[j];
                            BOOL sameServerId = messageServerId.length > 0 &&
                                [messageServerId isEqualToString:currentModel.message.messageServerId];
                            BOOL sameClientId = messageClientId.length > 0 &&
                                [messageClientId isEqualToString:currentModel.message.messageClientId];
                            if (sameServerId || sameClientId) {
                                currentIndex = j;
                                break;
                            }
                        }
                        if (currentIndex >= 0 && currentIndex < weakSelf.messages.count) {
                            weakSelf.messages[currentIndex].pinShowName = [weakSelf getShowName:pinID showAlias:YES];
                            V2NIMMessage *msg = weakSelf.messages[currentIndex].message;
                            if (msg) {
                                [weakSelf.delegate onMessageStatusChange:msg atIndexs:@[[NSIndexPath indexPathForRow:currentIndex inSection:0]]];
                            }
                        }
                    }];
                }
                index = i;
                break;
            }
        }
        if (index >= 0) {
            V2NIMMessage *msg = self.messages[index].message;
            if (msg) {
                [self.delegate onMessageStatusChange:msg atIndexs:@[[NSIndexPath indexPathForRow:index inSection:0]]];
            }
        }
    } else if (pinNotification.pinState == V2NIM_MESSAGE_PIN_STEATE_NOT_PINNED) {
        // 取消置顶
        NSInteger index = -1;
        for (NSInteger i = 0; i < self.messages.count; i++) {
            id<MessageModel> model = self.messages[i];
            if ([self isMessage:model.message matchedWithRefer:pinNotification.pin.messageRefer]) {
                if (!model.isPined) {
                    return;
                }
                model.isPined = NO;
                model.pinAccount = nil;
                model.pinShowName = nil;
                index = i;
                break;
            }
        }
        if (index >= 0) {
            V2NIMMessage *msg = self.messages[index].message;
            if (msg) {
                [self.delegate onMessageStatusChange:msg atIndexs:@[[NSIndexPath indexPathForRow:index inSection:0]]];
            }
        }
    }
}
- (void)onMessageQuickCommentNotification:(V2NIMMessageQuickCommentNotification *)notification {
    [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s, quickComment.index: %ld", __FUNCTION__, (long)notification.quickComment.index]];
}

- (void)onReceiveP2PMessageReadReceipts:(NSArray<V2NIMP2PMessageReadReceipt *> *)readReceipts {
    NSMutableArray<NSIndexPath *> *reloadIndexPaths = [NSMutableArray array];
    for (V2NIMP2PMessageReadReceipt *readReceipt in readReceipts) {
        if (![readReceipt.conversationId isEqualToString:[ChatRepo conversationId]]) continue;
        for (NSInteger i = 0; i < self.messages.count; i++) {
            id<MessageModel> model = self.messages[i];
            if (![ChatMessageHelper isSelf:model.message]) continue;
            if (model.message.messageConfig.readReceiptEnabled == NO) continue;
            if (model.message.createTime <= readReceipt.timestamp) {
                if (model.readCount == 1 && model.unreadCount == 0) continue;
                model.readCount = 1; model.unreadCount = 0;
                [reloadIndexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
            }
        }
    }
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.delegate onLoadMoreWithMessage:reloadIndexPaths];
    });
}

- (void)onReceiveTeamMessageReadReceipts:(NSArray<V2NIMTeamMessageReadReceipt *> *)readReceipts {
    NSMutableArray<NSIndexPath *> *reloadIndexPaths = [NSMutableArray array];
    for (V2NIMTeamMessageReadReceipt *readReceipt in readReceipts) {
        if (![readReceipt.conversationId isEqualToString:[ChatRepo conversationId]]) continue;
        for (NSInteger i = 0; i < self.messages.count; i++) {
            id<MessageModel> model = self.messages[i];
            if (![ChatMessageHelper isSelf:model.message]) continue;
            if (model.message.messageConfig.readReceiptEnabled == NO) continue;
            if ([model.message.messageClientId isEqualToString:readReceipt.messageClientId]) {
                if (model.readCount == readReceipt.readCount && model.unreadCount == readReceipt.unreadCount) continue;
                model.readCount = readReceipt.readCount; model.unreadCount = readReceipt.unreadCount;
                [reloadIndexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
            }
        }
    }
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.delegate onLoadMoreWithMessage:reloadIndexPaths];
    });
}

#pragma mark - V2NIMAIListener

- (void)onProxyAIModelCall:(V2NIMAIModelCallResult *)data {
    if (data.code == self.aiUserRequestSuccess) {
        if ([data.requestId isEqualToString:self.translationLanguageRequestId]) {
            if ([self.delegate respondsToSelector:@selector(didTranslateResult:)]) {
                [self.delegate didTranslateResult:data.content.msg];
            }
            [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s ai translate result : %@", __FUNCTION__, data.content.msg]];
        }
    }
}

@end
