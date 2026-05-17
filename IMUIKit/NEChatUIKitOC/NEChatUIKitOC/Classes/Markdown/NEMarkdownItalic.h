// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NEMarkdownCommonElement.h"

NS_ASSUME_NONNULL_BEGIN

@interface NEMarkdownItalic : NSObject <NEMarkdownCommonElement>

@property (nonatomic, strong, nullable) UIFont *font;
@property (nonatomic, strong, nullable) UIColor *color;

- (instancetype)initWithFont:(nullable UIFont *)font color:(nullable UIColor *)color;

@end

NS_ASSUME_NONNULL_END
