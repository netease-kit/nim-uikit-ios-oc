// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEChatUIKitObjCBridge.h"

#import <NEChatKit/NECommonLoader.h>

#import "ChatCellConstantValue.h"
#import "NEBaseChatInputView.h"
#import "NEChatBaseViewController.h"
#import "NEChatUIConstant.h"
#import "NEMarkdownImage.h"
#import "NIMInputEmoticonDefine.h"

@interface NEChatUIKitImageResource (NEChatUIKitInternal)
- (instancetype)initWithName:(NSString *)name bundle:(NSBundle *)bundle;
@end

@implementation NEChatUIKitObjCBridge

+ (NECommonLoader *)resourceLoader {
  static NECommonLoader *loader = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    loader = [[NECommonLoader alloc] initWithClass:[NEChatBaseViewController class]];
  });
  return loader;
}

+ (NSBundle *)chatBundle { return self.resourceLoader.bundle; }
+ (NSString *)chatLocalizable:(NSString *)key { return chatLocalizable(key); }
+ (UIImage *)chatLoadImage:(NSString *)name { return [self.resourceLoader loadImage:name]; }
+ (NEChatUIKitImageResource *)chatImageResource:(NSString *)name {
  return [[NEChatUIKitImageResource alloc] initWithName:name bundle:self.chatBundle];
}
+ (NSString *)chatResourcePath:(NSString *)source type:(NSString *)type {
  return [self.resourceLoader loadStringSource:source type:type];
}
+ (NSString *)jsonStringFrom:(NSDictionary<NSString *,id> *)dictionary {
  return getJSONStringFromDictionary(dictionary);
}
+ (NSDictionary *)dictionaryFromJSONString:(NSString *)jsonString {
  return getDictionaryFromJSONString(jsonString);
}

+ (CGFloat)screenWidth { return kScreenWidth(); }
+ (CGFloat)screenHeight { return kScreenHeight(); }
+ (CGFloat)screenWidthScale { return kUISreenWidthScale(); }
+ (CGFloat)screenHeightScale { return kUISreenHeightScale(); }
+ (CGFloat)navigationHeight { return kNavigationHeight; }
+ (CGFloat)statusBarHeight { return KStatusBarHeight(); }
+ (NSString *)moduleName { return ModuleName; }

+ (NSArray<NSString *> *)supportedAudioFileExtensions { return file_audio_support(); }
+ (NSArray<NSString *> *)supportedVideoFileExtensions { return file_video_support(); }
+ (NSArray<NSString *> *)supportedImageFileExtensions { return file_img_support(); }
+ (NSArray<NSString *> *)supportedSpreadsheetFileExtensions { return file_xls_support(); }
+ (NSArray<NSString *> *)supportedDocumentFileExtensions { return file_doc_support(); }
+ (NSArray<NSString *> *)supportedPresentationFileExtensions { return file_ppt_support(); }
+ (NSArray<NSString *> *)supportedTextFileExtensions { return file_txt_support(); }
+ (NSArray<NSString *> *)supportedArchiveFileExtensions { return file_zip_support(); }
+ (NSArray<NSString *> *)supportedPDFFileExtensions { return file_pdf_support(); }
+ (NSArray<NSString *> *)supportedHTMLFileExtensions { return file_html_support(); }
+ (NSDictionary<NSNumber *,NSString *> *)antispamResultCodes { return antispamResultCodeDic(); }

+ (CGFloat)screenInterval { return kScreenInterval; }
+ (CGFloat)moreViewSectionPadding { return NEMoreView_Section_Padding; }
+ (NSString *)moreCellReuseIdentifier { return NEMoreCell_ReuseId; }
+ (CGSize)moreCellImageSize { return NEMoreCell_Image_Size(); }
+ (CGFloat)moreCellTitleHeight { return NEMoreCell_Title_Height; }
+ (CGFloat)moreViewMargin { return NEMoreView_Margin; }
+ (NSInteger)moreViewColumnCount { return NEMoreView_Column_Count; }

