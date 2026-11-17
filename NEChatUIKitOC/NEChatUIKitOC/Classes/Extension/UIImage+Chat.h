// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (Chat)

/// Load an image by name from the chat bundle (uses chatLoadImage).
/// @param name  Image name (nullable — returns nil if nil)
+ (UIImage * _Nullable)ne_imageNamed:(NSString * _Nullable)name;

/// Load an emoji image from NIMKitEmoticon.bundle/Emoji/<name>.
/// @param name  Emoji image file name
+ (UIImage *)ne_bundleImage:(NSString *)name;

/// Fix image orientation — re-draw using CGAffineTransform so imageOrientation becomes .up.
- (UIImage *)fixOrientation;

@end

NS_ASSUME_NONNULL_END
