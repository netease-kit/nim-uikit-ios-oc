// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import <UIKit/UIKit.h>
#import <NEChatKit/NEChatKit.h>
#import <NIMSDK/NIMSDK.h>
#import "NEChatBaseViewController.h"
#import "NEHistorySearchMonthYearPickerView.h"
#import "NEHistorySearchDateCell.h"
#import "NEHistorySearchMonthHeaderView.h"

NS_ASSUME_NONNULL_BEGIN

@protocol NEHistoryDatePickerViewControllerDelegate <NSObject>

- (void)datePickerDidSelectDate:(int64_t)timestamp;

@end

typedef NS_ENUM(NSInteger, NEHistoryQuickSelectType) {
    NEHistoryQuickSelectTypeNone = 0,
    NEHistoryQuickSelectTypeToday,
    NEHistoryQuickSelectTypeLast7Days,
    NEHistoryQuickSelectTypeLast30Days,
};

@interface NEHistoryDatePickerViewController : NEChatBaseViewController <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property(nonatomic, weak, nullable) id<NEHistoryDatePickerViewControllerDelegate> delegate;
@property(nonatomic, strong) UIColor *selectButtonBackgroundColor;

@property(nonatomic, strong, nullable) NSDate *selectedDate;
@property(nonatomic, strong) NSDate *currentDisplayMonth;
@property(nonatomic, strong) NSMutableArray<NSDate *> *months;
@property(nonatomic, assign) NEHistoryQuickSelectType quickSelectType;

@property(nonatomic, strong) UIButton *todayButton;
@property(nonatomic, strong) UIButton *last7DaysButton;
@property(nonatomic, strong) UIButton *last30DaysButton;
@property(nonatomic, strong) UIButton *monthSelectorButton;
@property(nonatomic, strong) UIStackView *quickButtonStack;
@property(nonatomic, strong) UIStackView *weekdayHeader;
@property(nonatomic, strong) UICollectionView *collectionView;

@property(nonatomic, strong) NEHistorySearchMonthYearPickerView *pickerView;
@property(nonatomic, strong, nullable) NEHistorySearchMonthYearPickerView *monthPickerView;
@property(nonatomic, strong, nullable) UIView *dimView;

- (void)setupUI;
- (void)generateMonths;
- (void)updateMonthSelectorTitle;
- (void)updateQuickButtonState:(NEHistoryQuickSelectType)type;
- (void)scrollToToday:(BOOL)animated;
- (void)scrollToDate:(NSDate *)date animated:(BOOL)animated;
- (void)scrollToMonth:(NSDate *)date animated:(BOOL)animated;
- (void)showMonthPicker;
- (NSInteger)getFirstWeekdayOfMonth:(NSDate *)date;
- (NSInteger)getDaysInMonth:(NSDate *)date;

- (UIButton *)createQuickButtonWithTitle:(NSString *)title tag:(NSInteger)tag;

@end

NS_ASSUME_NONNULL_END
