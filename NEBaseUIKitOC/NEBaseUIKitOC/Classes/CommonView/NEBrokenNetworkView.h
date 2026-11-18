// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NEBrokenNetworkView : UIView

/// 错误提示图片
@property (nonatomic, strong) UIImageView *errorIconView;
/// 网络错误标签
@property (nonatomic, strong) UILabel *contentLabel;

@end

NS_ASSUME_NONNULL_END
