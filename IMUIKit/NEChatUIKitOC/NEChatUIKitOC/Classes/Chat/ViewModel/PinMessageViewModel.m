// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "PinMessageViewModel.h"
#import "NEChatUIConstant.h"
#import <NEChatKitOC/NEChatKitOC.h>
#import <NEChatKitOC/NEALog.h>
#import <NEChatKitOC/NECustomUtils.h>
#import <NEChatKitOC/NECoreIM2Constant.h>
#import "NETeamUserManager.h"
#import "ChatMessageHelper.h"
#import "MessageUtils.h"

@interface PinMessageViewModel ()
@property (nonatomic, strong) ChatRepo *chatRepo;
@end

@implementation PinMessageViewModel

- (instancetype)init {
  self = [super init];
  if (self) {
    _items = [NSMutableArray array];
    _chatRepo = [ChatRepo shared];
    [_chatRepo addChatListener:self];
  }
  return self;
}

- (void)dealloc {
  [_chatRepo removeChatListener:self];
}

- (void)getPinitems:(NSString *)conversationId completion:(void (^)(NSError *_Nullable error))completion {
  self.conversationId = conversationId;
  __weak typeof(self) weakSelf = self;
  dispatch_group_t group = dispatch_group_create();

  [self.chatRepo getPinnedMessageList:conversationId
                          completion:^(NSArray<V2NIMMessagePin *> *_Nullable pinItems, NSError *_Nullable error) {
    if (pinItems) {
      NSMutableArray<V2NIMMessageRefer *> *messageRefers = [NSMutableArray array];
      for (V2NIMMessagePin *pin in pinItems) {
        if (pin.messageRefer) {
          [messageRefers addObject:pin.messageRefer];
        }
      }

      if (messageRefers.count == 0) {
        [weakSelf.items removeAllObjects];
        if (completion) completion(nil);
        return;
      }

      dispatch_group_enter(group);
      [weakSelf.chatRepo getMessageListByRefers:messageRefers
                                    completion:^(NSArray<V2NIMMessage *> *_Nullable messages, NSError *_Nullable error) {
        if (messages) {
          [weakSelf.items removeAllObjects];
          for (V2NIMMessage *message in messages) {
            for (V2NIMMessagePin *item in pinItems) {
              if ([message.messageClientId isEqualToString:item.messageRefer.messageClientId]) {
                NEPinMessageModel *pinModel = [[NEPinMessageModel alloc] initWithMessage:message item:item];
                [weakSelf.items addObject:pinModel];
              }
            }
          }
        } else {
          if (completion) completion(error);
        }
        dispatch_group_leave(group);
      }];

      dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        // 按时间降序排列
        [weakSelf.items sortUsingComparator:^NSComparisonResult(NEPinMessageModel *model1, NEPinMessageModel *model2) {
          if (model1.message.createTime > model2.message.createTime) return NSOrderedAscending;
          if (model1.message.createTime < model2.message.createTime) return NSOrderedDescending;
          return NSOrderedSame;
        }];
        if (completion) completion(error);
        [weakSelf loadMoreWithModel:weakSelf.items completion:^{
          if ([weakSelf.delegate respondsToSelector:@selector(tableViewReload:)]) {
            [weakSelf.delegate tableViewReload:NO];
          }
        }];
      });
    } else {
      if (completion) completion(error);
    }
  }];
}

- (void)loadMoreWithModel:(nullable NSArray<NEPinMessageModel *> *)items completion:(void (^)(void))completion {
  if (!items) {
    if (completion) completion();
    return;
  }

  NSArray<NEPinMessageModel *> *itemSnapshot = [items copy];
  NSMutableArray<NSString *> *userIds = [NSMutableArray array];
  for (NEPinMessageModel *item in itemSnapshot) {
    if (item.message.senderId) {
      [userIds addObject:item.message.senderId];
    }
  }

  [[NETeamUserManager shared] getTeamMembers:userIds notify:NO completion:^{
    for (NEPinMessageModel *item in itemSnapshot) {
      NSString *senderId = [ChatMessageHelper getSenderId:item.chatmodel.message];
      if (senderId) {
        NSString *name = [[NETeamUserManager shared] getShowName:senderId showAlias:YES];
        NEUserWithFriend *user = [ChatMessageHelper getUserFromCache:senderId];
        item.chatmodel.avatar = user.user.avatar;
        item.chatmodel.fullName = name;
        item.chatmodel.shortName = [NEFriendUserCache getShortName:[user showName:NO] ?: @""];
      }
    }
    if (completion) completion();
  }];
}

