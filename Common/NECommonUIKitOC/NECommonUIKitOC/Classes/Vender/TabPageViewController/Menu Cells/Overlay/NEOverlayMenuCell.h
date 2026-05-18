// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NETabPagingMenuView.h"

NS_ASSUME_NONNULL_BEGIN

@interface NEOverlayMenuCell : NEPagingMenuViewCell

@property (nonatomic, weak, nullable) NETabPagingMenuView *referencedMenuView;
@property (nonatomic, weak, nullable) PagingMenuFocusView *referencedFocusView;
@property (nonatomic, strong, nullable) UIColor *hightlightTextColor;
@property (nonatomic, strong, nullable) UIColor *normalTextColor;
@property (nonatomic, strong, nullable) UIFont *hightlightTextFont;
@property (nonatomic, strong, nullable) UIFont *normalTextFont;

+ (instancetype)sizingCell;
- (void)configureWithTitle:(NSString *)title;
- (void)updateMaskAnimated:(BOOL)animated;
- (CGFloat)calculateWidthFromHeight:(CGFloat)height title:(NSString *)title;

@end

NS_ASSUME_NONNULL_END
