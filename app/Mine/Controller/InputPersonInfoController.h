// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <NECommonUIKitOC/NEBaseViewController.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, NEEditType) {
  NEEditTypeNickName = 0,
  NEEditTypeCellphone,
  NEEditTypeEmail,
  NEEditTypeSpecialSign,
};

/// 对齐 Swift InputPersonInfoController — 单行文本编辑页
@interface InputPersonInfoController : NEBaseViewController

@property (nonatomic, copy, nullable)  NSString *contentText;
@property (nonatomic, copy, nullable)  void (^callBack)(NSString *editText);

- (void)configTitle:(NEEditType)editType;

@end

NS_ASSUME_NONNULL_END
