// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "AppKey.h"

NSString *const NEAppKey = @"<#请输入云信 AppKey#>";
NSString *const NEAPNSCername = @"<#请输入云信 Apns 推送证书名#>";
NSString *const NEPKCerName = @"<#请输入云信 PushKit 推送证书名#>";
NSString *const NEAppAccount = @"<#account#>";
NSString *const NEAppToken = @"<#token#>";

NSString *const NENotificationLogout = @"logout";
NSString *const NENotificationChangeLanguage = @"app.changeLanguage";
NSString *const NENotificationChangeUI = @"change_ui";

NSString *NELocalizedString(NSString *key) {
  NSString *language = NEAppLanguageRawValue([NEAppLanguageUtil getCurrentLanguage]);
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
