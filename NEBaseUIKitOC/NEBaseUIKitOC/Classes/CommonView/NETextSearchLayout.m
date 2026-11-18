// Copyright (c) 2026 NetEase, Inc. All rights reserved.

#import "NETextSearchLayout.h"
#include <stdlib.h>

@implementation NETextSearchLayoutResult

- (instancetype)initWithText:(NSString *)text matchRange:(NSRange)matchRange {
  self = [super init];
  if (self) {
    _text = [text copy];
    _matchRange = matchRange;
  }
  return self;
}

@end

@implementation NETextSearchLayout

+ (NETextSearchLayoutResult *)resultWithText:(NSString *)text
                                  matchRange:(NSRange)matchRange
                                       font:(UIFont *)font
                                   maxWidth:(CGFloat)maxWidth {
  if (maxWidth <= 0 || matchRange.location == NSNotFound ||
      matchRange.location < 0 || NSMaxRange(matchRange) > text.length) {
    return [[NETextSearchLayoutResult alloc] initWithText:text matchRange:matchRange];
  }

  NSDictionary *attributes = @{NSFontAttributeName : font};
  CGFloat (^measure)(NSString *) = ^CGFloat(NSString *value) {
    return [value sizeWithAttributes:attributes].width;
  };
  if (measure(text) <= maxWidth) {
    return [[NETextSearchLayoutResult alloc] initWithText:text matchRange:matchRange];
  }

  NSMutableArray<NSString *> *components = [NSMutableArray array];
  NSMutableArray<NSValue *> *ranges = [NSMutableArray array];
  [text enumerateSubstringsInRange:NSMakeRange(0, text.length)
                           options:NSStringEnumerationByComposedCharacterSequences
                        usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
    [components addObject:substring ?: @""];
    [ranges addObject:[NSValue valueWithRange:substringRange]];
  }];

  NSUInteger matchStart = NSNotFound;
  NSUInteger matchEnd = NSNotFound;
  for (NSUInteger index = 0; index < ranges.count; index++) {
    NSRange componentRange = ranges[index].rangeValue;
    if (componentRange.location == matchRange.location) {
      matchStart = index;
    }
    if (NSMaxRange(componentRange) == NSMaxRange(matchRange)) {
      matchEnd = index + 1;
      break;
    }
  }
  if (matchStart == NSNotFound || matchEnd == NSNotFound) {
    return [[NETextSearchLayoutResult alloc] initWithText:text matchRange:matchRange];
  }

  NSString *(^join)(NSUInteger, NSUInteger) = ^NSString *(NSUInteger start, NSUInteger end) {
    return [[components subarrayWithRange:NSMakeRange(start, end - start)] componentsJoinedByString:@""];
  };

  NSString *bestText = nil;
  NSRange bestRange = NSMakeRange(NSNotFound, 0);
  NSInteger bestRetained = -1;
  NSInteger bestMarks = -1;
  NSInteger bestBalance = NSIntegerMin;
  for (NSUInteger start = 0; start <= matchStart; start++) {
    for (NSUInteger end = matchEnd; end <= components.count; end++) {
      NSString *content = join(start, end);
      BOOL omittedPrefix = start > 0;
      BOOL omittedSuffix = end < components.count;
      // An omitted side must be represented by an ellipsis. This prevents
      // silently dropping unmatched text when a measured window is used.
      NSArray<NSNumber *> *prefixOptions = omittedPrefix ? @[@YES] : @[@NO];
      NSArray<NSNumber *> *suffixOptions = omittedSuffix ? @[@YES] : @[@NO];
      for (NSNumber *prefixValue in prefixOptions) {
        for (NSNumber *suffixValue in suffixOptions) {
          BOOL prefixMark = prefixValue.boolValue;
          BOOL suffixMark = suffixValue.boolValue;
          NSString *candidate = [NSString stringWithFormat:@"%@%@%@",
                                                           prefixMark ? @"…" : @"",
                                                           content,
                                                           suffixMark ? @"…" : @""];
          if (measure(candidate) > maxWidth + 0.5) {
            continue;
          }
          NSInteger retained = content.length;
          NSInteger marks = (prefixMark ? 1 : 0) + (suffixMark ? 1 : 0);
          NSInteger balance = -llabs((NSInteger)(matchStart - start) - (NSInteger)(end - matchEnd));
          if (bestText != nil) {
            BOOL better = NO;
            if (marks != bestMarks) {
              better = marks < bestMarks;
            } else if (retained != bestRetained) {
              better = retained > bestRetained;
            } else {
              better = balance > bestBalance;
            }
            if (!better) {
              continue;
            }
          }
          bestText = candidate;
          bestMarks = marks;
          bestRetained = retained;
          bestBalance = balance;
          NSUInteger prefixLength = prefixMark ? 1 : 0;
          NSString *beforeMatch = join(start, matchStart);
          bestRange = NSMakeRange(prefixLength + beforeMatch.length, matchRange.length);
        }
      }
    }
  }

  if (bestText != nil) {
    return [[NETextSearchLayoutResult alloc] initWithText:bestText matchRange:bestRange];
  }
  NSString *matchText = [text substringWithRange:matchRange];
  return [[NETextSearchLayoutResult alloc] initWithText:matchText
                                             matchRange:NSMakeRange(0, matchRange.length)];
}

@end
