// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "AppKey.h"

#if __has_include("AppKey.private.h")
#import "AppKey.private.h"
#else
NSString *const NEAppKey = @"";
NSString *const NEAPNSCername = @"";
NSString *const NEPKCerName = @"";
NSString *const NEAppAccount = @"";
NSString *const NEAppToken = @"";
#endif

NSString *const NENotificationLogout = @"logout";
NSString *const NENotificationChangeLanguage = @"app.changeLanguage";
NSString *const NENotificationChangeUI = @"change_ui";

NSString *NELocalizedString(NSString *key) {
  NSString *language = [NEAppLanguageUtil getCurrentLanguage] == NEAppLanguageChinese ? @"zh-Hans" : @"en";
  NSBundle *bundle = [NSBundle mainBundle];
  NSString *path = [bundle pathForResource:language ofType:@"lproj"];
  if (!path) {
    NSString *prefix = [[language componentsSeparatedByString:@"-"] firstObject];
    path = [bundle pathForResource:prefix ofType:@"lproj"];
  }
  if (path) {
    NSBundle *localizedBundle = [NSBundle bundleWithPath:path];
    if (localizedBundle) {
      return [localizedBundle localizedStringForKey:key value:key table:@"Localizable"];
    }
  }
  return [bundle localizedStringForKey:key value:key table:@"Localizable"];
}
