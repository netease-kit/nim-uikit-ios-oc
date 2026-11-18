// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NESingleLineTextField : UITextField
@end

/// 带内边距偏移的搜索输入框
@interface SearchTextField : UITextField

/// 自定义 leftView 的 x 偏移量，nil 时偏移 10pt
@property (nonatomic, strong, nullable) NSNumber *leftViewRectX;

@end

@interface NESingleLineSearchTextField : SearchTextField
@end

NS_ASSUME_NONNULL_END
