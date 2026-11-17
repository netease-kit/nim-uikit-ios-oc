// Copyright (c) 2026 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// A local image that can be displayed in the input panel and sent as an image message.
@interface NIMInputSticker : NSObject

@property (nonatomic, copy, readonly) NSString *stickerID;
@property (nonatomic, copy, readonly) NSURL *fileURL;

- (instancetype)initWithStickerID:(NSString *)stickerID
                           fileURL:(NSURL *)fileURL NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

/// An ordered group of local stickers shown as one input-panel tab.
@interface NIMInputStickerPackage : NSObject

@property (nonatomic, copy, readonly) NSString *packageID;
@property (nonatomic, copy, nullable, readonly) NSString *title;
@property (nonatomic, strong, readonly) UIImage *normalIcon;
@property (nonatomic, strong, readonly) UIImage *selectedIcon;
@property (nonatomic, copy, readonly) NSArray<NIMInputSticker *> *stickers;

- (instancetype)initWithPackageID:(NSString *)packageID
                             title:(nullable NSString *)title
                        normalIcon:(UIImage *)normalIcon
                      selectedIcon:(UIImage *)selectedIcon
                          stickers:(NSArray<NIMInputSticker *> *)stickers NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

/// Notifications emitted by the process-wide sticker registry.
@interface NIMInputStickerNotification : NSObject

@property (class, nonatomic, readonly) NSNotificationName packagesDidChange;

@end

NS_ASSUME_NONNULL_END
