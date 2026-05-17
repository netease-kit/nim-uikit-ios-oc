// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEAISearchConstant.h"
#import "NEAISearchLoader.h"
#import <NEChatKitOC/NECommonLoader.h>
#import <NEChatKitOC/NEConstant.h>

NSString *const NEAISearchModuleName = @"NEAISearchKit";

static NECommonLoader *NEAISearchCoreLoader(void) {
  static NECommonLoader *loader = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    loader = [[NECommonLoader alloc] initWithClass:[NEAISearchLoader class]];
  });
  return loader;
}

NSString *NEAISearchLocalizable(NSString *key) {
  return [NEAISearchCoreLoader() localizable:key ?: @""];
}

UIFont *NEAISearchTextFont(void) {
  return [UIFont systemFontOfSize:14.0];
}

CGSize NEAISearchTextMaxSize(void) {
  return CGSizeMake(NEConstant.screenWidth - 40.0, CGFLOAT_MAX);
}

NSBundle *NEAISearchBundle(void) {
  return NEAISearchCoreLoader().bundle;
}

UIImage *NEAISearchImageNamed(NSString *name) {
  if (name.length <= 0) {
    return nil;
  }
  return [NEAISearchCoreLoader() loadImage:name];
}
