// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEChatUIConstant.h"
#import "NEChatBaseViewController.h"
#import "NEChatUIKitClient.h"
#import <NEChatKit/NEAppLanguageUtil.h>

#pragma mark - Localization Utility

static NSArray<NSBundle *> * _Nonnull _chatCandidateBundles(void) {
  static NSArray<NSBundle *> *bundles = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    NSMutableOrderedSet<NSBundle *> *candidates = [NSMutableOrderedSet orderedSet];
    void (^addBundle)(NSBundle * _Nullable) = ^(NSBundle * _Nullable bundle) {
      if (bundle) {
        [candidates addObject:bundle];
      }
    };

    // Align with Swift CommonLoader<NEChatBaseViewController>.
    addBundle([NSBundle bundleForClass:[NEChatBaseViewController class]]);
    // Keep the client class as a compatibility fallback for packaging differences.
    addBundle([NSBundle bundleForClass:[NEChatUIKitClient class]]);

    for (NSBundle *framework in [NSBundle allFrameworks]) {
      if ([framework.bundleURL.lastPathComponent isEqualToString:@"NEChatUIKitOC.framework"]) {
        addBundle(framework);
        break;
      }
    }

    addBundle([NSBundle mainBundle]);

    if (candidates.count > 0) {
      bundles = [candidates.array copy];
    } else {
      bundles = @[[NSBundle mainBundle]];
    }
  });
  return bundles;
}

static BOOL _chatBundleContainsResources(NSBundle *bundle) {
  if (!bundle) {
    return NO;
  }
  if ([bundle URLForResource:@"NIMKitEmoticon" withExtension:@"bundle"]) {
    return YES;
  }
  if ([bundle pathForResource:@"emoji_ios_en" ofType:@"plist"]) {
    return YES;
  }
  return [bundle pathForResource:@"Localizable" ofType:@"strings" inDirectory:@"zh-Hans.lproj"] != nil;
}

/// Returns the chat bundle used for loading images and localized strings.
static NSBundle *_Nullable _chatBundle(void) {
  static NSBundle *bundle = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    for (NSBundle *candidate in _chatCandidateBundles()) {
      if (_chatBundleContainsResources(candidate)) {
        bundle = candidate;
        break;
      }
    }
    if (!bundle) {
      bundle = _chatCandidateBundles().firstObject ?: [NSBundle mainBundle];
    }
  });
  return bundle;
}

NSString *chatLocalizable(NSString *key) {
  NEAppLanguage currentLanguage = [NEAppLanguageUtil getCurrentLanguage];
  NSString *language = currentLanguage == NEAppLanguageEnglish ? @"en" : @"zh-Hans";
  NSString *const missingValue = @"__NEChatUIKitMissing__";
  for (NSBundle *bundle in _chatCandidateBundles()) {
    NSBundle *stringBundle = bundle;
    NSString *lprojPath = [bundle pathForResource:language ofType:@"lproj"];
    if (!lprojPath) {
      NSString *prefix = [[language componentsSeparatedByString:@"-"] firstObject];
      lprojPath = [bundle pathForResource:prefix ofType:@"lproj"];
    }
    if (lprojPath) {
      NSBundle *candidate = [NSBundle bundleWithPath:lprojPath];
      if (candidate) {
        stringBundle = candidate;
      }
    }
    NSString *value = [stringBundle localizedStringForKey:key value:missingValue table:@"Localizable"];
    if (![value isEqualToString:missingValue]) {
      return value;
    }
  }
  return key;
}

UIImage * _Nullable chatLoadImage(NSString *name) {
  if (name.length == 0) {
    return nil;
  }

  NSBundle *preferredBundle = _chatBundle();
  if (preferredBundle) {
    UIImage *image = [UIImage imageNamed:name
                                inBundle:preferredBundle
           compatibleWithTraitCollection:nil];
    if (image) {
      return image;
    }
  }

  for (NSBundle *bundle in _chatCandidateBundles()) {
    if (bundle == preferredBundle) {
      continue;
    }
    UIImage *image = [UIImage imageNamed:name
                                inBundle:bundle
           compatibleWithTraitCollection:nil];
    if (image) {
      return image;
    }
  }

  return nil;
}

NSBundle * _Nullable chatBundle(void) {
  return _chatBundle();
}

#pragma mark - JSON Utility Functions

NSString *getJSONStringFromDictionary(NSDictionary<NSString *, id> *dictionary) {
  if (![NSJSONSerialization isValidJSONObject:dictionary]) {
    NSLog(@"not parse to json string");
    return @"";
  }
  NSError *error = nil;
  NSData *data = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:&error];
  if (data && !error) {
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] ?: @"";
  }
  return @"";
}

NSDictionary * _Nullable getDictionaryFromJSONString(NSString *jsonString) {
  NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
  if (!data) return nil;
  NSError *error = nil;
  id obj = [NSJSONSerialization JSONObjectWithData:data
                                           options:NSJSONReadingMutableContainers
                                             error:&error];
  if ([obj isKindOfClass:[NSDictionary class]]) {
    return (NSDictionary *)obj;
  }
  return nil;
}

#pragma mark - Screen Constants

CGFloat const kScreenInterval = 20.0;
CGFloat const kNavigationHeight = 44.0;
NSString *const ChatUIKitModuleName = @"NEChatUIKit";

CGFloat kScreenWidth = 0;
CGFloat kScreenHeight = 0;

static void NEChatRefreshScreenMetrics(void) {
  CGSize size = [UIScreen mainScreen].bounds.size;
  kScreenWidth = size.width;
  kScreenHeight = size.height;
}

