// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import <NEChatKit/NECoreIM2Constant.h>
#import <NEChatKit/NSObject+YXModel.h>
#import "ChatInputViewDelegate.h"
#import "MessageAtInfoModel.h"
#import "NETeamUserManager.h"
#import "NETranslateLanguageManager.h"

#ifndef ChatMessageStatusSuccessed
#define ChatMessageStatusSuccessed ChatSendMessageStatusSuccessed
#endif

#ifndef ChatMessageStatusSending
#define ChatMessageStatusSending ChatSendMessageStatusSending
#endif

#ifndef ChatMessageStatusFailed
#define ChatMessageStatusFailed ChatSendMessageStatusFailed
#endif

#ifndef ChatMessageStatusSendingFailed
#define ChatMessageStatusSendingFailed ChatSendMessageStatusSendingFailed
#endif

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Localization Utility

/// Chat module localization helper — equivalent to Swift `chatLocalizable(_:)`
NSString *chatLocalizable(NSString *key);

/// Load image from chat bundle — equivalent to Swift `chatCoreLoader.loadImage(_:)`
UIImage * _Nullable chatLoadImage(NSString *name);

/// Return the chat resource bundle — equivalent to Swift `chatCoreLoader.bundle`
NSBundle * _Nullable chatBundle(void);

#pragma mark - JSON Utility Functions

/// Convert dictionary to JSON string — equivalent to Swift `getJSONStringFromDictionary(_:)`
NSString *getJSONStringFromDictionary(NSDictionary<NSString *, id> *dictionary);

/// Convert JSON string to dictionary — equivalent to Swift `getDictionaryFromJSONString(_:)`
NSDictionary * _Nullable getDictionaryFromJSONString(NSString *jsonString);

#pragma mark - ViewModelDelegate Protocol

@protocol ViewModelDelegate <NSObject>

- (void)dataDidChange;
- (void)dataDidError:(NSError *)error;

@optional
- (void)dataNoMore;

@end

#pragma mark - Screen Constants

FOUNDATION_EXPORT CGFloat const kScreenInterval;
FOUNDATION_EXPORT CGFloat const kNavigationHeight;

/// Screen width / height (dynamic, use as functions)
FOUNDATION_EXPORT CGFloat kScreenWidth;
FOUNDATION_EXPORT CGFloat kScreenHeight;
#define kScreenWidth() (kScreenWidth)
#define kScreenHeight() (kScreenHeight)
CGFloat kUISreenWidthScale(void);
CGFloat kUISreenHeightScale(void);
CGFloat KStatusBarHeight(void);

/// Font helpers
UIFont *TextFont(NSString *fontName, CGFloat fontSize);
UIFont *DefaultTextFont(CGFloat fontSize);

/// Module name for logging
FOUNDATION_EXPORT NSString *const ChatUIKitModuleName;

/// Shorthand alias for ChatUIKitModuleName (used across files)
#define ModuleName ChatUIKitModuleName

#pragma mark - File Format Support Arrays

/// Supported audio formats (lowercased)
FOUNDATION_EXPORT NSArray<NSString *> *file_audio_support(void);
/// Supported video formats (lowercased)
FOUNDATION_EXPORT NSArray<NSString *> *file_video_support(void);
/// Supported image formats (lowercased)
FOUNDATION_EXPORT NSArray<NSString *> *file_img_support(void);
/// Supported spreadsheet formats (lowercased)
FOUNDATION_EXPORT NSArray<NSString *> *file_xls_support(void);
/// Supported document formats (lowercased)
FOUNDATION_EXPORT NSArray<NSString *> *file_doc_support(void);
/// Supported PPT formats (lowercased)
FOUNDATION_EXPORT NSArray<NSString *> *file_ppt_support(void);
/// Supported text formats (lowercased)
FOUNDATION_EXPORT NSArray<NSString *> *file_txt_support(void);
/// Supported archive formats (lowercased)
FOUNDATION_EXPORT NSArray<NSString *> *file_zip_support(void);
/// Supported PDF formats (lowercased)
FOUNDATION_EXPORT NSArray<NSString *> *file_pdf_support(void);
/// Supported HTML formats (lowercased)
FOUNDATION_EXPORT NSArray<NSString *> *file_html_support(void);

#pragma mark - Anti-spam Result Code Dictionary

/// [Anti-spam error code : description]
NSDictionary<NSNumber *, NSString *> *antispamResultCodeDic(void);

#pragma mark - More View Constants

FOUNDATION_EXPORT NSString *const NEMoreCell_ReuseId;
FOUNDATION_EXPORT CGFloat const NEMoreView_Section_Padding;
FOUNDATION_EXPORT CGFloat const NEMoreCell_Title_Height;
FOUNDATION_EXPORT CGFloat const NEMoreView_Margin;
FOUNDATION_EXPORT NSInteger const NEMoreView_Column_Count;

/// NEMoreCell_Image_Size (56 x 56)
CGSize NEMoreCell_Image_Size(void);

#pragma mark - Color Utility

UIColor *HexRGB(NSInteger rgbValue);
UIColor *HexRGBAlpha(NSInteger rgbValue, CGFloat alpha);

#pragma mark - Internal Colors

FOUNDATION_EXPORT UIColor *TextNormalColor(void);
FOUNDATION_EXPORT UIColor *SubTextColor(void);
FOUNDATION_EXPORT UIColor *PlaceholderTextColor(void);
FOUNDATION_EXPORT UIColor *multiForwardLineColor(void);
FOUNDATION_EXPORT UIColor *forwardLineColor(void);
FOUNDATION_EXPORT UIColor *multiForwardborderColor(void);

#pragma mark - Notification Names (NEChatUIKit specific)

FOUNDATION_EXPORT NSNotificationName const NENotificationCreateServer;
FOUNDATION_EXPORT NSNotificationName const NENotificationCreateChannel;
FOUNDATION_EXPORT NSNotificationName const NENotificationUpdateChannel;
FOUNDATION_EXPORT NSNotificationName const NENotificationDeleteChannel;
FOUNDATION_EXPORT NSNotificationName const NENotificationLeaveTeamBySelf;
FOUNDATION_EXPORT NSNotificationName const NENotificationLogout;
FOUNDATION_EXPORT NSNotificationName const NENotificationPopGroupChatVC;

NS_ASSUME_NONNULL_END
