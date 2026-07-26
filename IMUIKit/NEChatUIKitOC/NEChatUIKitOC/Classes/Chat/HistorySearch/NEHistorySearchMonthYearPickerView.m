// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEHistorySearchMonthYearPickerView.h"
#import <NECommonUIKitOC/NECommonUIKitOC.h>
#import "NEChatUIConstant.h"
#import <NEChatKit/UIColor+NECommon.h>
#import "NormalChatUIColor.h"

@implementation NEHistorySearchMonthYearPickerView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _currentDate = [NSDate date];
        _maxDate = [NSDate date];
        _selectedYear = 2025;
        _selectedMonth = 1;
        _themeColor = UIColor.ne_normalTheme;
        _years = @[];
        _months = @[];
        [self setupUI];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        _currentDate = [NSDate date];
        _maxDate = [NSDate date];
        _selectedYear = 2025;
        _selectedMonth = 1;
        _themeColor = UIColor.ne_normalTheme;
        _years = @[];
        _months = @[];
    }
    return self;
}

- (void)setThemeColor:(UIColor *)themeColor {
    _themeColor = themeColor;
    [self.confirmButton setTitleColor:themeColor forState:UIControlStateNormal];
}

- (UIButton *)closeButton {
    if (!_closeButton) {
        _closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
        UIImage *xmarkImage = [UIImage systemImageNamed:@"xmark"];
        [_closeButton setImage:xmarkImage forState:UIControlStateNormal];
        _closeButton.tintColor = UIColor.blackColor;
        [_closeButton addTarget:self action:@selector(closeTapped) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeButton;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text = chatLocalizable(@"choose_date_year_month");
        _titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLabel;
}

- (UIButton *)confirmButton {
    if (!_confirmButton) {
        _confirmButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_confirmButton setTitle:commonLocalizable(@"complete") forState:UIControlStateNormal];
        [_confirmButton setTitleColor:self.themeColor forState:UIControlStateNormal];
        _confirmButton.titleLabel.font = [UIFont systemFontOfSize:16];
        [_confirmButton addTarget:self action:@selector(confirmTapped) forControlEvents:UIControlEventTouchUpInside];
    }
    return _confirmButton;
}

- (UIView *)lineView {
    if (!_lineView) {
        _lineView = [[UIView alloc] init];
        _lineView.backgroundColor = UIColor.normalChatNavigationDivideBg;
    }
    return _lineView;
}

- (UIPickerView *)pickerView {
    if (!_pickerView) {
        _pickerView = [[UIPickerView alloc] init];
        _pickerView.delegate = self;
        _pickerView.dataSource = self;
    }
    return _pickerView;
}

- (void)setupUI {
    self.backgroundColor = UIColor.whiteColor;
    self.layer.cornerRadius = 16;
    self.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;

    for (UIView *item in @[self.closeButton, self.titleLabel, self.confirmButton, self.lineView, self.pickerView]) {
        item.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:item];
    }

    [NSLayoutConstraint activateConstraints:@[
        [self.closeButton.topAnchor constraintEqualToAnchor:self.topAnchor constant:16],
        [self.closeButton.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:16],
        [self.closeButton.widthAnchor constraintEqualToConstant:26],
        [self.closeButton.heightAnchor constraintEqualToConstant:26],

        [self.titleLabel.centerYAnchor constraintEqualToAnchor:self.closeButton.centerYAnchor],
        [self.titleLabel.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],

        [self.confirmButton.centerYAnchor constraintEqualToAnchor:self.closeButton.centerYAnchor],
        [self.confirmButton.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-16],

        [self.lineView.topAnchor constraintEqualToAnchor:self.closeButton.bottomAnchor constant:20],
        [self.lineView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:0],
        [self.lineView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:0],
        [self.lineView.heightAnchor constraintEqualToConstant:0.5],

        [self.pickerView.topAnchor constraintEqualToAnchor:self.lineView.bottomAnchor constant:10],
        [self.pickerView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.pickerView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [self.pickerView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-34],
    ]];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self setupYears];
    [self updateMonthsForSelectedYear];
    [self setInitialSelection];
}

- (void)setupYears {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSInteger maxYear = [calendar component:NSCalendarUnitYear fromDate:self.maxDate];
    NSMutableArray *yearsArray = [NSMutableArray array];
    for (NSInteger y = 1970; y <= maxYear; y++) {
        [yearsArray addObject:@(y)];
    }
    self.years = [yearsArray copy];
}

- (void)updateMonthsForSelectedYear {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSInteger maxYear = [calendar component:NSCalendarUnitYear fromDate:self.maxDate];
    NSInteger maxMonth = [calendar component:NSCalendarUnitMonth fromDate:self.maxDate];

    NSMutableArray *monthsArray = [NSMutableArray array];
    NSInteger endMonth = (self.selectedYear == maxYear) ? maxMonth : 12;
    for (NSInteger m = 1; m <= endMonth; m++) {
        [monthsArray addObject:@(m)];
    }
    self.months = [monthsArray copy];
}

- (void)setInitialSelection {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    self.selectedYear = [calendar component:NSCalendarUnitYear fromDate:self.currentDate];
    self.selectedMonth = [calendar component:NSCalendarUnitMonth fromDate:self.currentDate];

    NSUInteger yearIndex = [self.years indexOfObject:@(self.selectedYear)];
    if (yearIndex != NSNotFound) {
        [self.pickerView selectRow:(NSInteger)yearIndex inComponent:0 animated:NO];
    }

    [self updateMonthsForSelectedYear];
    [self.pickerView reloadComponent:1];

    NSUInteger monthIndex = [self.months indexOfObject:@(self.selectedMonth)];
    if (monthIndex != NSNotFound) {
        [self.pickerView selectRow:(NSInteger)monthIndex inComponent:1 animated:NO];
    }
}

- (void)closeTapped {
    if (self.onCancel) {
        self.onCancel();
    }
}

- (void)confirmTapped {
    if (self.onConfirm) {
        self.onConfirm(self.selectedYear, self.selectedMonth);
    }
}

#pragma mark - UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 2;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return component == 0 ? (NSInteger)self.years.count : (NSInteger)self.months.count;
}

#pragma mark - UIPickerViewDelegate

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(nullable UIView *)view {
    UILabel *label = [view isKindOfClass:[UILabel class]] ? (UILabel *)view : [[UILabel alloc] init];
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont systemFontOfSize:20 weight:UIFontWeightMedium];

    if (component == 0) {
        label.text = [NSString stringWithFormat:@"%ld", (long)self.years[row].integerValue];
    } else {
        label.text = [NSString stringWithFormat:@"%02ld", (long)self.months[row].integerValue];
    }
    return label;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (component == 0) {
        self.selectedYear = self.years[row].integerValue;
        [self updateMonthsForSelectedYear];
        [pickerView reloadComponent:1];

        if (![self.months containsObject:@(self.selectedMonth)]) {
            self.selectedMonth = self.months.lastObject.integerValue;
            NSUInteger monthIndex = [self.months indexOfObject:@(self.selectedMonth)];
            if (monthIndex != NSNotFound) {
                [pickerView selectRow:(NSInteger)monthIndex inComponent:1 animated:YES];
            }
        }
    } else {
        self.selectedMonth = self.months[row].integerValue;
    }
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
    return 44.0;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
    return self.bounds.size.width / 2.0 - 40;
}

@end
