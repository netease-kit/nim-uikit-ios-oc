// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MeViewController : UIViewController

@property (nonatomic, strong, nullable) UIColor *listSelectionBackgroundColor;

/// 右列回到空白占位或进入非行入口时宿主调用：清掉「上一次点过的行」，
/// 避免再次高亮过期选中项。
- (void)clearAdaptiveSelection;

@end

NS_ASSUME_NONNULL_END
