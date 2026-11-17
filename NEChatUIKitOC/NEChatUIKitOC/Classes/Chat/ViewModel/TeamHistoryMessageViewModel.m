// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <NEBaseUIKitOC/UIColor+NEUIKitDefault.h>
#import "TeamHistoryMessageViewModel.h"
#import <NEChatKit/NEChatKit.h>

#import <NEChatKit/UIColor+NECommon.h>
#import <NEBaseUIKitOC/NECommonUIConstant.h>
#import "NEChatUIConstant.h"
#import "OperationItem+NEChatUIKit.h"
#import "NEP2PChatUserCache.h"
#import "NETeamUserManager.h"
#import "ChatMessageHelper.h"
#import "MessageTextModel.h"
#import "MessageRichTextModel.h"
#import "MediaSectionModel.h"

static NSString *const TAG = @"TeamHistoryMessageViewModel";

@implementation TeamHistoryMessageViewModel

- (BOOL)isMessage:(V2NIMMessage *)message matchedWithRefer:(V2NIMMessageRefer *)messageRefer {
    if (!message || !messageRefer) return NO;
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

- (void)removeMessageFromFlatMessagesWithRefer:(V2NIMMessageRefer *)messageRefer {
    if (!messageRefer) return;
    for (NSInteger row = (NSInteger)self.messages.count - 1; row >= 0; row--) {
        id<MessageModel> model = self.messages[row];
        if ([self isMessage:model.message matchedWithRefer:messageRefer]) {
            [self.messages removeObjectAtIndex:row];
        }
    }
}

- (V2NIMMessage *)removeMediaMessageWithRefer:(V2NIMMessageRefer *)messageRefer
                                  revokedOnly:(BOOL)revokedOnly
                             removedIndexPath:(NSIndexPath **)removedIndexPath {
    if (removedIndexPath) *removedIndexPath = nil;
    if (!messageRefer) return nil;
    for (NSInteger section = (NSInteger)self.mediaMessageModels.count - 1; section >= 0; section--) {
        MediaSectionModel *sectionModel = self.mediaMessageModels[section];
        for (NSInteger item = (NSInteger)sectionModel.messageModels.count - 1; item >= 0; item--) {
            MessageContentModel *model = sectionModel.messageModels[item];
            if (![self isMessage:model.message matchedWithRefer:messageRefer]) continue;
            if (revokedOnly && model.isRevoked) continue;

            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:section];
            V2NIMMessage *message = model.message;
            [sectionModel.messageModels removeObjectAtIndex:item];
            [self removeMessageFromFlatMessagesWithRefer:messageRefer];
            if (sectionModel.messageModels.count == 0) {
                [self.mediaMessageModels removeObjectAtIndex:section];
            }
            if (removedIndexPath) *removedIndexPath = indexPath;
            return message;
        }
    }
    return nil;
}

- (instancetype)init {
    self = [super initWithConversationId:[ChatRepo conversationId]];
    if (self) {
        [self commonHistoryInit];
        [self getOperationTypes:[ChatRepo conversationId]];
    }
    return self;
}

- (instancetype)initWithConversationId:(NSString *)conversationId {
    self = [super initWithConversationId:conversationId];
    if (self) {
        [self commonHistoryInit];
        [self getOperationTypes:conversationId];
    }
    return self;
}

- (instancetype)initWithConversationId:(NSString *)conversationId anchor:(nullable V2NIMMessage *)anchor {
    self = [super initWithConversationId:conversationId anchor:anchor];
    if (self) {
        [self commonHistoryInit];
        [self getOperationTypes:conversationId];
    }
    return self;
}

- (void)commonHistoryInit {
    _operationTypes = [NSMutableArray array];
    _pageToken = @"";
    _allMessageShowTime = YES;
    _themeColor = UIColor.ne_defaultPrimaryColor;
    _mediaMessageModels = [NSMutableArray array];
}

- (void)getOperationTypes:(NSString *)conversationId {
    V2NIMConversationType sessionType = [V2NIMConversationIdUtil conversationType:conversationId];
    if (sessionType == V2NIM_CONVERSATION_TYPE_TEAM || sessionType == V2NIM_CONVERSATION_TYPE_SUPER_TEAM) {
        [self.operationTypes addObject:[OperationItem searchTeamMemberItem]];
    }
    [self.operationTypes addObject:[OperationItem searchImageItem]];
    [self.operationTypes addObject:[OperationItem searchVideoItem]];
    [self.operationTypes addObject:[OperationItem searchDateItem]];
    [self.operationTypes addObject:[OperationItem searchFileItem]];
}

