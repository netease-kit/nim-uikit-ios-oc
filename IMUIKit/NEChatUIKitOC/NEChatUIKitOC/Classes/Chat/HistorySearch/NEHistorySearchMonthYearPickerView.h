// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NEHistorySearchMonthYearPickerView : UIView <UIPickerViewDataSource, UIPickerViewDelegate>

@property(nonatomic, strong) NSDate *currentDate;
@property(nonatomic, strong) NSDate *maxDate;
@property(nonatomic, copy, nullable) void (^onConfirm)(NSInteger year, NSInteger month);
@property(nonatomic, copy, nullable) void (^onCancel)(void);

@property(nonatomic, strong) NSArray<NSNumber *> *years;
@property(nonatomic, strong) NSArray<NSNumber *> *months;
@property(nonatomic, assign) NSInteger selectedYear;
@property(nonatomic, assign) NSInteger selectedMonth;
@property(nonatomic, strong) UIColor *themeColor;

@property(nonatomic, strong) UIButton *closeButton;
@property(nonatomic, strong) UILabel *titleLabel;
@property(nonatomic, strong) UIButton *confirmButton;
@property(nonatomic, strong) UIView *lineView;
@property(nonatomic, strong) UIPickerView *pickerView;

- (void)setupUI;
- (void)setupYears;
- (void)updateMonthsForSelectedYear;
- (void)setInitialSelection;

@end

NS_ASSUME_NONNULL_END