+ (CGFloat)chatCellMargin { return chat_cell_margin; }
+ (CGFloat)chatContentMargin { return chat_content_margin; }
+ (CGFloat)chatAvatarSize { return chat_headWH; }
+ (CGFloat)chatTimeCellHeight { return chat_timeCellH; }
+ (CGSize)chatPictureSize { return chat_pic_size(); }
+ (CGSize)chatFileSize { return chat_file_size(); }
+ (CGFloat)chatMinimumHeight { return chat_min_h; }
+ (CGFloat)funChatMinimumHeight { return fun_chat_min_h; }
+ (CGFloat)chatReplyHeight { return chat_reply_height; }
+ (CGFloat)funChatReplyHeight { return fun_chat_reply_height; }
+ (CGFloat)chatContentMaximumWidth { return chat_content_maxW(); }
+ (CGFloat)chatTextMaximumWidth { return chat_text_maxW(); }
+ (CGFloat)chatPinHeight { return chat_pin_height; }
+ (CGFloat)chatFullNameHeight { return chat_full_name_height; }
+ (CGFloat)audioMaximumWidth { return audio_max_width(); }
+ (CGFloat)aiChatViewHeight { return ai_chat_view_height; }

+ (NSString *)atMessageKey { return yxAtMsg; }
+ (NSInteger)atRangeOffsetValue { return atRangeOffset; }
+ (NSString *)atSegmentsKeyValue { return atSegmentsKey; }
+ (NSString *)atTextKeyValue { return atTextKey; }

+ (NSString *)emojiCatalog { return NIMKit_EmojiCatalog; }
+ (NSString *)emojiPath { return NIMKit_EmojiPath; }
+ (NSString *)chartletCatalogPath { return NIMKit_ChartletChartletCatalogPath; }
+ (NSString *)chartletCatalogContentPath { return NIMKit_ChartletChartletCatalogContentPath; }
+ (NSString *)chartletCatalogIconPath { return NIMKit_ChartletChartletCatalogIconPath; }
+ (NSString *)chartletNormalIconSuffix { return NIMKit_ChartletChartletCatalogIconsSuffixNormal; }
+ (NSString *)chartletHighlightedIconSuffix { return NIMKit_ChartletChartletCatalogIconsSuffixHighLight; }
+ (NSInteger)emojiLeftMargin { return NIMKit_EmojiLeftMargin; }
+ (NSInteger)emojiRightMargin { return NIMKit_EmojiRightMargin; }
+ (NSInteger)emojiTopMargin { return NIMKit_EmojiTopMargin; }
+ (CGFloat)deleteIconWidth { return NIMKit_DeleteIconWidth; }
+ (CGFloat)deleteIconHeight { return NIMKit_DeleteIconHeight; }
+ (CGFloat)emojiCellHeight { return NIMKit_EmojCellHeight; }
+ (CGFloat)emojiImageHeight { return NIMKit_EmojImageHeight; }
+ (CGFloat)emojiImageWidth { return NIMKit_EmojImageWidth; }
+ (NSInteger)emojiRows { return NIMKit_EmojRows; }
+ (CGFloat)pictureCellHeight { return NIMKit_PicCellHeight; }
+ (CGFloat)pictureImageHeight { return NIMKit_PicImageHeight; }
+ (CGFloat)pictureImageWidth { return NIMKit_PicImageWidth; }
+ (NSInteger)pictureRows { return NIMKit_PicRows; }

+ (NSNotificationName)markdownImageDidLoadNotification {
  return NEMarkdownImageDidLoadNotification;
}

+ (void)invokeSelectionHandler:(void (^)(NSInteger, NETeamMemberInfoModel * _Nullable))handler
                          index:(NSInteger)index
                          model:(NETeamMemberInfoModel *)model {
  handler(index, model);
}

@end