- (void)loadShowName:(NSArray<NSString *> *)accountIds teamId:(nullable NSString *)teamId completion:(void (^)(void))completion {
    if ([V2NIMConversationIdUtil conversationType:[ChatRepo conversationId]] == V2NIM_CONVERSATION_TYPE_P2P) {
        [[NEFriendUserCache shared] loadShowName:accountIds showAlias:YES completion:^(NSArray<NEUserWithFriend *> *users) {
            for (NEUserWithFriend *user in users ?: @[]) {
                NSString *uid = user.user.accountId;
                if (uid && ![[NEFriendUserCache shared] isFriend:uid]) {
                    [[NEP2PChatUserCache shared] updateUserInfoWithFriend:user];
                }
            }
            completion();
        }];
    } else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[NETeamUserManager shared] getTeamMembers:accountIds notify:NO completion:completion];
        });
    }
}

- (NSString *)getShowName:(NSString *)accountId showAlias:(BOOL)showAlias {
    if ([V2NIMConversationIdUtil conversationType:[ChatRepo conversationId]] == V2NIM_CONVERSATION_TYPE_P2P) {
        if ([[NEFriendUserCache shared] isFriend:accountId]) {
            return [[NEFriendUserCache shared] getShowName:accountId showAlias:showAlias];
        } else {
            return [[NEP2PChatUserCache shared] getShowName:accountId showAlias:showAlias];
        }
    } else {
        return [[NETeamUserManager shared] getShowName:accountId showAlias:showAlias];
    }
}

- (void)searchHistoryMessages:(V2NIMMessageSearchExParams *)params firstSearch:(BOOL)firstSearch completion:(void (^)(NSError *_Nullable, NSInteger, BOOL))completion {
    params.pageToken = firstSearch ? @"" : self.pageToken;
    params.limit = 100;

    __weak typeof(self) weakSelf = self;
    void (^handleResult)(V2NIMMessageSearchResult *, NSError *) = ^(V2NIMMessageSearchResult *result, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;

        if (!error) {
            if (firstSearch) {
                strongSelf.pageToken = @"";
                [strongSelf.messages removeAllObjects];
                [strongSelf.mediaMessageModels removeAllObjects];
            }
            [strongSelf loadMessageModel:result params:params];
        }

        if (completion) completion(error, result.count, result.hasMore);
    };

    if ([IMKitConfigCenter shared].enableCloudMessageSearch) {
        [[ChatRepo shared] searchCloudMessagesExResult:params completion:^(V2NIMMessageSearchResult *result, NSError *error) {
            handleResult(result, error);
        }];
    } else {
        [[ChatRepo shared] searchLocalMessagesResult:params completion:^(V2NIMMessageSearchResult *result, NSError *error) {
            handleResult(result, error);
        }];
    }
}

- (void)loadMessageModel:(nullable V2NIMMessageSearchResult *)result params:(V2NIMMessageSearchExParams *)params {
    NSArray<V2NIMMessage *> *messagesList = result.items.firstObject.messages;
    if (!result || messagesList.count == 0) return;

    self.pageToken = result.nextPageToken;

    BOOL filterNoti = (params.senderAccountIds.count > 0);
    for (V2NIMMessage *msg in messagesList) {
        if (filterNoti && msg.messageType == V2NIM_MESSAGE_TYPE_NOTIFICATION) continue;
        if ([ChatMessageHelper isRevokeMessage:msg]) continue;
        if ([ChatMessageHelper isAISender:msg]) [self setErrorText:msg];
        id<MessageModel> model = [self modelFromMessage:msg];
        if (params.keywordList.count > 0) {
            NSString *keyword = params.keywordList.firstObject;
            if ([model isKindOfClass:[MessageTextModel class]]) {
                MessageTextModel *m = (MessageTextModel *)model;
                NSAttributedString *att = [ChatMessageHelper loadKeywordInMessage:msg attributeStr:m.attributeStr keyword:keyword themeColor:self.themeColor];
                if (att) m.attributeStr = [att mutableCopy];
            }
            if ([model isKindOfClass:[MessageRichTextModel class]]) {
                MessageRichTextModel *m = (MessageRichTextModel *)model;
                NSAttributedString *att = [ChatMessageHelper loadKeywordInMessage:msg attributeStr:m.titleAttributeStr keyword:keyword themeColor:self.themeColor];
                if (att) m.titleAttributeStr = [att mutableCopy];
            }
        }
        BOOL exists = NO;
        NSArray<id<MessageModel> > *messageSnapshot = [self.messages copy];
        for (id<MessageModel> m in messageSnapshot) {
            if ([m.message.messageClientId isEqualToString:model.message.messageClientId]) { exists = YES; break; }
        }
        if (!exists) [self.messages addObject:model];
    }
    if (self.allMessageShowTime) [self addTimeForHistoryMessage:NO];
    [self loadMoreWithMessage:messagesList];
}

