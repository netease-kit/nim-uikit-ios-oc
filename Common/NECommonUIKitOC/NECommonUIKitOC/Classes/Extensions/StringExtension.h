// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (StringExtension)

+ (NSString *)stringFromTimeInterval:(NSTimeInterval)time;
+ (NSString *)stringFromDate:(NSDate *)date showHM:(BOOL)showHM;
+ (NSString *)date24To12:(nullable NSString *)string;
+ (nullable NSDate *)firstDayInYear;

@end

NS_ASSUME_NONNULL_END

