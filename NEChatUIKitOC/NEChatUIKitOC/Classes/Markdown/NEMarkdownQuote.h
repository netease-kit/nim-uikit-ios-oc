// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NEMarkdownLevelElement.h"

NS_ASSUME_NONNULL_BEGIN

@interface NEMarkdownQuote : NSObject <NEMarkdownLevelElement>

@property (nonatomic, assign) NSInteger maxLevel;
@property (nonatomic, strong, nullable) UIFont *font;
@property (nonatomic, strong, nullable) UIColor *color;
@property (nonatomic, copy) NSString *separator;
@property (nonatomic, copy) NSString *indicator;

- (instancetype)initWithFont:(nullable UIFont *)font;
- (instancetype)initWithFont:(nullable UIFont *)font
                    maxLevel:(NSInteger)maxLevel
                   indicator:(NSString *)indicator
                   separator:(NSString *)separator
                       color:(nullable UIColor *)color;

@end

NS_ASSUME_NONNULL_END
