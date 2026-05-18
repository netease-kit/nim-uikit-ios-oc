// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NEMarkdownElement.h"
#import "NEMarkdownStyle.h"

NS_ASSUME_NONNULL_BEGIN

/// LevelElement 协议：支持多级别的 Markdown 元素（如 Header、List）
@protocol NEMarkdownLevelElement <NEMarkdownElement, NEMarkdownStyle>

@required
/// 最大级别
@property (nonatomic, assign) NSInteger maxLevel;

- (void)formatText:(NSMutableAttributedString *)attributedString range:(NSRange)range level:(NSInteger)level;
- (void)addAttributes:(NSMutableAttributedString *)attributedString range:(NSRange)range level:(NSInteger)level;
- (NSDictionary<NSAttributedStringKey, id> *)attributesForLevel:(NSInteger)level;

@end

NS_ASSUME_NONNULL_END
