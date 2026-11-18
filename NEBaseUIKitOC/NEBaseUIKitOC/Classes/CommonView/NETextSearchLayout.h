// Copyright (c) 2026 NetEase, Inc. All rights reserved.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NETextSearchLayoutResult : NSObject
@property(nonatomic, copy, readonly) NSString *text;
@property(nonatomic, readonly) NSRange matchRange;
- (instancetype)initWithText:(NSString *)text matchRange:(NSRange)matchRange;
@end

@interface NETextSearchLayout : NSObject
+ (NETextSearchLayoutResult *)resultWithText:(NSString *)text
                                  matchRange:(NSRange)matchRange
                                       font:(UIFont *)font
                                   maxWidth:(CGFloat)maxWidth;
@end

NS_ASSUME_NONNULL_END
