// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SearchSessionBaseView : UITableViewHeaderFooterView

@property (nonatomic, strong, readonly) UILabel *titleLabel;
@property (nonatomic, strong, readonly) UIView *bottomLine;

- (void)setupUI;
- (void)setUpTitle:(NSString *)title;

@end

@interface FunSearchSessionHeaderView : SearchSessionBaseView

@end

@interface FunSearchView : UIView

@property (nonatomic, strong, readonly) UIView *backView;
@property (nonatomic, strong, readonly) UIButton *searchButton;
@property (nonatomic, assign) CGFloat searchButtonLeftConstant;
@property (nonatomic, assign) CGFloat searchButtonRightConstant;

- (instancetype)initWithSearchButtonLeftConstant:(CGFloat)searchButtonLeftConstant
                       searchButtonRightConstant:(CGFloat)searchButtonRightConstant;
- (void)updateSearchButtonConstantWithSearchButtonLeftConstant:(nullable NSNumber *)searchButtonLeftConstant
                                     searchButtonRightConstant:(nullable NSNumber *)searchButtonRightConstant;

@end

NS_ASSUME_NONNULL_END
