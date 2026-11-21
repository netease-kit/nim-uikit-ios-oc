// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "AIChatDataLoader.h"
#import "AppKey.h"
#import "ServerAddresses.h"
#import <NEChatKit/ChatRepo.h>
#import <NEChatUIKitOC/AIChatCellModel.h>

static UIColor *AIChatColorFromHex(NSUInteger hex) {
  return [UIColor colorWithRed:((hex >> 16) & 0xFF) / 255.0
                         green:((hex >> 8) & 0xFF) / 255.0
                          blue:(hex & 0xFF) / 255.0
                         alpha:1.0];
}

@implementation NECommonResult

- (instancetype)init {
  self = [super init];
  if (self) {
    _code = -1;
  }
  return self;
}

@end

@implementation AIChatDataLoader

+ (void)loadData:(nullable NSArray<V2NIMMessage *> *)messages
      completion:(void (^)(NSArray<AIChatCellModel *> *_Nullable models,
                           NSError *_Nullable error))completion {
  V2NIMMessage *lastMessage = [self getLastTextMessage:messages];
  [self requestAIChatData:messages
              lastMessage:lastMessage
               completion:^(NSError *error, NECommonResult *result) {
                 NSMutableArray<AIChatCellModel *> *models = [NSMutableArray array];
                 NSDictionary *data = [result.originData[@"data"] isKindOfClass:NSDictionary.class]
                                          ? result.originData[@"data"]
                                          : nil;
                 NSArray *items = [data[@"items"] isKindOfClass:NSArray.class] ? data[@"items"] : nil;
                 NSArray<UIColor *> *titleColors = @[
                   AIChatColorFromHex(0xF159A2),
                   AIChatColorFromHex(0xE75257),
                   AIChatColorFromHex(0x598CF1),
                 ];
                 NSArray<UIColor *> *backgroundColors = @[
                   AIChatColorFromHex(0xFFE8F3),
                   AIChatColorFromHex(0xFFE8E8),
                   AIChatColorFromHex(0xE8F4FF),
                 ];
                 for (NSUInteger index = 0; index < items.count; index++) {
                   NSDictionary *item = [items[index] isKindOfClass:NSDictionary.class]
                                            ? items[index]
                                            : nil;
                   if (!item) {
                     continue;
                   }
                   NSUInteger colorIndex = index % titleColors.count;
                   AIChatCellModel *model =
                       [[AIChatCellModel alloc] initWithTagTitle:[item[@"style_name"] isKindOfClass:NSString.class]
                                                                 ? item[@"style_name"]
                                                                 : nil
                                                   tagTitleColor:titleColors[colorIndex]
                                         tagTitleBackgroundColor:backgroundColors[colorIndex]
                                                    contentTitle:[item[@"answer"] isKindOfClass:NSString.class]
                                                                 ? item[@"answer"]
                                                                 : nil];
                   [models addObject:model];
                 }
                 if (completion) {
                   completion(models, error);
                 }
               }];
}

+ (nullable V2NIMMessage *)getLastTextMessage:(nullable NSArray<V2NIMMessage *> *)messages {
  for (NSInteger index = (NSInteger)messages.count - 1; index >= 0; index--) {
    V2NIMMessage *message = messages[index];
    if (message.messageType == V2NIM_MESSAGE_TYPE_TEXT &&
        message.sendingState == V2NIM_MESSAGE_SENDING_STATE_SUCCEEDED &&
        !message.isSelf) {
      return message;
    }
  }
  return nil;
}

+ (void)requestAIChatData:(nullable NSArray<V2NIMMessage *> *)messages
              lastMessage:(nullable V2NIMMessage *)lastMessage
               completion:(void (^)(NSError *_Nullable error, NECommonResult *_Nullable result))completion {
  NSMutableURLRequest *request = [self requestWithMessages:messages lastMessage:lastMessage];
  if (!request) {
    if (completion) {
      completion([self errorWithMessage:nil code:nil], nil);
    }
    return;
  }

  NSURLSessionDataTask *task =
      [NSURLSession.sharedSession dataTaskWithRequest:request
                                    completionHandler:^(NSData *data,
                                                        NSURLResponse *response,
                                                        NSError *error) {
                                      (void)response;
                                      dispatch_async(dispatch_get_main_queue(), ^{
                                        if (error) {
                                          if (completion) {
                                            completion(error, nil);
                                          }
                                          return;
                                        }

                                        if (!data) {
                                          if (completion) {
                                            completion([self errorWithMessage:nil code:nil], nil);
                                          }
                                          return;
                                        }

                                        NECommonResult *result = [self parseResult:data];
                                        if (completion) {
                                          completion(result ? nil : [self errorWithMessage:nil code:nil],
                                                     result);
                                        }
                                      });
                                    }];
  [task resume];
}

+ (nullable NSMutableURLRequest *)requestWithMessages:(nullable NSArray<V2NIMMessage *> *)messages
                                         lastMessage:(nullable V2NIMMessage *)lastMessage {
  NSString *host = @"https://yiyong.netease.im/";
  NSURL *url =
      [NSURL URLWithString:[host stringByAppendingString:@"im/ai/chat_assistant/v1/chat_assist"]];
  if (!url) {
    return nil;
  }

  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
  request.HTTPMethod = @"POST";
  [request setValue:NEAppKey ?: @"" forHTTPHeaderField:@"appkey"];
  [request setValue:@"application/json;charset=utf-8" forHTTPHeaderField:@"Content-Type"];

  [request setValue:NEAppAccount forHTTPHeaderField:@"accountId"];
  [request setValue:NEAppToken forHTTPHeaderField:@"accessToken"];

  NSMutableDictionary<NSString *, id> *body = [NSMutableDictionary dictionary];
  body[@"style_list"] = @[ @"warm", @"hot", @"smart" ];
  body[@"sender_id"] = NEAppAccount;
  body[@"receiver_id"] = ChatRepo.sessionId ?: @"";
  if (lastMessage.text.length > 0) {
    body[@"receiver_last_message"] = lastMessage.text;
  }

  NSMutableArray<NSDictionary<NSString *, NSString *> *> *history = [NSMutableArray array];
  for (V2NIMMessage *message in messages ?: @[]) {
    if (message.senderId.length > 0 && message.text.length > 0) {
      [history addObject:@{@"sender_id" : message.senderId, @"text" : message.text}];
    }
  }
  body[@"history"] = history;

  request.HTTPBody = [NSJSONSerialization dataWithJSONObject:body options:0 error:nil];
  return request;
}

+ (NSError *)errorWithMessage:(nullable NSString *)message code:(nullable NSNumber *)code {
  return [NSError errorWithDomain:@"com.netease.im"
                             code:code.integerValue ?: -1
                         userInfo:@{NSLocalizedDescriptionKey : message ?: @"operation failed"}];
}

+ (nullable NECommonResult *)parseResult:(NSData *)data {
  id json =
      [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
  if (![json isKindOfClass:NSDictionary.class]) {
    return nil;
  }
  NECommonResult *result = [[NECommonResult alloc] init];
  NSNumber *code = [json[@"code"] isKindOfClass:NSNumber.class] ? json[@"code"] : nil;
  result.code = code.integerValue;
  result.originData = json;
  return result;
}

@end
