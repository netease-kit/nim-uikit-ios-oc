// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NEMarkdownElement.h"

NS_ASSUME_NONNULL_BEGIN

/// 图片下载完成通知名称，userInfo 包含 "url"(NSString) 和 "image"(UIImage)
FOUNDATION_EXPORT NSNotificationName const NEMarkdownImageDidLoadNotification;

/// 图片 Attachment：管理占位图 → 真实图片的切换
@interface NEMarkdownImageAttachment : NSTextAttachment

@property (nonatomic, copy, readonly) NSString *imageURL;
@property (nonatomic, assign, readonly) CGFloat maxWidth;
@property (nonatomic, assign, readonly) CGFloat maxHeight;
@property (nonatomic, assign, readonly) CGSize placeholderSize;
@property (nonatomic, assign, readonly) BOOL isLoaded;

- (instancetype)initWithImageURL:(NSString *)imageURL
                        maxWidth:(CGFloat)maxWidth
                       maxHeight:(CGFloat)maxHeight
                 placeholderSize:(CGSize)placeholderSize;

/// 开始异步下载图片
- (void)startDownload;

/// 约束图片尺寸，保持宽高比
+ (CGSize)constrainSize:(CGSize)imageSize maxWidth:(CGFloat)maxWidth maxHeight:(CGFloat)maxHeight;

@end

/// Markdown 图片解析 Element（支持 ![alt](url) 语法）
@interface NEMarkdownImage : NSObject <NEMarkdownElement>

@property (nonatomic, assign) CGFloat maxWidth;
@property (nonatomic, assign) CGFloat maxHeight;
@property (nonatomic, assign) CGSize placeholderSize;

- (instancetype)init;

@end

NS_ASSUME_NONNULL_END
