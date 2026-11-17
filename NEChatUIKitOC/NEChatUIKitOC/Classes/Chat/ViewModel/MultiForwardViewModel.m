// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "MultiForwardViewModel.h"
#import "NEChatUIConstant.h"
#import <NEChatKit/NEChatKit.h>
#import <NEChatKit/NEALog.h>
#import "ChatMessageHelper.h"
#import "MessageTextModel.h"

static inline NSString *NEStringValue(id value) {
  return [value isKindOfClass:[NSString class]] ? (NSString *)value : nil;
}

@implementation MultiForwardViewModel

- (instancetype)init {
  self = [super init];
  if (self) {
    _messages = [NSMutableArray array];
  }
  return self;
}

- (void)loadData:(nullable NSString *)messageAttachmentUrl
        filePath:(NSString *)filePath
             md5:(nullable NSString *)md5
      completion:(void (^)(NSError *_Nullable error))completion {
  if (filePath.length <= 0) {
    if (completion) {
      completion([NSError errorWithDomain:chatLocalizable(@"multiForward_open_failed") code:0 userInfo:nil]);
    }
    return;
  }

  if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
    [self decodeMessagesAtFilePath:filePath md5:md5 completion:completion];
  } else if (messageAttachmentUrl.length > 0) {
    __weak typeof(self) weakSelf = self;
    [self downLoad:messageAttachmentUrl
          filePath:filePath
          progress:nil
        completion:^(NSString *_Nullable path, NSError *_Nullable error) {
          if (error) {
            if (completion) completion(error);
            return;
          }
          [weakSelf decodeMessagesAtFilePath:filePath md5:md5 completion:completion];
        }];
  } else if (completion) {
    completion([NSError errorWithDomain:chatLocalizable(@"multiForward_open_failed") code:0 userInfo:nil]);
  }
}

- (void)decodeMessagesAtFilePath:(NSString *)filePath
                             md5:(nullable NSString *)md5
                      completion:(void (^)(NSError *_Nullable error))completion {
  // 校验文件 MD5
  NSURL *fileURL = [NSURL fileURLWithPath:filePath];
  NSString *fileMD5 = fileURL ? [ChatMessageHelper getFileChecksumWithFileURL:fileURL] : nil;
  if (fileMD5 && ![fileMD5 isEqualToString:md5]) {
    if (completion) {
      completion([NSError errorWithDomain:chatLocalizable(@"file_check_failed") code:0 userInfo:nil]);
    }
    return;
  }

  NSError *readError = nil;
  NSData *data = [NSData dataWithContentsOfFile:filePath options:0 error:&readError];
  if (readError) {
    if (completion) {
      completion(readError);
    }
    return;
  }

  NSString *strData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
  NSArray<NSString *> *subStringData = [strData componentsSeparatedByString:@"\n"];
  NSInteger msgCount = subStringData.count;
  if (msgCount > 1) {
    for (NSInteger i = 1; i < msgCount; i++) {
      NSString *msgString = subStringData[i];
      if (![msgString isKindOfClass:[NSString class]] || msgString.length <= 0) {
        continue;
      }
      V2NIMMessage *msg = [V2NIMMessageConverter messageDeserialization:msgString];
      if (msg) {
        id<MessageModel> model = [self modelFromMessage:msg];
        [ChatMessageHelper addTimeMessage:model lastModel:self.messages.lastObject];
        [self.messages addObject:model];
      }
    }
    if (completion) {
      completion(nil);
    }
  } else if (completion) {
    completion([NSError errorWithDomain:chatLocalizable(@"multiForward_open_failed") code:0 userInfo:nil]);
  }
}

- (id<MessageModel>)modelFromMessage:(V2NIMMessage *)message {
  id<MessageModel> model;
  switch (message.messageType) {
    case V2NIM_MESSAGE_TYPE_AUDIO:
      message.text = chatLocalizable(@"msg_audio");
      model = [[MessageTextModel alloc] initWithMessage:message];
      break;
    case V2NIM_MESSAGE_TYPE_CALL: {
      message.text = chatLocalizable(@"msg_rtc_call");
      V2NIMMessageCallAttachment *attachment = (V2NIMMessageCallAttachment *)message.attachment;
      if ([attachment isKindOfClass:[V2NIMMessageCallAttachment class]]) {
        message.text = attachment.type == 1 ? chatLocalizable(@"msg_rtc_audio") : chatLocalizable(@"msg_rtc_video");
      }
      model = [[MessageTextModel alloc] initWithMessage:message];
      break;
    }
    default:
      model = [ChatMessageHelper modelFromMessage:message];
      break;
  }

  NSDictionary *remoteExt = getDictionaryFromJSONString(message.serverExtension ?: @"");
  if (remoteExt) {
    model.fullName = NEStringValue(remoteExt[mergedMessageNickKey]);
    model.shortName = [NEFriendUserCache getShortName:model.fullName ?: @""];
    model.avatar = NEStringValue(remoteExt[mergedMessageAvatarKey]);
  } else {
    model.fullName = [ChatMessageHelper getSenderId:message];
    model.shortName = [NEFriendUserCache getShortName:model.fullName ?: @""];
  }

  if (self.delegate && [self.delegate respondsToSelector:@selector(getMessageModel:)]) {
    [self.delegate getMessageModel:model];
  }
  return model;
}

- (void)downLoad:(NSString *)urlString
        filePath:(NSString *)filePath
        progress:(nullable void (^)(NSUInteger progress))progress
      completion:(nullable void (^)(NSString *_Nullable path, NSError *_Nullable error))completion {
  [NEALog infoLog:[NSString stringWithFormat:@"%@ MultiForwardViewModel", ModuleName] desc:[NSString stringWithFormat:@"%s, messageId: %@", __FUNCTION__, urlString]];
  [[ResourceRepo shared] downLoadFile:urlString filePath:filePath progress:progress completion:completion];
}

@end
