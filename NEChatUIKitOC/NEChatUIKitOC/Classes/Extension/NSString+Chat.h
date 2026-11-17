// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (Chat)

/// Calculate the number of text lines for a plain string within the given width.
/// Uses font.lineHeight as the line-height metric.
/// @param width  The constrained width
/// @param string  The string to measure (nullable — returns 0)
/// @param font  The font used for measurement
+ (NSInteger)calculateMaxLinesWithWidth:(CGFloat)width
                                 string:(NSString * _Nullable)string
                                   font:(UIFont *)font;

/// Calculate the number of text lines for an attributed string within the given width.
/// Uses font.lineHeight as the line-height metric.
/// @param width  The constrained width
/// @param attributeString  The attributed string to measure (nullable — returns 0)
/// @param font  The font used for measurement
+ (NSInteger)calculateMaxLinesWithWidth:(CGFloat)width
                        attributeString:(NSAttributedString * _Nullable)attributeString
                                   font:(UIFont *)font;

@end

NS_ASSUME_NONNULL_END
