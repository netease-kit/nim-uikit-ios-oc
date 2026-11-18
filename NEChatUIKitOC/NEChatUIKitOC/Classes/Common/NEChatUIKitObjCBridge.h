// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "NEChatUIKitObjCModels.h"

@class NETeamMemberInfoModel;

NS_ASSUME_NONNULL_BEGIN

@interface NEChatUIKitObjCBridge : NSObject

@property (class, nonatomic, strong, readonly) NSBundle *chatBundle;
+ (NSString *)chatLocalizable:(NSString *)key;
+ (nullable UIImage *)chatLoadImage:(NSString *)name;
+ (NEChatUIKitImageResource *)chatImageResource:(NSString *)name;
+ (nullable NSString *)chatResourcePath:(nullable NSString *)source
                                    type:(nullable NSString *)type;
+ (NSString *)jsonStringFrom:(NSDictionary<NSString *, id> *)dictionary;
+ (nullable NSDictionary *)dictionaryFromJSONString:(NSString *)jsonString;

@property (class, nonatomic, assign, readonly) CGFloat screenWidth;
@property (class, nonatomic, assign, readonly) CGFloat screenHeight;
@property (class, nonatomic, assign, readonly) CGFloat screenWidthScale;
@property (class, nonatomic, assign, readonly) CGFloat screenHeightScale;
@property (class, nonatomic, assign, readonly) CGFloat navigationHeight;
@property (class, nonatomic, assign, readonly) CGFloat statusBarHeight;
@property (class, nonatomic, copy, readonly) NSString *moduleName;

@property (class, nonatomic, copy, readonly) NSArray<NSString *> *supportedAudioFileExtensions;
@property (class, nonatomic, copy, readonly) NSArray<NSString *> *supportedVideoFileExtensions;
@property (class, nonatomic, copy, readonly) NSArray<NSString *> *supportedImageFileExtensions;
@property (class, nonatomic, copy, readonly) NSArray<NSString *> *supportedSpreadsheetFileExtensions;
@property (class, nonatomic, copy, readonly) NSArray<NSString *> *supportedDocumentFileExtensions;
@property (class, nonatomic, copy, readonly) NSArray<NSString *> *supportedPresentationFileExtensions;
@property (class, nonatomic, copy, readonly) NSArray<NSString *> *supportedTextFileExtensions;
@property (class, nonatomic, copy, readonly) NSArray<NSString *> *supportedArchiveFileExtensions;
@property (class, nonatomic, copy, readonly) NSArray<NSString *> *supportedPDFFileExtensions;
@property (class, nonatomic, copy, readonly) NSArray<NSString *> *supportedHTMLFileExtensions;
@property (class, nonatomic, copy, readonly) NSDictionary<NSNumber *, NSString *> *antispamResultCodes;

@property (class, nonatomic, assign, readonly) CGFloat screenInterval;
@property (class, nonatomic, assign, readonly) CGFloat moreViewSectionPadding;
@property (class, nonatomic, copy, readonly) NSString *moreCellReuseIdentifier;
@property (class, nonatomic, assign, readonly) CGSize moreCellImageSize;
@property (class, nonatomic, assign, readonly) CGFloat moreCellTitleHeight;
@property (class, nonatomic, assign, readonly) CGFloat moreViewMargin;
@property (class, nonatomic, assign, readonly) NSInteger moreViewColumnCount;

@property (class, nonatomic, assign, readonly) CGFloat chatCellMargin;
@property (class, nonatomic, assign, readonly) CGFloat chatContentMargin;
@property (class, nonatomic, assign, readonly) CGFloat chatAvatarSize;
@property (class, nonatomic, assign, readonly) CGFloat chatTimeCellHeight;
@property (class, nonatomic, assign, readonly) CGSize chatPictureSize;
@property (class, nonatomic, assign, readonly) CGSize chatFileSize;
@property (class, nonatomic, assign, readonly) CGFloat chatMinimumHeight;
@property (class, nonatomic, assign, readonly) CGFloat funChatMinimumHeight;
@property (class, nonatomic, assign, readonly) CGFloat chatReplyHeight;
@property (class, nonatomic, assign, readonly) CGFloat funChatReplyHeight;
@property (class, nonatomic, assign, readonly) CGFloat chatContentMaximumWidth;
@property (class, nonatomic, assign, readonly) CGFloat chatTextMaximumWidth;
@property (class, nonatomic, assign, readonly) CGFloat chatPinHeight;
@property (class, nonatomic, assign, readonly) CGFloat chatFullNameHeight;
@property (class, nonatomic, assign, readonly) CGFloat audioMaximumWidth;
@property (class, nonatomic, assign, readonly) CGFloat aiChatViewHeight;

@property (class, nonatomic, copy, readonly) NSString *atMessageKey;
@property (class, nonatomic, assign, readonly) NSInteger atRangeOffsetValue;
@property (class, nonatomic, copy, readonly) NSString *atSegmentsKeyValue;
@property (class, nonatomic, copy, readonly) NSString *atTextKeyValue;

@property (class, nonatomic, copy, readonly) NSString *emojiCatalog;
@property (class, nonatomic, copy, readonly) NSString *emojiPath;
@property (class, nonatomic, copy, readonly) NSString *chartletCatalogPath;
@property (class, nonatomic, copy, readonly) NSString *chartletCatalogContentPath;
@property (class, nonatomic, copy, readonly) NSString *chartletCatalogIconPath;
@property (class, nonatomic, copy, readonly) NSString *chartletNormalIconSuffix;
@property (class, nonatomic, copy, readonly) NSString *chartletHighlightedIconSuffix;
@property (class, nonatomic, assign, readonly) NSInteger emojiLeftMargin;
@property (class, nonatomic, assign, readonly) NSInteger emojiRightMargin;
@property (class, nonatomic, assign, readonly) NSInteger emojiTopMargin;
@property (class, nonatomic, assign, readonly) CGFloat deleteIconWidth;
@property (class, nonatomic, assign, readonly) CGFloat deleteIconHeight;
@property (class, nonatomic, assign, readonly) CGFloat emojiCellHeight;
@property (class, nonatomic, assign, readonly) CGFloat emojiImageHeight;
@property (class, nonatomic, assign, readonly) CGFloat emojiImageWidth;
@property (class, nonatomic, assign, readonly) NSInteger emojiRows;
@property (class, nonatomic, assign, readonly) CGFloat pictureCellHeight;
@property (class, nonatomic, assign, readonly) CGFloat pictureImageHeight;
@property (class, nonatomic, assign, readonly) CGFloat pictureImageWidth;
@property (class, nonatomic, assign, readonly) NSInteger pictureRows;

@property (class, nonatomic, copy, readonly) NSNotificationName markdownImageDidLoadNotification;

+ (void)invokeSelectionHandler:(void (^)(NSInteger index,
                                          NETeamMemberInfoModel *_Nullable model))handler
                          index:(NSInteger)index
                          model:(nullable NETeamMemberInfoModel *)model;

@end

NS_ASSUME_NONNULL_END
