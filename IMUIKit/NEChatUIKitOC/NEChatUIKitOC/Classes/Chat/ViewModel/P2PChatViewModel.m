// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "P2PChatViewModel.h"
#import <NEChatKitOC/NEChatKitOC.h>
#import <NEChatKitOC/NECoreIM2KitOC.h>
#import <NEChatKitOC/NEALog.h>
#import "NEChatUIConstant.h"
#import "NEP2PChatUserCache.h"
#import "ChatUIConfig.h"
#import "ChatMessageHelper.h"

static NSString *const TAG = @"P2PChatViewModel";

@implementation P2PChatViewModel

- (instancetype)initWithConversationId:(NSString *)conversationId {
    return [super initWithConversationId:conversationId];
}

- (instancetype)initWithConversationId:(NSString *)conversationId anchor:(nullable V2NIMMessage *)anchor {
    return [super initWithConversationId:conversationId anchor:anchor];
}

- (void)dealloc {
    [[ChatRepo shared] removeNotiListener:self];
    if ([IMKitConfigCenter shared].enableOnlineStatus) {
        [[SubscribeRepo shared] removeListener:self];
    }
}

- (void)addListener {
    [super addListener];
    [[ChatRepo shared] addNotiListener:self];
    if ([IMKitConfigCenter shared].enableOnlineStatus) {
        [[SubscribeRepo shared] addListener:self];
        [self subscribeOnlineStatus];
    }
}

- (NSString *)getShowName:(NSString *)accountId showAlias:(BOOL)showAlias {
    if ([[NEFriendUserCache shared] isFriend:accountId]) {
        return [[NEFriendUserCache shared] getShowName:accountId showAlias:showAlias];
    } else {
        return [[NEP2PChatUserCache shared] getShowName:accountId showAlias:showAlias];
    }
}

