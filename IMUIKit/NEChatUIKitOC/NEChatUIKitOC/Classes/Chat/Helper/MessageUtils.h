// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
@class V2NIMMessage;

NS_ASSUME_NONNULL_BEGIN

@interface MessageUtils : NSObject

+ (V2NIMMessage *)textMessageWithText:(NSString *)text
                             remoteExt:(nullable NSDictionary<NSString *, id> *)remoteExt;

+ (V2NIMMessage *)textMessageWithText:(NSString *)text;

+ (V2NIMMessage *)forwardMessageWithMessage:(V2NIMMessage *)message;

+ (V2NIMMessage *)imageMessageWithPath:(NSString *)path
                                   name:(nullable NSString *)name
                              sceneName:(nullable NSString *)sceneName
                                  width:(int32_t)width
                                 height:(int32_t)height;

+ (V2NIMMessage *)audioMessageWithFilePath:(NSString *)filePath
                                       name:(nullable NSString *)name
                                  sceneName:(nullable NSString *)sceneName
                                   duration:(int32_t)duration;

+ (V2NIMMessage *)videoMessageWithFilePath:(NSString *)filePath
                                       name:(nullable NSString *)name
                                  sceneName:(nullable NSString *)sceneName
                                      width:(int32_t)width
                                     height:(int32_t)height
                                   duration:(int32_t)duration;

+ (V2NIMMessage *)locationMessageWithLat:(double)lat
                                      lng:(double)lng
                                  address:(NSString *)address;

+ (V2NIMMessage *)fileMessageWithFilePath:(NSString *)filePath
                               displayName:(nullable NSString *)displayName
                                 sceneName:(nullable NSString *)sceneName;

+ (V2NIMMessage *)customMessageWithText:(NSString *)text
                           rawAttachment:(NSString *)rawAttachment;

+ (V2NIMMessage *)tipMessageWithText:(NSString *)text;

@end

NS_ASSUME_NONNULL_END
