// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NIMInputEmoticonManager.h"
#import <NEChatKit/NEALog.h>
#import "NSBundle+NEChatUIKit.h"

static NSString *const kClassTag = @"NIMInputEmoticonManager";

#pragma mark - NIMInputEmoticon

@implementation NIMInputEmoticon

- (NIMEmoticonType)type {
  if (self.unicode.length > 0) {
    return NIMEmoticonTypeUnicode;
  }
  return NIMEmoticonTypeFile;
}

@end

#pragma mark - NIMInputEmoticonLayout

@implementation NIMInputEmoticonLayout

- (instancetype)initWithWidth:(CGFloat)width {
  self = [super init];
  if (self) {
    _rows = NIMKit_EmojRows;
    _columes = ((NSInteger)width - NIMKit_EmojiLeftMargin - NIMKit_EmojiRightMargin) /
               (NSInteger)NIMKit_EmojImageWidth;
    _itemCountInPage = _rows * _columes - 1;
    _cellWidth =
        (CGFloat)(((NSInteger)width - NIMKit_EmojiLeftMargin - NIMKit_EmojiRightMargin) / _columes);
    _cellHeight = NIMKit_EmojCellHeight;
    _imageWidth = NIMKit_EmojImageWidth;
    _imageHeight = NIMKit_EmojImageHeight;
    _emoji = @(YES);
  }
  return self;
}

@end

#pragma mark - NIMInputEmoticonCatalog

@implementation NIMInputEmoticonCatalog
@end

#pragma mark - NIMInputEmoticonManager

@interface NIMInputEmoticonManager ()

@property (nonatomic, strong, nullable) NSArray<NIMInputEmoticonCatalog *> *catalogs;
@property (nonatomic, assign, readwrite) BOOL isCustomEmojResource;

@end

@implementation NIMInputEmoticonManager

+ (instancetype)shared {
  static NIMInputEmoticonManager *instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[NIMInputEmoticonManager alloc] init];
  });
  return instance;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _isCustomEmojResource = NO;
    [self parsePlist];
    [self preloadEmoticonResource];
  }
  return self;
}

- (void)setCustomEmojConfig:(NSArray *)array {
  NSMutableArray<NIMInputEmoticonCatalog *> *catalogs = [NSMutableArray array];
  for (id dict in array) {
    if ([dict isKindOfClass:[NSDictionary class]]) {
      NSDictionary *convertDict = (NSDictionary *)dict;
      NSDictionary *info = convertDict[@"info"];
      NSArray *emotions = convertDict[@"data"];
      NIMInputEmoticonCatalog *catalog = [self catalogByInfo:info emoticonsArray:emotions];
      [catalogs addObject:catalog];
    }
  }
  self.catalogs = catalogs;
  _isCustomEmojResource = YES;
}

- (void)parsePlist {
  NSMutableArray<NIMInputEmoticonCatalog *> *catalogs = [NSMutableArray array];
  NSString *filePath = [NSBundle nim_EmojiPlistFile];
  if (filePath) {
    NSArray *array = [NSArray arrayWithContentsOfFile:filePath];
    for (id dict in array) {
      if ([dict isKindOfClass:[NSDictionary class]]) {
        NSDictionary *convertDict = (NSDictionary *)dict;
        NSDictionary *info = convertDict[@"info"];
        NSArray *emotions = convertDict[@"data"];
        NIMInputEmoticonCatalog *catalog = [self catalogByInfo:info emoticonsArray:emotions];
        [catalogs addObject:catalog];
      }
    }
  }
  self.catalogs = catalogs;
}

- (NIMInputEmoticonCatalog *)catalogByInfo:(nullable NSDictionary *)info
                            emoticonsArray:(nullable NSArray *)emoticonsArray {
  NIMInputEmoticonCatalog *catalog = [[NIMInputEmoticonCatalog alloc] init];
  if (!info || !emoticonsArray) {
    [NEALog errorLog:kClassTag desc:@"info or emoticonsArray is nil"];
    return catalog;
  }

  catalog.catalogID = info[@"id"];
  catalog.title = info[@"title"];
  catalog.icon = info[@"normal"];
  catalog.iconPressed = info[@"pressed"];

  NSMutableDictionary<NSString *, NIMInputEmoticon *> *tag2Emoticons = [NSMutableDictionary dictionary];
  NSMutableDictionary<NSString *, NIMInputEmoticon *> *id2Emoticons = [NSMutableDictionary dictionary];
  NSMutableArray<NIMInputEmoticon *> *resultEmotions = [NSMutableArray array];

  for (id emoticonDict in emoticonsArray) {
    if ([emoticonDict isKindOfClass:[NSDictionary class]]) {
      NSDictionary *dict = (NSDictionary *)emoticonDict;
      NIMInputEmoticon *emotion = [[NIMInputEmoticon alloc] init];
      emotion.emoticonID = dict[@"id"];
      emotion.tag = dict[@"tag"];
      emotion.unicode = dict[@"unicode"];
      emotion.fileName = dict[@"file"];

      if (emotion.emoticonID.length > 0) {
        [resultEmotions addObject:emotion];
        id2Emoticons[emotion.emoticonID] = emotion;
      }
      if (emotion.tag.length > 0) {
        tag2Emoticons[emotion.tag] = emotion;
      }
    }
  }

  catalog.emoticons = resultEmotions;
  catalog.id2Emoticons = id2Emoticons;
  catalog.tag2Emoticons = tag2Emoticons;
  return catalog;
}

- (void)preloadEmoticonResource {
  // 预加载资源（目前为空实现，与 Swift 一致）
}

- (nullable NIMInputEmoticonCatalog *)emoticonCatalogWithID:(NSString *)catalogID {
  for (NIMInputEmoticonCatalog *catalog in self.catalogs) {
    if ([catalog.catalogID isEqualToString:catalogID]) {
      return catalog;
    }
  }
  return nil;
}

- (nullable NIMInputEmoticon *)emoticonByTag:(NSString *)tag {
  if (tag.length == 0) {
    return nil;
  }
  if (!self.catalogs) {
    [NEALog errorLog:kClassTag desc:@"catalogs is nil"];
    return nil;
  }
  for (NIMInputEmoticonCatalog *catalog in self.catalogs) {
    NIMInputEmoticon *emotion = catalog.tag2Emoticons[tag];
    if (emotion) {
      return emotion;
    }
  }
  return nil;
}

- (nullable NIMInputEmoticon *)emoticonByID:(NSString *)emoticonID {
  if (emoticonID.length == 0) {
    return nil;
  }
  if (!self.catalogs) {
    [NEALog errorLog:kClassTag desc:@"catalogs is nil"];
    return nil;
  }
  for (NIMInputEmoticonCatalog *catalog in self.catalogs) {
    NIMInputEmoticon *emotion = catalog.id2Emoticons[emoticonID];
    if (emotion) {
      return emotion;
    }
  }
  return nil;
}

- (nullable NIMInputEmoticon *)emoticonByCatalogID:(NSString *)catalogID
                                        emoticonID:(NSString *)emoticonID {
  if (catalogID.length == 0 || emoticonID.length == 0) {
    return nil;
  }
  if (!self.catalogs) {
    [NEALog errorLog:kClassTag desc:@"catalogs is nil"];
    return nil;
  }
  for (NIMInputEmoticonCatalog *catalog in self.catalogs) {
    if ([catalog.catalogID isEqualToString:catalogID]) {
      return catalog.id2Emoticons[emoticonID];
    }
  }
  return nil;
}

@end
