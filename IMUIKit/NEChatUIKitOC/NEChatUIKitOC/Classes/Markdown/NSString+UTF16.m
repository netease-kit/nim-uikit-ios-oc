// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NSString+UTF16.h"

@implementation NSString (UTF16)

- (NSString *)ne_escapeUTF16 {
    NSMutableString *result = [NSMutableString string];
    NSUInteger length = [self length];
    for (NSUInteger i = 0; i < length; i++) {
        unichar c = [self characterAtIndex:i];
        [result appendFormat:@"%04x", (unsigned int)c];
    }
    return [result copy];
}

- (nullable NSString *)ne_unescapeUTF16 {
    NSUInteger len = [self length];
    // 热修复：长度不是 4 的倍数，直接返回 self
    if (len % 4 != 0) {
        return self;
    }

    NSMutableArray<NSNumber *> *utf16Array = [NSMutableArray array];
    for (NSUInteger i = 0; i < len; i += 4) {
        NSString *hex4 = [self substringWithRange:NSMakeRange(i, 4)];
        unsigned int value = 0;
        NSScanner *scanner = [NSScanner scannerWithString:hex4];
        if ([scanner scanHexInt:&value]) {
            [utf16Array addObject:@((uint16_t)value)];
        }
    }

    NSMutableData *data = [NSMutableData dataWithCapacity:utf16Array.count * 2];
    for (NSNumber *num in utf16Array) {
        uint16_t val = (uint16_t)[num unsignedShortValue];
        [data appendBytes:&val length:2];
    }

    NSString *decoded = [[NSString alloc] initWithData:data encoding:NSUTF16LittleEndianStringEncoding];
    return decoded;
}

@end
