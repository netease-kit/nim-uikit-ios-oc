// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "TeamChatViewModel.h"
#import <NEChatKit/NEChatKit.h>
#import <NEChatKit/ChatConstant.h>

#import <NEChatKit/NECoreIM2Constant.h>
#import <NEChatKit/NEALog.h>

#import <NEBaseUIKitOC/NECommonUIConstant.h>
#import "NEChatUIConstant.h"
#import "NETeamUserManager.h"
#import "ChatMessageHelper.h"
#import "ChatUIConfig.h"
#import <NEChatKit/NIMExtension.h>

static NSString *const TAG = @"TeamChatViewModel";

@interface TeamChatViewModel ()
@property (nonatomic, assign) NSUInteger topMessageLoadGeneration;
@property (nonatomic, assign) BOOL teamNetworkBroken;
@property (nonatomic, assign) NSUInteger teamRefreshGeneration;
@property (nonatomic, assign) BOOL teamRefreshInFlight;
@property (nonatomic, assign) BOOL teamRefreshPending;
@property (nonatomic, copy, readonly) NSString *chatTeamId;
- (void)loadTopMessageWithExtension:(nullable NSString *)extension;
@end

@implementation TeamChatViewModel

- (instancetype)initWithConversationId:(NSString *)conversationId {
    return [super initWithConversationId:conversationId];
}

- (instancetype)initWithConversationId:(NSString *)conversationId anchor:(nullable V2NIMMessage *)anchor {
    return [super initWithConversationId:conversationId anchor:anchor];
}

- (void)dealloc {
    [[IMKitClient instance] removeLoginListener:self];
    [[TeamRepo shared] removeTeamListener:self];
    [[NETeamUserManager shared] removeListener:self];
}

- (void)addListener {
    [super addListener];
    [[IMKitClient instance] addLoginListener:self];
    [[TeamRepo shared] addTeamListener:self];
    [[NETeamUserManager shared] addListener:self];
    [[NETeamUserManager shared] loadData:self.chatTeamId];
}

- (NSString *)chatTeamId {
    return [V2NIMConversationIdUtil conversationTargetId:self.conversationId] ?: @"";
}

- (NSString *)getShowName:(NSString *)accountId showAlias:(BOOL)showAlias {
    return [[NETeamUserManager shared] getShowName:accountId showAlias:showAlias];
}

- (void)loadShowName:(NSArray<NSString *> *)accountIds teamId:(nullable NSString *)teamId completion:(void (^)(void))completion {
    [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s, teamId: %@", __FUNCTION__, teamId]];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[NETeamUserManager shared] getTeamMembers:accountIds notify:NO completion:completion];
    });
}

- (void)loadTopMessage {
    [self loadTopMessageWithExtension:self.team.serverExtension];
}

