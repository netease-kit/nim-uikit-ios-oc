// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEAIWordSearchViewModel.h"
#import "NEAISearchConstant.h"
#import "NEAIWordSearchModel.h"
#import <NEChatKit/AIRepo.h>
#import <NEChatKit/NEAIUserManager.h>
#import <NEChatKit/NSObject+NECommon.h>
#import <NEBaseUIKitOC/NECommonUIConstant.h>
#import <NEChatKit/NEALog.h>
#import <NEChatKit/NECoreIM2Constant.h>

@interface NEAIWordSearchViewModel ()

@property (nonatomic, strong) AIRepo *repo;
@property (nonatomic, strong) NSMutableArray<NSString *> *searchTexts;
@property (nonatomic, assign) CGFloat aiModelTemperature;
@property (nonatomic, strong) NSMutableArray<NSString *> *requestIds;

@end

@implementation NEAIWordSearchViewModel

- (instancetype)init {
  self = [super init];
  if (self) {
    _repo = [AIRepo shared];
    _data = [NSMutableArray array];
    _searchTexts = [NSMutableArray array];
    _requestIds = [NSMutableArray array];
    _aiModelTemperature = 0.8;
    [self.repo addAIListener:self];
  }
  return self;
}

- (void)dealloc {
  [self.repo removeAIListener:self];
}

- (V2NIMAIModelCallContent *)getAIModelCallContent:(NSString *)msg
                                              type:(V2NIMAIModelCallContentType)type {
  (void)type;
  V2NIMAIModelCallContent *content = [[V2NIMAIModelCallContent alloc] init];
  content.msg = msg ?: @"";
  content.type = V2NIM_AI_MODEL_CONTENT_TYPE_TEXT;
  return content;
}

- (V2NIMAIModelConfigParams *)getAIModelConfigParams:(CGFloat)temperature {
  V2NIMAIModelConfigParams *config = [[V2NIMAIModelConfigParams alloc] init];
  config.temperature = temperature;
  return config;
}

- (nullable NSArray<V2NIMAIModelCallMessage *> *)getAIMessages {
  NSMutableArray<V2NIMAIModelCallMessage *> *messages = [NSMutableArray array];
  [self.searchTexts enumerateObjectsUsingBlock:^(NSString * _Nonnull text, NSUInteger idx, BOOL * _Nonnull stop) {
    (void)stop;
    [NEALog infoLog:[NSString stringWithFormat:@"%@ %@", NEAISearchModuleName, [[self class] className]]
               desc:[NSString stringWithFormat:@"%@[AISearch], message text%lu: %@",
                                               NSStringFromSelector(_cmd),
                                               (unsigned long)(idx + 1),
                                               text ?: @""]];
    V2NIMAIModelCallMessage *message = [[V2NIMAIModelCallMessage alloc] init];
    message.msg = text ?: @"";
    message.role = V2NIM_AI_MODEL_ROLE_TYPE_USER;
    message.type = V2NIM_AI_MODEL_CONTENT_TYPE_TEXT;
    [messages addObject:message];
  }];
  return messages.count > 0 ? messages : nil;
}

- (V2NIMProxyAIModelCallParams *)getProxyAIModelCallParams:(NSString *)accid
                                                 requestId:(NSString *)requestId
                                                   content:(V2NIMAIModelCallContent *)content
                                         modelConfigParams:(V2NIMAIModelConfigParams *)modelConfigParams {
  V2NIMProxyAIModelCallParams *params = [[V2NIMProxyAIModelCallParams alloc] init];
  params.accountId = accid ?: @"";
  params.requestId = requestId ?: @"";
  params.content = content;
  params.modelConfigParams = modelConfigParams;
  params.messages = [self getAIMessages];
  return params;
}

