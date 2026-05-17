// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NSString+Chat.h"

@implementation NSString (Chat)

+ (NSInteger)calculateMaxLinesWithWidth:(CGFloat)width
                                 string:(NSString *)string
                                   font:(UIFont *)font {
  if (!string || string.length == 0) {
    return 0;
  }

  CGSize maxSize = CGSizeMake(width, CGFLOAT_MAX);
  CGFloat charSize = font.lineHeight;

  // Measure text size using UILabel (matches Swift String.getRealSize)
  UILabel *label = [[UILabel alloc] init];
  label.font = font;
  label.numberOfLines = 0;
  label.text = string;
  CGSize textSize = [label sizeThatFits:maxSize];

  NSInteger lines = (NSInteger)(textSize.height / charSize);
  return lines;
}

+ (NSInteger)calculateMaxLinesWithWidth:(CGFloat)width
                        attributeString:(NSAttributedString *)attributeString
                                   font:(UIFont *)font {
  if (!attributeString || attributeString.string.length == 0) {
    return 0;
  }

  CGSize maxSize = CGSizeMake(width, CGFLOAT_MAX);
  CGFloat charSize = font.lineHeight;

  // Measure attributed text size using UILabel (matches Swift NSAttributedString.getRealLabelSize)
  UILabel *label = [[UILabel alloc] init];
  label.font = font;
  label.numberOfLines = 0;
  label.attributedText = attributeString;
  CGSize textSize = [label sizeThatFits:maxSize];

  NSInteger lines = (NSInteger)(textSize.height / charSize);
  return lines;
}

@end