- (void)loadTopMessageWithExtension:(nullable NSString *)extension {
    NSUInteger generation = ++self.topMessageLoadGeneration;
    if (![IMKitConfigCenter shared].enableTopMessage) return;
    NSDictionary *extDic = extension ? getDictionaryFromJSONString(extension) : nil;
    NSDictionary *topInfo = extDic[keyTopMessage];
    if (![topInfo isKindOfClass:[NSDictionary class]]) {
        self.topMessage = nil;
        [self.delegate setTopValueWithName:nil content:nil url:nil isVideo:NO hideClose:NO];
        return;
    }
    NSInteger operation = [topInfo[@"operation"] integerValue];
    if (operation == 0) {
        V2NIMMessageRefer *refer = [ChatMessageHelper createMessageRefer:topInfo];
        __weak typeof(self) weakSelf = self;
        [[ChatRepo shared] getMessageListByRefers:@[refer] completion:^(NSArray<V2NIMMessage *> *messages, NSError *error) {
            if (!weakSelf || weakSelf.topMessageLoadGeneration != generation || error) return;
            V2NIMMessage *topMessage = messages.firstObject;
            if (topMessage) {
                NSString *senderId = [ChatMessageHelper getSenderId:topMessage];
                __block NSString *senderName = senderId ? [weakSelf getShowName:senderId showAlias:YES] : @"";
                dispatch_group_t group = dispatch_group_create();
                if ([senderName isEqualToString:senderId]) {
                    dispatch_group_enter(group);
                    [weakSelf loadShowName:@[senderId] teamId:[ChatRepo sessionId] completion:^{
                        senderName = [weakSelf getShowName:senderId showAlias:YES];
                        dispatch_group_leave(group);
                    }];
                }
                dispatch_group_notify(group, dispatch_get_main_queue(), ^{
                    if (!weakSelf || weakSelf.topMessageLoadGeneration != generation) return;
                    NSString *content = [ChatMessageHelper contentOfMessage:topMessage];
                    NSString *thumbUrl = nil;
                    BOOL isVideo = NO;
                    BOOL hideClose = YES;
                    if ([topMessage.attachment isKindOfClass:[V2NIMMessageImageAttachment class]]) {
                        V2NIMMessageImageAttachment *attach = (V2NIMMessageImageAttachment *)topMessage.attachment;
                        if (attach.url) thumbUrl = [V2NIMStorageUtil imageThumbUrl:attach.url thumbSize:[ChatUIConfig shared].imageThumbSize];
                    }
                    if ([topMessage.attachment isKindOfClass:[V2NIMMessageVideoAttachment class]]) {
                        V2NIMMessageVideoAttachment *attach = (V2NIMMessageVideoAttachment *)topMessage.attachment;
                        if (attach.url) { thumbUrl = [V2NIMStorageUtil videoCoverUrl:attach.url offset:0]; isVideo = YES; }
                    }
                    if ([weakSelf hasTopMessagePremission]) hideClose = NO;
                    [weakSelf.delegate setTopValueWithName:senderName content:content url:thumbUrl isVideo:isVideo hideClose:hideClose];
                    weakSelf.topMessage = topMessage;
                });
            } else {
                weakSelf.topMessage = nil;
                [weakSelf.delegate setTopValueWithName:nil content:nil url:nil isVideo:NO hideClose:NO];
            }
        }];
    } else {
        self.topMessage = nil;
        [self.delegate setTopValueWithName:nil content:nil url:nil isVideo:NO hideClose:NO];
    }
}

- (BOOL)hasTopMessagePremission {
    if ([self.team ne_isDisscuss]) return YES;
    if (self.teamMember.memberRole == V2NIM_TEAM_MEMBER_ROLE_OWNER ||
        self.teamMember.memberRole == V2NIM_TEAM_MEMBER_ROLE_MANAGER) {
        return YES;
    } else if (self.teamMember.memberRole == V2NIM_TEAM_MEMBER_ROLE_NORMAL) {
        if (self.team.serverExtension) {
            NSDictionary *json = getDictionaryFromJSONString(self.team.serverExtension);
            if (json) {
                NSString *atValue = json[keyAllowTopMessage];
                return [atValue isEqualToString:allowAtAllValue];
            }
        }
        return NO;
    }
    return NO;
}

