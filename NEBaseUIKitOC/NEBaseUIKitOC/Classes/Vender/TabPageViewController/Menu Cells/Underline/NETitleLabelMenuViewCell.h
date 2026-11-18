// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NETabPagingMenuView.h"

NS_ASSUME_NONNULL_BEGIN

@interface NETitleLabelMenuViewCell : NEPagingMenuViewCell

@property (nonatomic, strong) UIColor *focusColor;
@property (nonatomic, strong) UIColor *normalColor;
@property (nonatomic, assign, readonly) CGFloat labelWidth;
@property (nonatomic, strong, readonly) UILabel *titleLabel;
@property (nonatomic, assign) CGFloat spacing;

- (void)setImage:(nullable UIImage *)image;
- (CGFloat)calcIntermediateLabelSizeWithCurrentCell:(NETitleLabelMenuViewCell *)currentCell
                                            percent:(CGFloat)percent;

@end

NS_ASSUME_NONNULL_END
