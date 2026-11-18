// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (NEViewExtension)

@property (nonatomic, assign) CGFloat left;
@property (nonatomic, assign) CGFloat top;
@property (nonatomic, assign) CGFloat width;
@property (nonatomic, assign) CGFloat height;
@property (nonatomic, assign, readonly) CGFloat right;
@property (nonatomic, assign, readonly) CGFloat bottom;
@property (nonatomic, assign) CGFloat centerX;
@property (nonatomic, assign) CGFloat centerY;

- (void)addCorner:(UIRectCorner)corners radius:(CGFloat)radius;
- (nullable NSLayoutConstraint *)getLayoutConstraintWithFirstItem:(UIView *)firstItem
                                                       secondItem:(nullable UIView *)secondItem
                                                        attribute:(NSLayoutAttribute)attribute;
- (void)updateLayoutConstraintWithFirstItem:(UIView *)firstItem
                                 secondItem:(nullable UIView *)secondItem
                                  attribute:(NSLayoutAttribute)attribute
                                   constant:(CGFloat)constant;
- (void)removeLayoutConstraintWithFirstItem:(UIView *)firstItem
                                 secondItem:(nullable UIView *)secondItem
                                  attribute:(NSLayoutAttribute)attribute;
- (nullable UILabel *)findLabelWithString:(nullable NSString *)string;

@end

NS_ASSUME_NONNULL_END

