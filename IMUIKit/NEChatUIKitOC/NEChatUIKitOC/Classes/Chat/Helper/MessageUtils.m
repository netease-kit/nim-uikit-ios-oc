// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "MessageUtils.h"
#import <NIMSDK/NIMSDK.h>

@implementation MessageUtils

+ (V2NIMMessage *)textMessageWithText:(NSString *)text
                             remoteExt:(NSDictionary<NSString *, id> *)remoteExt {
  V2NIMMessage *message = [V2NIMMessageCreator createTextMessage:text];
  if (remoteExt) {
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:remoteExt options:0 error:nil];
    if (jsonData) {
      message.serverExtension = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
  }
  return message;
}

+ (V2NIMMessage *)textMessageWithText:(NSString *)text {
  return [V2NIMMessageCreator createTextMessage:text];
}

+ (V2NIMMessage *)forwardMessageWithMessage:(V2NIMMessage *)message {
  return [V2NIMMessageCreator createForwardMessage:message];
}

+ (V2NIMMessage *)imageMessageWithPath:(NSString *)path
                                   name:(NSString *)name
                              sceneName:(NSString *)sceneName
                                  width:(int32_t)width
                                 height:(int32_t)height {
  NSString *scene = sceneName ?: [V2NIMStorageSceneConfig DEFAULT_IM].sceneName;
  return [V2NIMMessageCreator createImageMessage:path
                                            name:name
                                       sceneName:scene
                                           width:width
                                          height:height];
}

+ (V2NIMMessage *)audioMessageWithFilePath:(NSString *)filePath
                                       name:(NSString *)name
                                  sceneName:(NSString *)sceneName
                                   duration:(int32_t)duration {
  NSString *scene = sceneName ?: [V2NIMStorageSceneConfig DEFAULT_IM].sceneName;
  return [V2NIMMessageCreator createAudioMessage:filePath
                                            name:name
                                       sceneName:scene
                                        duration:duration];
}

+ (V2NIMMessage *)videoMessageWithFilePath:(NSString *)filePath
                                       name:(NSString *)name
                                  sceneName:(NSString *)sceneName
                                      width:(int32_t)width
                                     height:(int32_t)height
                                   duration:(int32_t)duration {
  NSString *scene = sceneName ?: [V2NIMStorageSceneConfig DEFAULT_IM].sceneName;
  return [V2NIMMessageCreator createVideoMessage:filePath
                                            name:name
                                       sceneName:scene
                                        duration:duration
                                           width:width
                                          height:height];
}

+ (V2NIMMessage *)locationMessageWithLat:(double)lat
                                      lng:(double)lng
                                  address:(NSString *)address {
  return [V2NIMMessageCreator createLocationMessage:lat longitude:lng address:address];
}

+ (V2NIMMessage *)fileMessageWithFilePath:(NSString *)filePath
                               displayName:(NSString *)displayName
                                 sceneName:(NSString *)sceneName {
  NSString *scene = sceneName ?: [V2NIMStorageSceneConfig DEFAULT_IM].sceneName;
  return [V2NIMMessageCreator createFileMessage:filePath
                                           name:displayName
                                      sceneName:scene];
}

+ (V2NIMMessage *)customMessageWithText:(NSString *)text
                           rawAttachment:(NSString *)rawAttachment {
  return [V2NIMMessageCreator createCustomMessage:text rawAttachment:rawAttachment];
}

+ (V2NIMMessage *)tipMessageWithText:(NSString *)text {
  return [V2NIMMessageCreator createTipsMessage:text];
}

@end