- (void)topMessage:(void (^)(NSError *_Nullable))completion {
    [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    V2NIMMessage *message = self.operationModel.message;
    if (!message) return;
    NSDictionary *topMessageDic = @{
        @"idClient": message.messageClientId ?: [NSNull null],
        @"scene": @(message.conversationType),
        @"from": message.senderId ?: [NSNull null],
        @"receiverId": message.receiverId ?: [NSNull null],
        @"to": message.conversationId ?: [NSNull null],
        @"idServer": message.messageServerId ?: [NSNull null],
        @"time": @((NSInteger)(message.createTime * 1000)),
        @"operator": [[IMKitClient instance] account],
        @"operation": @(0),
    };
    __weak typeof(self) weakSelf = self;
    [[TeamRepo shared] getTeamInfo:[ChatRepo sessionId] teamType:V2NIM_TEAM_TYPE_NORMAL completion:^(V2NIMTeam *team, NSError *error) {
        if (error) { completion(error); return; }
        NSString *tid = [ChatRepo sessionId];
        if (![weakSelf hasTopMessagePremission]) {
            completion([NSError errorWithDomain:chatLocalizable(@"no_permission_tip") code:noPermissionOperationCode userInfo:nil]);
            return;
        }
        NSMutableDictionary *serverExtension = [NSMutableDictionary dictionary];
        if (team.serverExtension) {
            NSDictionary *ext = [NECommonUtil getDictionaryFromJSONString:team.serverExtension];
            if (ext) [serverExtension addEntriesFromDictionary:ext];
        }
        serverExtension[keyTopMessage] = topMessageDic;
        serverExtension[@"lastOpt"] = keyTopMessage;
        NSString *extension = [NECommonUtil getJSONStringFromDictionary:serverExtension];
        [[TeamRepo shared] updateTeamExtension:tid teamType:V2NIM_TEAM_TYPE_NORMAL ext:extension mode:nil completion:^(NSError *error) {
            if (!error) {
                // 双屏/分栏下群信息更新回调不一定作用在当前聊天页，先同步本地缓存并
                [weakSelf loadTopMessageWithExtension:extension];
            }
            completion(error);
        }];
    }];
}

- (void)untopMessage:(void (^)(NSError *_Nullable))completion {
    [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    if (!self.topMessage.messageClientId) {
        completion([NSError errorWithDomain:commonLocalizable(@"failed_operation") code:failedOperation userInfo:nil]);
        return;
    }
    NSDictionary *topMessageDic = @{
        @"idClient": self.topMessage.messageClientId ?: [NSNull null],
        @"operator": [[IMKitClient instance] account],
        @"operation": @(1),
    };
    __weak typeof(self) weakSelf = self;
    [[TeamRepo shared] getTeamInfo:[ChatRepo sessionId] teamType:V2NIM_TEAM_TYPE_NORMAL completion:^(V2NIMTeam *team, NSError *error) {
        if (error) { completion(error); return; }
        NSString *tid = [ChatRepo sessionId];
        if (![weakSelf hasTopMessagePremission]) {
            completion([NSError errorWithDomain:chatLocalizable(@"no_permission_tip") code:noPermissionOperationCode userInfo:nil]);
            return;
        }
        if (team.serverExtension) {
            NSMutableDictionary *serverExtension = [NSMutableDictionary dictionaryWithDictionary:[NECommonUtil getDictionaryFromJSONString:team.serverExtension] ?: @{}];
            if (serverExtension[keyTopMessage]) {
                serverExtension[keyTopMessage] = topMessageDic;
                serverExtension[@"lastOpt"] = keyTopMessage;
                weakSelf.topMessage = nil;
                NSString *extension = [NECommonUtil getJSONStringFromDictionary:serverExtension];
                [[TeamRepo shared] updateTeamExtension:tid teamType:V2NIM_TEAM_TYPE_NORMAL ext:extension mode:nil completion:^(NSError *error) {
                    if (!error) {
                        // 同 topMessage：当前页立即收起置顶横幅，不等切页重载。
                        [weakSelf loadTopMessageWithExtension:extension];
                    }
                    completion(error);
                }];
            }
        }
    }];
}

- (void)getTeamInfoWithTeamId:(NSString *)teamId completion:(void (^)(NSError *_Nullable, V2NIMTeam *_Nullable))completion {
    [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s, teamId: %@", __FUNCTION__, teamId]];
    V2NIMTeam *cachedTeam = [[NETeamUserManager shared] getTeamInfo];
    if (cachedTeam) {
        self.team = cachedTeam;
        self.teamMember = [[NETeamUserManager shared] getTeamMemberInfo:[[IMKitClient instance] account]];
        completion(nil, cachedTeam);
    } else {
        __weak typeof(self) weakSelf = self;
        [[TeamRepo shared] getTeamInfo:teamId teamType:V2NIM_TEAM_TYPE_NORMAL completion:^(V2NIMTeam *team, NSError *error) {
            if (!error) weakSelf.team = team;
            completion(error, team);
        }];
    }
}

- (void)topMessageAction:(void (^)(NSError *_Nullable))completion {
    [self topMessage:completion];
}

- (void)untopMessageAction:(void (^)(NSError *_Nullable))completion {
    [self untopMessage:completion];
}

- (void)getTeamMember:(void (^)(void))completion {
    V2NIMTeamMember *member = [[NETeamUserManager shared] getTeamMemberInfo:[[IMKitClient instance] account]];
    if (member) {
        self.teamMember = member;
        completion();
    } else {
        __weak typeof(self) weakSelf = self;
        [[TeamRepo shared] getTeamMember:[ChatRepo sessionId] teamType:V2NIM_TEAM_TYPE_NORMAL accId:[[IMKitClient instance] account] completion:^(V2NIMTeamMember *member, NSError *error) {
            weakSelf.teamMember = member;
            completion();
        }];
    }
}

- (void)markRead:(NSArray<V2NIMMessage *> *)messages completion:(void (^)(NSError *_Nullable))completion {
    [self markReadInTeam:messages completion:completion];
}

- (void)markReadInTeam:(NSArray<V2NIMMessage *> *)messages completion:(void (^)(NSError *_Nullable))completion {
    if (![ChatUIConfig shared].messageProperties.showTeamMessageStatus) { completion(nil); return; }
    NSMutableArray *markMessages = [NSMutableArray array];
    for (V2NIMMessage *message in messages) {
        if (message.messageServerId && !message.isSelf && message.messageConfig.readReceiptEnabled && !message.messageStatus.readReceiptSent) {
            [markMessages addObject:message];
        }
    }
    if (markMessages.count > 0) {
        [[ChatRepo shared] markTeamMessagesRead:markMessages completion:completion];
    } else {
        completion(nil);
    }
}

- (void)getMessageReceipts:(NSArray<V2NIMMessage *> *)messages completion:(void (^)(NSArray<NSIndexPath *> *, NSError *_Nullable))completion {
    [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    if ([ChatUIConfig shared].messageProperties.showTeamMessageStatus) {
        [self getTeamMessageReceipts:messages completion:completion];
    } else {
        completion(@[], nil);
    }
}

- (void)getTeamMessageReceipts:(NSArray<V2NIMMessage *> *)messages completion:(void (^)(NSArray<NSIndexPath *> *, NSError *_Nullable))completion {
    [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s", __FUNCTION__]];
    NSMutableArray *sendMessages = [NSMutableArray array];
    for (V2NIMMessage *msg in messages) {
        if (msg.messageServerId && msg.isSelf && msg.messageType != V2NIM_MESSAGE_TYPE_NOTIFICATION && msg.messageType != V2NIM_MESSAGE_TYPE_TIP) {
            [sendMessages addObject:msg];
        }
    }
    if (sendMessages.count == 0) { completion(@[], nil); return; }

    dispatch_group_t group = dispatch_group_create();
    NSMutableArray *readReceiptList = [NSMutableArray array];
    __block NSError *err = nil;
    NSInteger chunkSize = 50;
    for (NSInteger i = 0; i < sendMessages.count; i += chunkSize) {
        NSRange range = NSMakeRange(i, MIN(chunkSize, sendMessages.count - i));
        NSArray *chunk = [sendMessages subarrayWithRange:range];
        dispatch_group_enter(group);
        [[ChatRepo shared] getTeamMessageReceipts:chunk completion:^(NSArray<V2NIMTeamMessageReadReceipt *> *readReceipts, NSError *error) {
            if (error) err = error;
            if (readReceipts) [readReceiptList addObjectsFromArray:readReceipts];
            dispatch_group_leave(group);
        }];
    }
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        NSMutableArray<NSIndexPath *> *reloadIndexs = [NSMutableArray array];
        NSArray<V2NIMTeamMessageReadReceipt *> *readReceiptSnapshot = [readReceiptList copy];
        for (V2NIMTeamMessageReadReceipt *readReceipt in readReceiptSnapshot) {
            NSArray<id<MessageModel> > *messageSnapshot = [self.messages copy];
            for (NSInteger i = 0; i < messageSnapshot.count; i++) {
                id<MessageModel> model = messageSnapshot[i];
                if (![ChatMessageHelper isSelf:model.message]) continue;
                if (model.message.messageConfig.readReceiptEnabled == NO) continue;
                if ([model.message.messageClientId isEqualToString:readReceipt.messageClientId]) {
                    if (model.readCount == readReceipt.readCount && model.unreadCount == readReceipt.unreadCount) continue;
                    model.readCount = readReceipt.readCount;
                    model.unreadCount = readReceipt.unreadCount;
                    [reloadIndexs addObject:[NSIndexPath indexPathForRow:i inSection:0]];
                }
            }
        }
        completion(reloadIndexs, err);
    });
}

#pragma mark - NETeamListener

- (void)onTeamDismissed:(V2NIMTeam *)team {
    [NEALog infoLog:TAG desc:[NSString stringWithFormat:@"%s, teamId: %@", __FUNCTION__, team.teamId]];
    if ([[ChatRepo sessionId] isEqualToString:team.teamId]) {
        if ([self.delegate conformsToProtocol:@protocol(TeamChatViewModelDelegate)]) {
            id<TeamChatViewModelDelegate> teamDelegate = (id<TeamChatViewModelDelegate>)self.delegate;
            if ([teamDelegate respondsToSelector:@selector(onTeamRemoved:)]) {
                [teamDelegate onTeamRemoved:team];
            }
        }
    }
}

#pragma mark - NETeamChatUserCacheListener

- (void)onTeamInfoUpdate:(NSString *)teamId {
    V2NIMTeam *team = [[NETeamUserManager shared] getTeamInfo];
    if (![teamId isEqualToString:self.chatTeamId] || !team || ![team.teamId isEqualToString:self.chatTeamId]) return;
    self.team = team;
    [self loadTopMessage];
    if ([self.delegate conformsToProtocol:@protocol(TeamChatViewModelDelegate)]) {
        id<TeamChatViewModelDelegate> teamDelegate = (id<TeamChatViewModelDelegate>)self.delegate;
        if ([teamDelegate respondsToSelector:@selector(onTeamUpdate:)]) [teamDelegate onTeamUpdate:team];
    }
}

- (void)onTeamMemberUpdate:(NSString *)accountId {
    V2NIMTeamMember *teamMember = [[NETeamUserManager shared] getTeamMemberInfo:accountId];
    if (!teamMember || ![teamMember.teamId isEqualToString:self.chatTeamId]) return;
    if ([accountId isEqualToString:[[IMKitClient instance] account]]) {
        self.teamMember = teamMember;
        [self loadTopMessage];
    }
    [self updateMessageInfo:accountId];
    if ([self.delegate conformsToProtocol:@protocol(TeamChatViewModelDelegate)]) {
        id<TeamChatViewModelDelegate> teamDelegate = (id<TeamChatViewModelDelegate>)self.delegate;
        if ([teamDelegate respondsToSelector:@selector(onTeamMemberUpdate:)]) [teamDelegate onTeamMemberUpdate:@[teamMember]];
    }
}

#pragma mark - NEIMKitClientListener

- (void)onConnectStatus:(V2NIMConnectStatus)status {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{ [self onConnectStatus:status]; });
        return;
    }
    if (status == V2NIM_CONNECT_STATUS_WAITING || status == V2NIM_CONNECT_STATUS_DISCONNECTED) {
        self.teamNetworkBroken = YES;
        self.teamRefreshGeneration += 1;
        self.teamRefreshInFlight = NO;
        self.teamRefreshPending = NO;
        self.topMessageLoadGeneration += 1;
        [[NETeamUserManager shared] invalidateTeamInfoRefresh:self.chatTeamId];
    } else if (status == V2NIM_CONNECT_STATUS_CONNECTED && self.teamNetworkBroken) {
        self.teamNetworkBroken = NO;
        [self refreshTeamState];
    }
}

- (void)refreshTeamState {
    if (self.teamNetworkBroken || self.chatTeamId.length == 0) return;
    if (self.teamRefreshInFlight) {
        // Sync completion may contain newer state than the reconnect request.
        self.teamRefreshPending = YES;
        return;
    }
    self.teamRefreshInFlight = YES;
    NSUInteger generation = ++self.teamRefreshGeneration;
    __weak typeof(self) weakSelf = self;
    [self refreshTeamInfoAndSelfMember:self.chatTeamId completion:^{
        if (!weakSelf || weakSelf.teamRefreshGeneration != generation) return;
        weakSelf.teamRefreshInFlight = NO;
        if (weakSelf.teamRefreshPending) {
            weakSelf.teamRefreshPending = NO;
            [weakSelf refreshTeamState];
        }
    }];
}

- (void)refreshTeamInfoAndSelfMember:(NSString *)teamId completion:(void (^)(void))completion {
    [[NETeamUserManager shared] refreshTeamInfoAndSelfMember:teamId completion:completion];
}

- (void)onDataSync:(V2NIMDataSyncType)type state:(V2NIMDataSyncState)state error:(V2NIMError *)error {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{ [self onDataSync:type state:state error:error]; });
        return;
    }
    if (!error && state == V2NIM_DATA_SYNC_STATE_COMPLETED &&
        (type == V2NIM_DATA_SYNC_TYPE_MAIN || type == V2NIM_DATA_SYNC_TYPE_TEAM_MEMBER)) {
        [self refreshTeamState];
    }
}

@end
