// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "ContactConst.h"

#import <NEChatKit/NECoreIM2Constant.h>
#import <NEChatKit/NECommonLoader.h>
#import <NEChatKit/NEChatKit.h>

/// 资源加载器（定位 bundle 用）
static NECommonLoader *_contactCoreLoader = nil;

static NECommonLoader *contactCoreLoader(void) {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _contactCoreLoader = [[NECommonLoader alloc] initWithClass:NSClassFromString(@"NEContactBaseViewController") ?: [NSObject class]];
  });
  return _contactCoreLoader;
}

NSString *const ModuleName = @"NEContactUIKit";

NSNotificationName const NENotificationNameChangeLanguage = @"app.changeLanguage";

NSString *contactLocalizable(NSString *key) {
  return [contactCoreLoader() localizable:key];
}

UIImage *_Nullable ne_contactImageNamed(NSString *_Nullable name) {
  if (!name || name.length == 0) {
    return nil;
  }
  return [contactCoreLoader() loadImage:name];
}

NSString *robotErrorMessage(NSError *error) {
  NSInteger code = error.code;
  if (code == robotFunctionNotEnabled) {
    return contactLocalizable(@"robot_error_403");
  } else if (code == failedOperation) {
    return contactLocalizable(@"robot_error_414");
  } else if (code == inValidTokenCode) {
    return contactLocalizable(@"robot_error_102302");
  } else if (code == userNotExistCode) {
    return contactLocalizable(@"robot_error_102404");
  } else if (code == robotNotAIAccount) {
    return contactLocalizable(@"robot_error_102308");
  } else if (code == robotBindCodeNotExist) {
    return contactLocalizable(@"robot_error_102309");
  } else if (code == robotNotBelongToUser) {
    return contactLocalizable(@"robot_error_102310");
  } else if (code == robotQRCodeAlreadyBound) {
    return contactLocalizable(@"robot_error_102311");
  } else {
    return error.localizedDescription;
  }
}
