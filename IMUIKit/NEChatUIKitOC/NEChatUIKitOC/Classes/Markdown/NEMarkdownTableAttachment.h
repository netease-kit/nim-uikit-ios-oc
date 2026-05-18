// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NEMarkdownTableView.h"

NS_ASSUME_NONNULL_BEGIN

/// 将 NEMarkdownTableView 截图嵌入 NSAttributedString 的 NSTextAttachment
@interface NEMarkdownTableAttachment : NSTextAttachment

@property (nonatomic, strong, readonly) NEMarkdownTableView *tableView;
@property (nonatomic, assign, readonly) CGSize tableSize;

- (instancetype)initWithTableView:(NEMarkdownTableView *)tableView size:(CGSize)size;

/// 将表格 View 叠加到 textView 的指定位置（方案 B，支持横向滚动）
- (void)embedIntoTextView:(UITextView *)textView atCharacterIndex:(NSInteger)characterIndex;

@end

/// 包裹 NEMarkdownTableView 并支持横向滚动的容器（方案 B 使用）
@interface NEMarkdownTableScrollWrapper : UIScrollView

@property (nonatomic, weak, nullable) NEMarkdownTableAttachment *attachment;

- (instancetype)initWithAttachment:(NEMarkdownTableAttachment *)attachment
                         tableView:(NEMarkdownTableView *)tableView
                             frame:(CGRect)frame;

@end

NS_ASSUME_NONNULL_END
