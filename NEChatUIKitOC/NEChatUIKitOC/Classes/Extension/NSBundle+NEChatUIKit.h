// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSBundle (NEChatUIKit)

/// Returns the default emoji bundle (NIMKitEmoticon.bundle)
+ (NSBundle * _Nullable)nim_defaultEmojiBundle;

/// Returns the path to the emoji plist file (emoji_ios_cn.plist)
+ (NSString * _Nullable)nim_EmojiPlistFile;

/// Returns the path to an emoji image with the given name (supports @2x/@3x)
+ (NSString * _Nullable)nim_EmojiImageWithImageName:(NSString *)imageName;

@end

NS_ASSUME_NONNULL_END