- (void)addTimeForHistoryMessage:(BOOL)forward {
    NSArray<id<MessageModel> > *messageSnapshot = [self.messages copy];
    for (id<MessageModel> model in messageSnapshot) {
        double curTime = model.message.createTime;
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:curTime];
        model.timeContent = [ChatMessageHelper ne_stringFromDate:date];
    }
}

- (void)onReceiveMessages:(NSArray<V2NIMMessage *> *)messages {}

- (void)onMessageRevokeNotifications:(NSArray<V2NIMMessageRevokeNotification *> *)revokeNotifications {
    dispatch_async(dispatch_get_main_queue(), ^{
        for (V2NIMMessageRevokeNotification *revokeNoti in revokeNotifications) {
            if (![revokeNoti.messageRefer.conversationId isEqualToString:[ChatRepo conversationId]]) continue;
            if (revokeNoti.messageRefer.messageClientId.length == 0 &&
                revokeNoti.messageRefer.messageServerId.length == 0) continue;

            if (self.mediaMessageModels.count == 0 && self.messages.count > 0) {
                for (NSInteger row = 0; row < (NSInteger)self.messages.count; row++) {
                    id<MessageModel> model = self.messages[row];
                    if ([self isMessage:model.message matchedWithRefer:revokeNoti.messageRefer] && !model.isRevoked) {
                        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
                        [self.messages removeObjectAtIndex:row];
                        [self.delegate onRevokeMessage:model.message atIndexs:@[indexPath]];
                        break;
                    }
                }
            }

            if (self.mediaMessageModels.count > 0) {
                NSIndexPath *indexPath = nil;
                V2NIMMessage *message = [self removeMediaMessageWithRefer:revokeNoti.messageRefer revokedOnly:YES removedIndexPath:&indexPath];
                if (message && indexPath) {
                    [self.delegate onRevokeMessage:message atIndexs:@[indexPath]];
                }
            }
        }
    });
}

- (void)onMessageDeletedNotifications:(NSArray<V2NIMMessageDeletedNotification *> *)messageDeletedNotification {
    dispatch_async(dispatch_get_main_queue(), ^{
        for (V2NIMMessageDeletedNotification *deleteNoti in messageDeletedNotification) {
            if (![deleteNoti.messageRefer.conversationId isEqualToString:[ChatRepo conversationId]]) continue;
            if (deleteNoti.messageRefer.messageClientId.length == 0 &&
                deleteNoti.messageRefer.messageServerId.length == 0) continue;

            if (self.mediaMessageModels.count == 0 && self.messages.count > 0) {
                for (NSInteger row = 0; row < (NSInteger)self.messages.count; row++) {
                    id<MessageModel> model = self.messages[row];
                    if ([self isMessage:model.message matchedWithRefer:deleteNoti.messageRefer]) {
                        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
                        [self.messages removeObjectAtIndex:row];
                        [self.delegate onRevokeMessage:model.message atIndexs:@[indexPath]];
                        break;
                    }
                }
            }

            if (self.mediaMessageModels.count > 0) {
                NSIndexPath *indexPath = nil;
                V2NIMMessage *message = [self removeMediaMessageWithRefer:deleteNoti.messageRefer revokedOnly:NO removedIndexPath:&indexPath];
                if (message && indexPath) {
                    [self.delegate onRevokeMessage:message atIndexs:@[indexPath]];
                }
            }
        }
    });
}