- (void)removePinMessage:(V2NIMMessage *)message completion:(void (^)(NSError *_Nullable error))completion {
  [NEALog infoLog:@"PinMessageViewModel" desc:[NSString stringWithFormat:@"%s, messageId: %@", __FUNCTION__, message.messageClientId]];
  [self.chatRepo unpinMessage:message serverExt:@"" completion:^(NSError *_Nullable error) {
    if (completion) completion(error);
  }];
}

- (V2NIMAIModelCallContent *)getAIModelCallContent:(nullable NSString *)text type:(V2NIMAIModelCallContentType)type {
  V2NIMAIModelCallContent *content = [[V2NIMAIModelCallContent alloc] init];
  content.msg = text ?: @"";
  content.type = type;
  return content;
}

- (V2NIMSendMessageParams *)getSendMessageParams:(nullable NSString *)aiUserAccid message:(V2NIMMessage *)message {
  V2NIMSendMessageParams *params = [self.chatRepo getSendMessageParams];

  NSString *cid = aiUserAccid;
  NSString *aiAccid = [V2NIMConversationIdUtil conversationTargetId:cid ?: @""];
  if (!aiAccid || ![[NEAIUserManager shared] isAIUser:aiAccid]) {
    return params;
  }

  V2NIMMessageAIConfigParams *aiConfig = [[V2NIMMessageAIConfigParams alloc] init];
  aiConfig.accountId = aiAccid;
  aiConfig.aiStream = [IMKitConfigCenter shared].enableAIStream;

  if (message.messageType == V2NIM_MESSAGE_TYPE_TEXT && message.text) {
    aiConfig.content = [self getAIModelCallContent:message.text type:V2NIM_AI_MODEL_CONTENT_TYPE_TEXT];
  }

  if (message.messageType == V2NIM_MESSAGE_TYPE_CUSTOM) {
    NSInteger type = [[NECustomUtils typeOfCustomMessage:message.attachment] integerValue];
    if (type == customRichTextType) {
      NSString *title = [NECustomUtils titleOfRichText:message.attachment];
      NSString *body = [NECustomUtils bodyOfRichText:message.attachment];
      NSString *text = [NSString stringWithFormat:@"%@%@", title ?: @"", body ?: @""];
      aiConfig.content = [self getAIModelCallContent:text type:V2NIM_AI_MODEL_CONTENT_TYPE_TEXT];
    }
  }

  params.aiConfig = aiConfig;
  return params;
}

- (void)sendTextMessage:(NSString *)text
         conversationId:(NSString *)conversationId
             completion:(void (^)(V2NIMSendMessageResult *_Nullable result, NSError *_Nullable error, NSUInteger progress))completion {
  [NEALog infoLog:[NSString stringWithFormat:@"%@ PinMessageViewModel", ChatUIKitModuleName] desc:[NSString stringWithFormat:@"%s, text.count: %lu", __FUNCTION__, (unsigned long)text.length]];
  if (text.length <= 0) return;

  V2NIMMessage *message = [MessageUtils textMessageWithText:text];
  V2NIMSendMessageParams *params = [self getSendMessageParams:conversationId message:message];
  [self.chatRepo sendMessage:message conversationId:conversationId params:params completion:completion];
}

