// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "CollectionMessageViewModel.h"
#import "NEChatUIConstant.h"
#import "ChatMessageHelper.h"
#import "MessageUtils.h"
#import <NEChatKit/NEChatKitOC.h>
#import <NEChatKit/NEALog.h>
#import <NEChatKit/NECustomUtils.h>
#import <NEChatKit/NECoreIM2Constant.h>

@interface CollectionMessageViewModel ()
@property (nonatomic, strong) ChatRepo *chatRepo;
@end

@implementation CollectionMessageViewModel

- (instancetype)init {
  self = [super init];
  if (self) {
    _collectionDatas = [NSMutableArray array];
    _audioDownloadSet = [NSMutableSet set];
    _pageSize = 100;
    _chatRepo = [ChatRepo shared];
  }
  return self;
}

- (void)loadData:(void (^)(NSError *_Nullable error, BOOL noMore))completion {
  V2NIMCollectionOption *option = [[V2NIMCollectionOption alloc] init];

  if (self.collectionDatas.lastObject) {
    CollectionMessageModel *lastModel = self.collectionDatas.lastObject;
    option.anchorCollection = lastModel.collection;
  } else {
    option.endTime = [[NSDate date] timeIntervalSince1970];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [[NSDateComponents alloc] init];
    components.year = -10;
    NSDate *tenYearsAgo = [calendar dateByAddingComponents:components toDate:[NSDate date] options:0];
    option.beginTime = [tenYearsAgo timeIntervalSince1970];
  }
  option.limit = self.pageSize;
  option.direction = V2NIM_QUERY_DIRECTION_DESC;

  __weak typeof(self) weakSelf = self;
  [self.chatRepo getCollections:option completion:^(NSArray<V2NIMCollection *> *_Nullable collections, NSError *_Nullable error) {
    if (error) {
      if (completion) completion(error, NO);
    } else {
      if (collections) {
        NSArray<CollectionMessageModel *> *models = [weakSelf parseMessage:collections];
        [weakSelf.collectionDatas addObjectsFromArray:models];
        if (completion) completion(nil, models.count == 0);
      } else {
        if (completion) completion(nil, YES);
      }
    }
  }];
}

- (NSArray<CollectionMessageModel *> *)parseMessage:(NSArray<V2NIMCollection *> *)collections {
  NSMutableArray<CollectionMessageModel *> *retArray = [NSMutableArray array];
  for (V2NIMCollection *collection in collections) {
    NSString *dataString = [collection.collectionData isKindOfClass:[NSString class]] ? collection.collectionData : nil;
    if (dataString.length <= 0) continue;

    NSDictionary *dataDic = getDictionaryFromJSONString(dataString);
    if (!dataDic) continue;
    NSString *messageString = [dataDic[@"message"] isKindOfClass:[NSString class]] ? dataDic[@"message"] : nil;
    NSString *conversationName = [dataDic[@"conversationName"] isKindOfClass:[NSString class]] ? dataDic[@"conversationName"] : nil;
    if (messageString.length <= 0 || conversationName.length <= 0) continue;

    CollectionMessageModel *model = [[CollectionMessageModel alloc] init];
    V2NIMMessage *message = [V2NIMMessageConverter messageDeserialization:messageString];
    if (message) {
      model.message = message;
    }

    model.conversationName = conversationName;

    NSString *avatar = [dataDic[@"avatar"] isKindOfClass:[NSString class]] ? dataDic[@"avatar"] : nil;
    if (avatar.length > 0) {
      model.avatar = avatar;
      model.chatmodel.avatar = avatar;
    }

    NSString *senderName = [dataDic[@"senderName"] isKindOfClass:[NSString class]] ? dataDic[@"senderName"] : nil;
    if (senderName.length > 0) {
      model.senderName = senderName;
      model.chatmodel.fullName = senderName;
      model.chatmodel.shortName = [NEFriendUserCache getShortName:senderName];
    } else {
      NSString *senderId = [ChatMessageHelper getSenderId:message];
      model.chatmodel.shortName = [NEFriendUserCache getShortName:senderId ?: @""];
    }

    model.collection = collection;
    [retArray addObject:model];
  }
  return retArray;
}

- (V2NIMAIModelCallContent *)getAIModelCallContent:(nullable NSString *)text type:(V2NIMAIModelCallContentType)type {
  V2NIMAIModelCallContent *content = [[V2NIMAIModelCallContent alloc] init];
  content.msg = text ?: @"";
  content.type = type;
  return content;
}

- (V2NIMSendMessageParams *)getSendMessageParams:(nullable NSString *)conversationId message:(V2NIMMessage *)message {
  V2NIMSendMessageParams *params = [self.chatRepo getSendMessageParams];

  NSString *cid = conversationId;
  if (!cid) return params;

  NSString *aiAccid = [V2NIMConversationIdUtil conversationTargetId:cid];
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
  [NEALog infoLog:[NSString stringWithFormat:@"%@ CollectionMessageViewModel", ModuleName] desc:[NSString stringWithFormat:@"%s, text.count: %lu", __FUNCTION__, (unsigned long)text.length]];
  if (text.length <= 0) return;

  V2NIMMessage *message = [MessageUtils textMessageWithText:text];
  V2NIMSendMessageParams *params = [self getSendMessageParams:conversationId message:message];
  [self.chatRepo sendMessage:message conversationId:conversationId params:params completion:completion];
}

- (void)forwardCollectionMessages:(V2NIMMessage *)message
                   conversationIds:(NSArray<NSString *> *)conversationIds
                           comment:(nullable NSString *)comment
                        completion:(void (^)(V2NIMSendMessageResult *_Nullable result, NSError *_Nullable error, NSUInteger progress))completion {
  [NEALog infoLog:[NSString stringWithFormat:@"%@ CollectionMessageViewModel", ModuleName] desc:[NSString stringWithFormat:@"%s, messageId: %@", __FUNCTION__, message.messageClientId]];
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

- (void)downloadFile:(NSString *)urlString
            filePath:(NSString *)filePath
            progress:(nullable void (^)(NSUInteger progress))progress
          completion:(nullable void (^)(NSString *_Nullable path, NSError *_Nullable error))completion {
  [NEALog infoLog:[NSString stringWithFormat:@"%@ CollectionMessageViewModel", ModuleName] desc:[NSString stringWithFormat:@"%s, messageId: %@", __FUNCTION__, urlString]];
  [[ResourceRepo shared] downLoadFile:urlString filePath:filePath progress:progress completion:completion];
}

- (void)removeCollection:(V2NIMCollection *)collection completion:(void (^)(NSError *_Nullable error))completion {
  [self.chatRepo removeCollections:@[collection] completion:^(NSInteger ret, NSError *_Nullable error) {
    if (completion) completion(error);
  }];
}

- (BOOL)getHandSetEnable {
  [NEALog infoLog:[NSString stringWithFormat:@"%@ CollectionMessageViewModel", ModuleName] desc:[NSString stringWithFormat:@"%s", __FUNCTION__]];
  return [[SettingRepo shared] getHandsetMode];
}

@end
