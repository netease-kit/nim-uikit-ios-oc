// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "StringExtension.h"
#import "NECommonUIConstant.h"
#import <NEChatKitOC/NSDate+NECommon.h>

@implementation NSString (StringExtension)

+ (NSString *)stringFromTimeInterval:(NSTimeInterval)time {
  if (time <= 0) {
    return @"";
  }

  NSDate *targetDate = [NSDate dateWithTimeIntervalSince1970:time];
  NSDateFormatter *formatter = [[NSDateFormatter alloc] init];

  if (targetDate.ne_isToday) {
    formatter.dateFormat = commonLocalizable(@"hm");
    return [formatter stringFromDate:targetDate];
  }

  if (targetDate.ne_isThisYear) {
    formatter.dateFormat = commonLocalizable(@"mdhm");
    return [formatter stringFromDate:targetDate];
  }

  formatter.dateFormat = commonLocalizable(@"ymdhm");
  return [formatter stringFromDate:targetDate];
}

+ (NSString *)stringFromDate:(NSDate *)date showHM:(BOOL)showHM {
  NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
  if (showHM && [[NSCalendar currentCalendar] isDateInToday:date]) {
    formatter.dateFormat = commonLocalizable(@"hm");
  } else {
    NSDate *firstDay = [self firstDayInYear];
    if (firstDay && [date timeIntervalSinceDate:firstDay] > 0) {
      formatter.dateFormat = showHM ? commonLocalizable(@"mdhm") : commonLocalizable(@"md");
    } else {
      formatter.dateFormat = showHM ? commonLocalizable(@"ymdhm") : commonLocalizable(@"ymd");
    }
  }
  return [formatter stringFromDate:date];
}

+ (NSString *)date24To12:(NSString *)string {
  if (string.length == 0) {
    return @"";
  }

  NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
  NSArray<NSArray<NSString *> *> *formats = @[
    @[ commonLocalizable(@"hm"), commonLocalizable(@"ahm") ],
    @[ commonLocalizable(@"mdhm"), commonLocalizable(@"amdhm") ],
    @[ commonLocalizable(@"ymdhm"), commonLocalizable(@"aymdhm") ],
  ];

  for (NSArray<NSString *> *pair in formats) {
    formatter.dateFormat = pair.firstObject;
    NSDate *date = [formatter dateFromString:string];
    if (date) {
      formatter.dateFormat = pair.lastObject;
      return [formatter stringFromDate:date];
    }
  }
  return @"";
}

+ (NSDate *)firstDayInYear {
  NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
  formatter.dateFormat = @"yyyy-MM-dd";
  NSInteger year = [[NSCalendar currentCalendar] component:NSCalendarUnitYear fromDate:[NSDate date]];
  return [formatter dateFromString:[NSString stringWithFormat:@"%ld-01-01", (long)year]];
}

@end

