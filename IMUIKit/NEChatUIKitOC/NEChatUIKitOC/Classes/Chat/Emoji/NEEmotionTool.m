// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEEmotionTool.h"
#import "NIMInputEmoticonManager.h"

@implementation NEEmotionTool

+ (nullable NSArray<NSTextCheckingResult *> *)getRegularArray:(NSString *)str {
  NSString *pattern = @"\\[[^\\[|^\\]]+\\]";
  NSError *error = nil;
  NSRegularExpression *reExpression = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                                options:NSRegularExpressionCaseInsensitive
                                                                                  error:&error];
  NSArray<NSTextCheckingResult *> *regularArr =
      [reExpression matchesInString:str
                            options:NSMatchingReportProgress
                              range:NSMakeRange(0, str.length)];
  return regularArr;
}

+ (NSMutableAttributedString *)getAttWithStr:(NSString *)str
                                        font:(UIFont *)font
                                       color:(UIColor *)color
                                      offset:(CGPoint)offset {
  NSArray<NSTextCheckingResult *> *regularArr = [self getRegularArray:str];
  NSArray<NIMInputEmoticon *> *emoticons =
      [[NIMInputEmoticonManager shared] emoticonCatalogWithID:NIMKit_EmojiCatalog].emoticons;

  NSMutableAttributedString *attStr = [[NSMutableAttributedString alloc]
      initWithString:str
          attributes:@{
            NSFontAttributeName : font,
            NSForegroundColorAttributeName : color,
          }];

  if (regularArr.count > 0 && emoticons.count > 0) {
    // 从后向前替换，避免范围偏移
    for (NSInteger i = regularArr.count - 1; i >= 0; i--) {
      NSTextCheckingResult *result = regularArr[i];
      NSString *ocStr = str;
      NSString *matchedStr = [ocStr substringWithRange:result.range];

      for (NIMInputEmoticon *obj in emoticons) {
        if ([matchedStr isEqualToString:obj.tag]) {
          NSAttributedString *emotionAtt = [self getAttWithEmotion:obj font:font offset:offset];
          [attStr replaceCharactersInRange:result.range withAttributedString:emotionAtt];
          break;
        }
      }
    }
  }
  return attStr;
}

+ (NSAttributedString *)getAttWithEmotion:(NIMInputEmoticon *)emotion
                                     font:(UIFont *)font
                                   offset:(CGPoint)offset {
  NEEmotionAttachment *textAttachment = [[NEEmotionAttachment alloc] init];
  textAttachment.emotion = emotion;
  CGFloat height = font.lineHeight;
  textAttachment.bounds = CGRectMake(offset.x, offset.y, height, height);
  return [NSAttributedString attributedStringWithAttachment:textAttachment];
}

+ (nullable NSString *)getTextWithAtt:(nullable NSMutableAttributedString *)att
                                range:(NSRange)range {
  if (!att || att.length == 0 || range.length == 0 || range.location >= att.length) {
    return nil;
  }

  range = NSMakeRange(range.location, MIN(range.length, att.length - range.location));
  NSMutableString *text = [NSMutableString string];
  [att enumerateAttributesInRange:range
                          options:0
                       usingBlock:^(NSDictionary<NSAttributedStringKey, id> *attrs,
                                    NSRange attrRange,
                                    BOOL *stop) {
    NEEmotionAttachment *attachment = attrs[NSAttachmentAttributeName];
    if ([attachment isKindOfClass:[NEEmotionAttachment class]]) {
      [text appendString:attachment.emotion.tag ?: @""];
    } else {
      NSString *subStr = [att.string substringWithRange:attrRange];
      [text appendString:subStr];
    }
  }];

  return text.length > 0 ? [text copy] : nil;
}

@end