- (void)loadData:(NSString *)searchText
      completion:(void (^)(NSError * _Nullable))completion {
  [NEALog infoLog:[NSString stringWithFormat:@"%@ %@", NEAISearchModuleName, [[self class] className]]
             desc:[NSString stringWithFormat:@"%@[AISearch], searchText: %@",
                                             NSStringFromSelector(_cmd),
                                             searchText ?: @""]];

  if (!searchText) {
    if (completion) {
      completion(nil);
    }
    return;
  }

  V2NIMAIUser *aiUser = [[NEAIUserManager shared] getAISearchUser];
  if (!aiUser) {
    return;
  }

  NSString *accid = aiUser.accountId ?: @"";
  if (accid.length <= 0) {
    return;
  }

  NSString *requestId = [NSUUID UUID].UUIDString ?: @"";
  V2NIMAIModelCallContent *content =
      [self getAIModelCallContent:searchText type:V2NIM_AI_MODEL_CONTENT_TYPE_TEXT];
  V2NIMAIModelConfigParams *modelConfigParams =
      [self getAIModelConfigParams:self.aiModelTemperature];
  V2NIMProxyAIModelCallParams *params =
      [self getProxyAIModelCallParams:accid
                            requestId:requestId
                              content:content
                    modelConfigParams:modelConfigParams];

  __weak typeof(self) weakSelf = self;
  [self.repo proxyAIModelCall:params completion:^(NSError * _Nullable error) {
    if (error) {
      NSLog(@"proxyAIModelCall error: %@", error.localizedDescription ?: @"");
      if (completion) {
        completion(error);
      }
      return;
    }

    [weakSelf.searchTexts addObject:searchText];
    [weakSelf.requestIds addObject:requestId];
  }];
}

- (NSString *)getErrorText:(V2NIMAIModelCallResult *)data {
  NSInteger code = data.code;
  if (code == operationSuccess) {
    return data.content.msg ?: @"";
  }
  if (code == failedOperation) {
    return commonLocalizable(@"parameter_setting_error");
  }
  if (code == rateLimitExceeded) {
    return commonLocalizable(@"rate_limit_exceeded");
  }
  if (code == userNotExistCode) {
    return commonLocalizable(@"user_not_exist");
  }
  if (code == userBannedCode) {
    return commonLocalizable(@"user_banned");
  }
  if (code == userChatBannedCode) {
    return commonLocalizable(@"user_chat_banned");
  }
  if (code == noFriendCode) {
    return commonLocalizable(@"friend_not_exist");
  }
  if (code == messageHitAntispam1 || code == messageHitAntispam2) {
    return commonLocalizable(@"message_hit_antispam");
  }
  if (code == teamMemberNotExist) {
    return commonLocalizable(@"team_member_not_exist");
  }
  if (code == teamNormalMemberChatBanned) {
    return commonLocalizable(@"team_normal_member_chat_banned");
  }
  if (code == teamMemberChatBanned) {
    return commonLocalizable(@"team_member_chat_banned");
  }
  if (code == notAIAccount) {
    return commonLocalizable(@"not_ai_account");
  }
  if (code == cannotBlockAIAccount) {
    return commonLocalizable(@"cannot_blocklist_ai_account");
  }
  if (code == aiMessagesDisabled) {
    return commonLocalizable(@"ai_messages_function_disabled");
  }
  if (code == aiMessageRequestFailed) {
    return commonLocalizable(@"failed_request_to_the_LLM");
  }
  return NEAISearchLocalizable(@"request_exception");
}

- (void)onProxyAIModelCall:(V2NIMAIModelCallResult *)data {
  [NEALog infoLog:[NSString stringWithFormat:@"%@ %@", NEAISearchModuleName, [[self class] className]]
             desc:[NSString stringWithFormat:@"%@[aiSearch], data: %@",
                                             NSStringFromSelector(_cmd),
                                             data.content.msg ?: @""]];

  if (data.requestId.length <= 0 || ![self.requestIds containsObject:data.requestId]) {
    return;
  }

  NSString *showText = [self getErrorText:data];
  NSAttributedString *content =
      [[NSAttributedString alloc] initWithString:showText ?: @""];
  NEAIWordSearchModel *model = [[NEAIWordSearchModel alloc] initWithContent:content];
  [self.data insertObject:model atIndex:0];
  [self.requestIds removeObject:data.requestId];

  BOOL isLoading = self.requestIds.count > 0;
  [self.delegate tableViewReload:isLoading];
}

@end
