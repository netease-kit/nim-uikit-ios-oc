// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NSBundle+NEChatUIKit.h"
#import "NEChatUIConstant.h"

static NSString *const NIMKit_EmojiPath = @"Emoji";

@implementation NSBundle (NEChatUIKit)

+ (NSBundle *)nim_defaultEmojiBundle {
  NSBundle *bundle = chatBundle();
  NSURL *url = [bundle URLForResource:@"NIMKitEmoticon" withExtension:@"bundle"];
  if (url) {
    return [NSBundle bundleWithURL:url];
  }
  return nil;
}

+ (NSString *)nim_EmojiPlistFile {
  NSBundle *emojiBundle = [NSBundle nim_defaultEmojiBundle];
  NSString *resource = @"emoji_ios_cn";
  NSString *filepath = [emojiBundle pathForResource:resource
                                             ofType:@"plist"
                                        inDirectory:NIMKit_EmojiPath];
  return filepath;
}

+ (NSString *)nim_EmojiImageWithImageName:(NSString *)imageName {
  NSBundle *emojiBundle = [NSBundle nim_defaultEmojiBundle];

  // Extract extension; default to png
  NSString *ext = [imageName pathExtension];
  if (ext.length == 0) {
    ext = @"png";
  }
  NSString *name = [imageName stringByDeletingPathExtension];

  NSString *doubleImage = [name stringByAppendingString:@"@2x"];
  NSString *tripleImage = [name stringByAppendingString:@"@3x"];

  NSString *path = nil;

  // Prefer @3x on 3x screens
  if ([UIScreen mainScreen].scale == 3.0) {
    path = [emojiBundle pathForResource:tripleImage
                                 ofType:ext
                            inDirectory:NIMKit_EmojiPath];
  }

  // Fallback to @2x
  if (!path || path.length == 0) {
    path = [emojiBundle pathForResource:doubleImage
                                 ofType:ext
                            inDirectory:NIMKit_EmojiPath];
  }

  return path;
}

@end
