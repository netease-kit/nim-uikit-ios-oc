// Copyright (c) 2026 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NIMInputSticker.h"

@interface NIMInputSticker ()

@property (nonatomic, copy, readwrite) NSString *stickerID;
@property (nonatomic, copy, readwrite) NSURL *fileURL;

@end

@implementation NIMInputSticker

- (instancetype)initWithStickerID:(NSString *)stickerID fileURL:(NSURL *)fileURL {
  self = [super init];
  if (self) {
    _stickerID = [stickerID copy];
    _fileURL = [fileURL copy];
  }
  return self;
}

@end

@interface NIMInputStickerPackage ()

@property (nonatomic, copy, readwrite) NSString *packageID;
@property (nonatomic, copy, nullable, readwrite) NSString *title;
@property (nonatomic, strong, readwrite) UIImage *normalIcon;
@property (nonatomic, strong, readwrite) UIImage *selectedIcon;
@property (nonatomic, copy, readwrite) NSArray<NIMInputSticker *> *stickers;

@end

@implementation NIMInputStickerPackage

- (instancetype)initWithPackageID:(NSString *)packageID
                             title:(nullable NSString *)title
                        normalIcon:(UIImage *)normalIcon
                      selectedIcon:(UIImage *)selectedIcon
                          stickers:(NSArray<NIMInputSticker *> *)stickers {
  self = [super init];
  if (self) {
    _packageID = [packageID copy];
    _title = [title copy];
    _normalIcon = normalIcon;
    _selectedIcon = selectedIcon;
    _stickers = [stickers copy];
  }
  return self;
}

@end

@implementation NIMInputStickerNotification

+ (NSNotificationName)packagesDidChange {
  return @"NIMInputStickerPackagesDidChangeNotification";
}

@end
