// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.
//
// RedAngleLabel.h — 对齐 Swift RedAngleLabel（支持 textInsets 内边距）

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 未读角标 Label，支持 textInsets 内边距，自动撑开宽度
@interface RedAngleLabel : UILabel

/// 文字内边距（默认 top:3 left:7 bottom:3 right:7）
@property (nonatomic, assign) UIEdgeInsets textInsets;

@end

NS_ASSUME_NONNULL_END
