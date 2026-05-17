// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// AI助聊数据模型
@interface AIChatCellModel : NSObject

@property (nonatomic, copy, nullable) NSString *tagTitle;
@property (nonatomic, strong, nullable) UIColor *tagTitleColor;
@property (nonatomic, strong, nullable) UIColor *tagTitleBackgroundColor;
@property (nonatomic, copy, nullable) NSString *contentTitle;

- (instancetype)initWithTagTitle:(nullable NSString *)tagTitle
                   tagTitleColor:(nullable UIColor *)tagTitleColor
         tagTitleBackgroundColor:(nullable UIColor *)tagTitleBackgroundColor
                    contentTitle:(nullable NSString *)contentTitle;

@end

NS_ASSUME_NONNULL_END
