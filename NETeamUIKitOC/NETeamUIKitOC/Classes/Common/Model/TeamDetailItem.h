// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TeamDetailItem : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy, nullable) NSString *detailTitle;
@property (nonatomic, assign) BOOL value;
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, assign) Class cellClass;

- (instancetype)initWithTitle:(NSString *)title
                  detailTitle:(nullable NSString *)detailTitle
                        value:(BOOL)value
                    textColor:(UIColor *)textColor
                    cellClass:(Class)cellClass;

@end

NS_ASSUME_NONNULL_END