- (void)searchHistryMediaMessages:(BOOL)firstLoad
                       searchType:(MessageType)searchType
                       completion:(void (^)(NSError *_Nullable error, NSInteger messageCount, BOOL hasMore))completion {
    V2NIMMessageSearchExParams *params = [[V2NIMMessageSearchExParams alloc] init];
    params.conversationId = [ChatRepo conversationId];
    params.limit = 100;

    switch (searchType) {
        case MessageTypeImage:
            params.messageTypes = @[@(V2NIM_MESSAGE_TYPE_IMAGE)];
            self.allMessageShowTime = NO;
            break;
        case MessageTypeVideo:
            params.messageTypes = @[@(V2NIM_MESSAGE_TYPE_VIDEO)];
            self.allMessageShowTime = NO;
            break;
        case MessageTypeFile:
            params.messageTypes = @[@(V2NIM_MESSAGE_TYPE_FILE)];
            self.allMessageShowTime = YES;
            break;
        default:
            params.messageTypes = @[@(V2NIM_MESSAGE_TYPE_IMAGE), @(V2NIM_MESSAGE_TYPE_VIDEO), @(V2NIM_MESSAGE_TYPE_FILE)];
            self.allMessageShowTime = YES;
            break;
    }

    __weak typeof(self) weakSelf = self;
    [self searchHistoryMessages:params firstSearch:firstLoad completion:^(NSError *error, NSInteger messageCount, BOOL hasMore) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        if (error) {
            if (completion) completion(error, messageCount, hasMore);
            return;
        }

        [strongSelf.mediaMessageModels removeAllObjects];
        NSMutableDictionary<NSString *, NSMutableArray<MessageContentModel *> *> *mediaMessageDic = [NSMutableDictionary dictionary];
        NSString *lastKey = nil;

        for (NSInteger index = 0; index < strongSelf.messages.count; index++) {
            id<MessageModel> baseModel = strongSelf.messages[index];
            if (![baseModel isKindOfClass:[MessageContentModel class]]) continue;
            MessageContentModel *model = (MessageContentModel *)baseModel;
            V2NIMMessage *message = model.message;
            if (!message) continue;

            NSDate *date = [NSDate dateWithTimeIntervalSince1970:message.createTime];
            NSString *timeText = [ChatMessageHelper ne_stringFromDate:date showHM:NO];
            if (searchType == MessageTypeFile) {
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                formatter.dateFormat = commonLocalizable(@"ym");
                timeText = [formatter stringFromDate:date];
            }

            NSMutableArray<MessageContentModel *> *models = mediaMessageDic[timeText];
            if (models) {
                if (searchType == MessageTypeFile) {
                    [models addObject:model];
                } else {
                    [models insertObject:model atIndex:0];
                }
            } else {
                mediaMessageDic[timeText] = [NSMutableArray arrayWithObject:model];
                if (lastKey.length > 0) {
                    NSArray<MessageContentModel *> *lastModels = mediaMessageDic[lastKey];
                    if (lastModels.count > 0) {
                        MediaSectionModel *sectionModel = [[MediaSectionModel alloc] init];
                        sectionModel.time = lastKey;
                        sectionModel.messageModels = [lastModels mutableCopy];
                        if (searchType == MessageTypeFile) {
                            [strongSelf.mediaMessageModels addObject:sectionModel];
                        } else {
                            [strongSelf.mediaMessageModels insertObject:sectionModel atIndex:0];
                        }
                        [mediaMessageDic removeObjectForKey:lastKey];
                    }
                }
                lastKey = timeText;
            }

            if (index == strongSelf.messages.count - 1) {
                NSArray<MessageContentModel *> *lastModels = mediaMessageDic[timeText];
                if (lastModels.count > 0) {
                    MediaSectionModel *sectionModel = [[MediaSectionModel alloc] init];
                    sectionModel.time = timeText;
                    sectionModel.messageModels = [lastModels mutableCopy];
                    if (searchType == MessageTypeFile) {
                        [strongSelf.mediaMessageModels addObject:sectionModel];
                    } else {
                        [strongSelf.mediaMessageModels insertObject:sectionModel atIndex:0];
                    }
                }
            }
        }

        if (completion) completion(error, messageCount, hasMore);
    }];
}

@end