- (void)loadShowName:(NSArray<NSString *> *)accountIds teamId:(nullable NSString *)teamId completion:(void (^)(void))completion {
    [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s, count: %lu", __FUNCTION__, (unsigned long)accountIds.count]];
    [[NEFriendUserCache shared] loadShowName:accountIds showAlias:YES completion:^(NSArray<NEUserWithFriend *> *users) {
        for (NEUserWithFriend *user in users ?: @[]) {
            NSString *uid = user.user.accountId;
            if (uid && ![[NEFriendUserCache shared] isFriend:uid]) {
                [[NEP2PChatUserCache shared] updateUserInfoWithFriend:user];
            }
        }
        completion();
    }];
}

- (void)markRead:(NSArray<V2NIMMessage *> *)messages completion:(void (^)(NSError *_Nullable))completion {
    [self markReadInP2P:messages completion:completion];
}

- (void)markReadInP2P:(NSArray<V2NIMMessage *> *)messages completion:(void (^)(NSError *_Nullable))completion {
    [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s, messages.count: %lu", __FUNCTION__, (unsigned long)messages.count]];
    if (![ChatUIConfig shared].messageProperties.showP2PMessageStatus) {
        completion(nil); return;
    }
    NSArray *sorted = [messages sortedArrayUsingComparator:^NSComparisonResult(V2NIMMessage *m1, V2NIMMessage *m2) {
        return m1.createTime > m2.createTime ? NSOrderedAscending : NSOrderedDescending;
    }];
    for (V2NIMMessage *message in sorted) {
        if (!message.isSelf && message.messageStatus.readReceiptSent == NO) {
            [[ChatRepo shared] markP2PMessageRead:message completion:^(V2NIMP2PMessageReadReceipt *receipt, NSError *error) {
                completion(error);
            }];
            return;
        }
    }
    completion(nil);
}

- (void)getMessageReceipts:(NSArray<V2NIMMessage *> *)messages completion:(void (^)(NSArray<NSIndexPath *> *, NSError *_Nullable))completion {
    [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s, messages.count: %lu", __FUNCTION__, (unsigned long)messages.count]];
    if ([ChatUIConfig shared].messageProperties.showP2PMessageStatus) {
        [self getP2PMessageReceipt:messages completion:completion];
    } else {
        completion(@[], nil);
    }
}

- (void)getP2PMessageReceipt:(NSArray<V2NIMMessage *> *)messages completion:(void (^)(NSArray<NSIndexPath *> *, NSError *_Nullable))completion {
    [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    [[ChatRepo shared] getP2PMessageReceipt:[ChatRepo conversationId] completion:^(V2NIMP2PMessageReadReceipt *readReceipt, NSError *error) {
        if (readReceipt) {
            NSMutableArray<NSIndexPath *> *reloadIndexs = [NSMutableArray array];
            for (NSInteger i = 0; i < self.messages.count; i++) {
                id<MessageModel> model = self.messages[i];
                if ([ChatMessageHelper isSelf:model.message] == NO) continue;
                if (model.message.messageConfig.readReceiptEnabled == NO) continue;
                if (model.message.createTime <= readReceipt.timestamp) {
                    if (model.readCount == 1 && model.unreadCount == 0) continue;
                    model.readCount = 1; model.unreadCount = 0;
                    [reloadIndexs addObject:[NSIndexPath indexPathForRow:i inSection:0]];
                }
            }
            completion(reloadIndexs, error);
        } else {
            completion(@[], error);
        }
    }];
}

- (void)sendInputTypingState {
    [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    if ([V2NIMConversationIdUtil conversationType:[ChatRepo conversationId]] == V2NIM_CONVERSATION_TYPE_P2P) {
        [self setTypingCustom:1];
    }
}

- (void)sendInputTypingEndState {
    [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    if ([V2NIMConversationIdUtil conversationType:[ChatRepo conversationId]] == V2NIM_CONVERSATION_TYPE_P2P) {
        [self setTypingCustom:0];
    }
}

- (void)setTypingCustom:(NSInteger)typing {
    [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s, typing: %ld", __FUNCTION__, (long)typing]];
    NSString *content = getJSONStringFromDictionary(@{@"typing": @(typing)});
    [[ChatRepo shared] sendCustomNotification:[ChatRepo conversationId] data:content completion:^(NSError *error) {
        if (error) NSLog(@"send noti success: %@", error);
    }];
}

#pragma mark - NESubscribeListener

- (void)subscribeOnlineStatus {
    if (![IMKitConfigCenter shared].enableOnlineStatus) return;
    if ([[NEAIUserManager shared] isAIUser:[ChatRepo sessionId]]) return;
    V2NIMUserStatus *event = [[NESubscribeManager shared] getSubscribeStatus:[ChatRepo sessionId]];
    if (event) {
        self.online = (event.statusType == V2NIM_USER_STATUS_TYPE_LOGIN);
        [self.delegate remoteUserOnlineChanged];
        return;
    }
    [[NESubscribeManager shared] subscribeUsersOnlineState:@[[ChatRepo sessionId]] completion:^(NSError *error) {}];
}

- (void)unsubscribeOnlineStatus {
    [[NESubscribeManager shared] unSubscribeUsersOnlineState:@[[ChatRepo sessionId]] completion:^(NSError *error) {}];
}

- (void)onUserStatusChanged:(NSArray<V2NIMUserStatus *> *)data {
    for (V2NIMUserStatus *d in data) {
        if ([d.accountId isEqualToString:[ChatRepo sessionId]]) {
            self.online = (d.statusType == V2NIM_USER_STATUS_TYPE_LOGIN);
            [self.delegate remoteUserOnlineChanged];
            break;
        }
    }
}

#pragma mark - NENotiListener

- (void)onReceiveCustomNotifications:(NSArray<V2NIMCustomNotification *> *)customNotifications {
    [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s, count: %lu", __FUNCTION__, (unsigned long)customNotifications.count]];
    if ([V2NIMConversationIdUtil conversationType:[ChatRepo conversationId]] != V2NIM_CONVERSATION_TYPE_P2P) return;
    for (V2NIMCustomNotification *notification in customNotifications) {
        if (![notification.senderId isEqualToString:[ChatRepo sessionId]]) continue;
        if (notification.content) {
            NSDictionary *dic = getDictionaryFromJSONString(notification.content);
            NSNumber *typing = dic[@"typing"];
            if (typing) {
                if (typing.integerValue == 1) {
                    [self.delegate remoteUserEditing];
                } else {
                    [self.delegate remoteUserEndEditing];
                }
            }
        }
    }
}

#pragma mark - NEIMKitClientListener

- (void)onConnectStatus:(V2NIMConnectStatus)status {
    if (status == V2NIM_CONNECT_STATUS_WAITING) {
        self.networkBroken = YES;
    }
    if (status == V2NIM_CONNECT_STATUS_CONNECTED && self.networkBroken) {
        self.networkBroken = NO;
        __weak typeof(self) weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf subscribeOnlineStatus];
        });
    }
}

@end
