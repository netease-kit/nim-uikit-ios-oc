// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NEBaseMultiSelectViewController.h"

NS_ASSUME_NONNULL_BEGIN

/// 转发 - 选择页面 - 通用版
@interface FunMultiSelectViewController : NEBaseMultiSelectViewController

- (void)setSearchTextFieldLeftView;
- (void)searchTextFieldBeginEdit;

@end

NS_ASSUME_NONNULL_END
