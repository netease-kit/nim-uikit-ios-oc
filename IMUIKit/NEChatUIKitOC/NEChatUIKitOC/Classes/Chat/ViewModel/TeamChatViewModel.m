// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "TeamChatViewModel.h"
#import <NEChatKit/NEChatKitOC.h>
#import <NEChatKit/ChatConstant.h>
#import <NEChatKit/NECoreIM2Constant.h>
#import <NEChatKit/NEALog.h>
#import <NECommonUIKitOC/NECommonUIConstant.h>
#import "NEChatUIConstant.h"
#import "NETeamUserManager.h"
#import "ChatMessageHelper.h"
#import "ChatUIConfig.h"
#import <NEChatKit/NIMExtension.h>

static NSString *const TAG = @"TeamChatViewModel";

@implementation TeamChatViewModel

- (instancetype)initWithConversationId:(NSString *)conversationId {
    return [super initWithConversationId:conversationId];
}

- (instancetype)initWithConversationId:(NSString *)conversationId anchor:(nullable V2NIMMessage *)anchor {
    return [super initWithConversationId:conversationId anchor:anchor];
}

- (void)dealloc {
    [[TeamRepo shared] removeTeamListener:self];
    [[NETeamUserManager shared] removeListener:self];
}

- (void)addListener {
    [super addListener];
    [[TeamRepo shared] addTeamListener:self];
    [[NETeamUserManager shared] addListener:self];
    [[NETeamUserManager shared] loadData:[ChatRepo sessionId]];
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
    if (![IMKitConfigCenter shared].enableTopMessage) return;
    if (!self.team.serverExtension) return;
    NSDictionary *extDic = getDictionaryFromJSONString(self.team.serverExtension);
    if (!extDic) return;
    NSDictionary *topInfo = extDic[keyTopMessage];
    if (!topInfo) return;
    NSInteger operation = [topInfo[@"operation"] integerValue];
    if (operation == 0) {
        V2NIMMessageRefer *refer = [ChatMessageHelper createMessageRefer:topInfo];
        __weak typeof(self) weakSelf = self;
        [[ChatRepo shared] getMessageListByRefers:@[refer] completion:^(NSArray<V2NIMMessage *> *messages, NSError *error) {
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
        [[TeamRepo shared] updateTeamExtension:tid teamType:V2NIM_TEAM_TYPE_NORMAL ext:[NECommonUtil getJSONStringFromDictionary:serverExtension] mode:nil completion:^(NSError *error) {
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
                [[TeamRepo shared] updateTeamExtension:tid teamType:V2NIM_TEAM_TYPE_NORMAL ext:[NECommonUtil getJSONStringFromDictionary:serverExtension] mode:nil completion:^(NSError *error) {
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
    if (!team || ![team.teamId isEqualToString:[ChatRepo sessionId]]) return;
    self.team = team;
    [self loadTopMessage];
    if ([self.delegate conformsToProtocol:@protocol(TeamChatViewModelDelegate)]) {
        id<TeamChatViewModelDelegate> teamDelegate = (id<TeamChatViewModelDelegate>)self.delegate;
        if ([teamDelegate respondsToSelector:@selector(onTeamUpdate:)]) [teamDelegate onTeamUpdate:team];
    }
}

- (void)onTeamMemberUpdate:(NSString *)accountId {
    V2NIMTeamMember *teamMember = [[NETeamUserManager shared] getTeamMemberInfo:accountId];
    if (!teamMember) return;
    if (!self.teamMember || [accountId isEqualToString:self.teamMember.accountId]) {
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

- (void)onDataSync:(V2NIMDataSyncType)type state:(V2NIMDataSyncState)state error:(V2NIMError *)error {
    if (type == V2NIM_DATA_SYNC_TYPE_TEAM_MEMBER && state == V2NIM_DATA_SYNC_STATE_COMPLETED) {
        __weak typeof(self) weakSelf = self;
        [self getTeamInfoWithTeamId:[ChatRepo sessionId] completion:^(NSError *err, V2NIMTeam *team) {
            if (!err) weakSelf.team = team;
            [weakSelf getTeamMember:^{
                [weakSelf loadTopMessage];
            }];
        }];
    }
}

@end