__attribute__((constructor))
static void NEChatInstallScreenMetricObserver(void) {
  @autoreleasepool {
    NEChatRefreshScreenMetrics();

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    void (^refreshBlock)(NSNotification *) = ^(__unused NSNotification *note) {
      NEChatRefreshScreenMetrics();
    };
    [center addObserverForName:UIApplicationDidChangeStatusBarOrientationNotification
                        object:nil
                         queue:NSOperationQueue.mainQueue
                    usingBlock:refreshBlock];
    [center addObserverForName:UIApplicationDidChangeStatusBarFrameNotification
                        object:nil
                         queue:NSOperationQueue.mainQueue
                    usingBlock:refreshBlock];
  }
}

CGFloat kUISreenWidthScale(void) {
  return kScreenWidth() / 375.0;
}

CGFloat kUISreenHeightScale(void) {
  return kScreenHeight() / 667.0;
}

CGFloat KStatusBarHeight(void) {
  return [UIApplication sharedApplication].statusBarFrame.size.height;
}

UIFont *TextFont(NSString *fontName, CGFloat fontSize) {
  UIFont *font = [UIFont fontWithName:fontName size:fontSize];
  return font ?: [UIFont systemFontOfSize:fontSize];
}

UIFont *DefaultTextFont(CGFloat fontSize) {
  return TextFont(@"PingFangSC-Regular", fontSize);
}

#pragma mark - File Format Support Arrays

NSArray<NSString *> *file_audio_support(void) {
  return @[@"mp3", @"aac", @"wav", @"wma", @"flac"];
}

NSArray<NSString *> *file_video_support(void) {
  return @[@"mp4", @"avi", @"wmv", @"mpeg", @"m4v", @"mov", @"asf", @"flv", @"f4v", @"rmvb", @"rm", @"3gp"];
}

NSArray<NSString *> *file_img_support(void) {
  return @[@"jpg", @"jpeg", @"png", @"tiff", @"heic", @"gif"];
}

NSArray<NSString *> *file_xls_support(void) {
  return @[@"xls", @"xlsx", @"csv"];
}

NSArray<NSString *> *file_doc_support(void) {
  return @[@"doc", @"docx"];
}

NSArray<NSString *> *file_ppt_support(void) {
  return @[@"ppt", @"pptx"];
}

NSArray<NSString *> *file_txt_support(void) {
  return @[@"txt"];
}

NSArray<NSString *> *file_zip_support(void) {
  return @[@"zip", @"tar", @"rar", @"7z"];
}

NSArray<NSString *> *file_pdf_support(void) {
  return @[@"pdf", @"rtf"];
}

NSArray<NSString *> *file_html_support(void) {
  return @[@"html"];
}

#pragma mark - Anti-spam Result Code Dictionary

NSDictionary<NSNumber *, NSString *> *antispamResultCodeDic(void) {
  return @{
    @100 : chatLocalizable(@"failed_message_reson_ornography"),
    @200 : chatLocalizable(@"failed_message_reson_advertising"),
    @260 : chatLocalizable(@"failed_message_reson_advertising_law"),
    @300 : chatLocalizable(@"failed_message_reson_violence_and_terrorism"),
    @400 : chatLocalizable(@"failed_message_reson_prohibited"),
    @500 : chatLocalizable(@"failed_message_reson_political_related"),
    @600 : chatLocalizable(@"failed_message_reson_abuse"),
    @700 : chatLocalizable(@"failed_message_reson_waterlogging"),
    @900 : chatLocalizable(@"failed_message_reson_others"),
    @1000 : chatLocalizable(@"failed_message_reson_value_related"),
  };
}

#pragma mark - More View Constants

NSString *const NEMoreCell_ReuseId = @"NEMoreCell";
CGFloat const NEMoreView_Section_Padding = 24.0;
CGFloat const NEMoreCell_Title_Height = 20.0;
CGFloat const NEMoreView_Margin = 16.0;
NSInteger const NEMoreView_Column_Count = 4;

CGSize NEMoreCell_Image_Size(void) {
  return CGSizeMake(56.0, 56.0);
}

#pragma mark - Color Utility

UIColor *HexRGBAlpha(NSInteger rgbValue, CGFloat alpha) {
  return [UIColor colorWithRed:((CGFloat)((rgbValue & 0xFF0000) >> 16)) / 255.0
                         green:((CGFloat)((rgbValue & 0xFF00) >> 8)) / 255.0
                          blue:((CGFloat)(rgbValue & 0xFF)) / 255.0
                         alpha:alpha];
}

UIColor *HexRGB(NSInteger rgbValue) {
  return HexRGBAlpha(rgbValue, 1.0);
}

#pragma mark - Internal Colors

UIColor *TextNormalColor(void) { return HexRGB(0x333333); }
UIColor *SubTextColor(void) { return HexRGB(0x666666); }
UIColor *PlaceholderTextColor(void) { return HexRGB(0xA6ADB6); }
UIColor *multiForwardLineColor(void) { return HexRGB(0xF0F1F5); }
UIColor *forwardLineColor(void) { return HexRGB(0xE1E6E8); }
UIColor *multiForwardborderColor(void) { return HexRGB(0xE4E9F2); }

#pragma mark - Notification Names

NSNotificationName const NENotificationCreateServer = @"qchat.createServer";
NSNotificationName const NENotificationCreateChannel = @"qchat.createChannel";
NSNotificationName const NENotificationUpdateChannel = @"qchat.updateChannel";
NSNotificationName const NENotificationDeleteChannel = @"qchat.deleteChannel";
NSNotificationName const NENotificationLeaveTeamBySelf = @"team.leaveTeamBySelf";
NSNotificationName const NENotificationLogout = @"qchat.logout";
NSNotificationName const NENotificationPopGroupChatVC = @"team.popGroupChatVC";