- (void)forwardMessages:(V2NIMMessage *)message
        conversationIds:(NSArray<NSString *> *)conversationIds
                comment:(nullable NSString *)comment
             completion:(void (^)(V2NIMSendMessageResult *_Nullable result, NSError *_Nullable error, NSUInteger progress))completion {
  [NEALog infoLog:[NSString stringWithFormat:@"%@ PinMessageViewModel", ChatUIKitModuleName] desc:[NSString stringWithFormat:@"%s, messageId: %@", __FUNCTION__, message.messageClientId]];
  for (NSString *conversationId in conversationIds) {
    V2NIMMessage *forwardMessage = [MessageUtils forwardMessageWithMessage:message];
    [ChatMessageHelper clearForwardReplyMark:forwardMessage];
    V2NIMSendMessageParams *params = [self getSendMessageParams:conversationId message:message];
    [self.chatRepo sendMessage:forwardMessage conversationId:conversationId params:params completion:completion];

    if (comment && comment.length > 0) {
      [self sendTextMessage:comment conversationId:conversationId completion:completion];
    }
  }
}

- (void)downLoad:(NSString *)urlString
        filePath:(NSString *)filePath
        progress:(nullable void (^)(NSUInteger progress))progress
      completion:(nullable void (^)(NSString *_Nullable path, NSError *_Nullable error))completion {
  [NEALog infoLog:[NSString stringWithFormat:@"%@ PinMessageViewModel", ChatUIKitModuleName] desc:[NSString stringWithFormat:@"%s, messageId: %@", __FUNCTION__, urlString]];
  [[ResourceRepo shared] downLoadFile:urlString filePath:filePath progress:progress completion:completion];
}

- (BOOL)getHandSetEnable {
  [NEALog infoLog:[NSString stringWithFormat:@"%@ PinMessageViewModel", ChatUIKitModuleName] desc:[NSString stringWithFormat:@"%s", __FUNCTION__]];
  return [[SettingRepo shared] getHandsetMode];
}

- (void)onDeleteIndexPath:(NSArray<V2NIMMessageRefer *> *)messageRefers {
  NSArray<V2NIMMessageRefer *> *referSnapshot = [messageRefers copy];
  for (V2NIMMessageRefer *messageRefer in referSnapshot) {
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(NEPinMessageModel *item, NSDictionary *bindings) {
      return [item.message.messageClientId isEqualToString:messageRefer.messageClientId];
    }];
    NSArray *toRemove = [self.items filteredArrayUsingPredicate:predicate];
    [self.items removeObjectsInArray:toRemove];
  }
  if ([self.delegate respondsToSelector:@selector(tableViewReload:)]) {
    [self.delegate tableViewReload:NO];
  }
}

#pragma mark - NEChatListener

- (void)onMessageRevokeNotifications:(NSArray<V2NIMMessageRevokeNotification *> *)revokeNotifications {
  if ([self.delegate respondsToSelector:@selector(tableViewReload:)]) {
    [self.delegate tableViewReload:YES];
  }
}

- (void)onMessagePinNotification:(V2NIMMessagePinNotification *)pinNotification {
  switch (pinNotification.pinState) {
    case V2NIM_MESSAGE_PIN_STEATE_NOT_PINNED: {
      V2NIMMessageRefer *messageRefer = pinNotification.pin.messageRefer;
      if (messageRefer) {
        [self onDeleteIndexPath:@[messageRefer]];
      }
      break;
    }
    case V2NIM_MESSAGE_PIN_STEATE_PINNED:
      if ([self.delegate respondsToSelector:@selector(tableViewReload:)]) {
        [self.delegate tableViewReload:YES];
      }
      break;
    case V2NIM_MESSAGE_PIN_STEATE_UPDATED:
      if ([self.delegate respondsToSelector:@selector(tableViewReload:)]) {
        [self.delegate tableViewReload:YES];
      }
      break;
    default:
      break;
  }
}

- (void)onMessageDeletedNotifications:(NSArray<V2NIMMessageDeletedNotification *> *)messageDeletedNotification {
  NSMutableArray<V2NIMMessageRefer *> *messageRefers = [NSMutableArray array];
  for (V2NIMMessageDeletedNotification *notification in messageDeletedNotification) {
    [messageRefers addObject:notification.messageRefer];
  }
  [self onDeleteIndexPath:messageRefers];
}

@end
