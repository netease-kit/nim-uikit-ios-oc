// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

#import <UIKit/UIKit.h>
#import "NEBaseContactViewCell.h"
#import "MultiSelectModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface NEBaseSelectCell : NEBaseContactViewCell

@property (nonatomic, assign) CGFloat titleLabelMaxWidth;
@property (nonatomic, assign) CGFloat memberLabelMaxWidth;
@property (nonatomic, strong, nullable) NSLayoutConstraint *titleLabelWidthAnchor;
@property (nonatomic, strong, nullable) NSLayoutConstraint *memberLabelWidthAnchor;
@property (nonatomic, strong) UIColor *searchTextColor;
@property (nonatomic, strong) UIImageView *multiSelectImageView;
@property (nonatomic, copy, nullable) NSString *searchText;

- (void)commonUI;
- (void)setConfig;
- (void)showSelect:(BOOL)isShow;
- (void)setModel:(MultiSelectModel *)model;

/// 按 cell 的实际宽度重算名称上限。
/// 子类可覆写以保留自己的预留量（如“已选”列表）。
- (void)recalculateTitleLabelMaxWidth;

@end

NS_ASSUME_NONNULL_END
