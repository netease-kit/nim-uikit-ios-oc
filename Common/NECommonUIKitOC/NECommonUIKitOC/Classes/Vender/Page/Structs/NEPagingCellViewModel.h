// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class NEPagingOptions;

@interface NEPagingTitleCellViewModel : NSObject

@property (nonatomic, copy, readonly, nullable) NSString *title;
@property (nonatomic, strong, readonly) UIFont *font;
@property (nonatomic, strong, readonly) UIFont *selectedFont;
@property (nonatomic, strong, readonly) UIColor *textColor;
@property (nonatomic, strong, readonly) UIColor *selectedTextColor;
@property (nonatomic, strong, readonly) UIColor *backgroundColor;
@property (nonatomic, strong, readonly) UIColor *selectedBackgroundColor;
@property (nonatomic, assign, readonly, getter=isSelected) BOOL selected;
@property (nonatomic, assign, readonly) CGFloat labelSpacing;

- (instancetype)initWithTitle:(nullable NSString *)title
                     selected:(BOOL)selected
                      options:(NEPagingOptions *)options;

@end

NS_ASSUME_NONNULL_END
