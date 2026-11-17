// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NEMarkdownCommonElement.h"

NS_ASSUME_NONNULL_BEGIN

@interface NEMarkdownStrikethrough : NSObject <NEMarkdownCommonElement>

@property (nonatomic, strong, nullable) UIFont *font;
@property (nonatomic, strong, nullable) UIColor *color;
/// 删除线属性，默认包含 NSStrikethroughStyleAttributeName:single
@property (nonatomic, strong) NSDictionary<NSAttributedStringKey, id> *attributes;

- (instancetype)initWithFont:(nullable UIFont *)font color:(nullable UIColor *)color;

@end

NS_ASSUME_NONNULL_END
