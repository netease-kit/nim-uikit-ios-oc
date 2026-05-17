// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEHistoryDatePickerViewController.h"
#import "UIImage+Chat.h"
#import <NEChatKitOC/UIColor+NECommon.h>
#import <NEChatKitOC/NEChatKitOC.h>
#import <NECommonUIKitOC/NECommonUIKitOC.h>
#import <NIMSDK/NIMSDK.h>
#import "NEChatUIConstant.h"
#import "NormalChatUIColor.h"
#import "ChatNavigationView.h"

@implementation NEHistoryDatePickerViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        _selectButtonBackgroundColor = UIColor.normalSearchDateButtonBg;
        _currentDisplayMonth = [NSDate date];
        _months = [NSMutableArray array];
        _quickSelectType = NEHistoryQuickSelectTypeNone;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self generateMonths];

    // 首次进入默认选中今天
    NSCalendar *calendar = [NSCalendar currentCalendar];
    self.selectedDate = [calendar startOfDayForDate:[NSDate date]];
    [self updateQuickButtonState:NEHistoryQuickSelectTypeToday];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self scrollToToday:NO];
    });
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
    if ([layout isKindOfClass:[UICollectionViewFlowLayout class]]) {
        CGFloat width = CGRectGetWidth(self.collectionView.bounds) / 7.0;
        layout.itemSize = CGSizeMake(width, 70);
        layout.headerReferenceSize = CGSizeMake(CGRectGetWidth(self.collectionView.bounds), 50);
    }
}

#pragma mark - Lazy

- (UIButton *)todayButton {
    if (!_todayButton) {
        _todayButton = [self createQuickButtonWithTitle:commonLocalizable(@"weekday_today") tag:0];
    }
    return _todayButton;
}

- (UIButton *)last7DaysButton {
    if (!_last7DaysButton) {
        _last7DaysButton = [self createQuickButtonWithTitle:commonLocalizable(@"weekday_last7day") tag:1];
    }
    return _last7DaysButton;
}

- (UIButton *)last30DaysButton {
    if (!_last30DaysButton) {
        _last30DaysButton = [self createQuickButtonWithTitle:commonLocalizable(@"weekday_last30day") tag:2];
    }
    return _last30DaysButton;
}

- (UIStackView *)quickButtonStack {
    if (!_quickButtonStack) {
        _quickButtonStack = [[UIStackView alloc] initWithArrangedSubviews:@[self.todayButton, self.last7DaysButton, self.last30DaysButton]];
        _quickButtonStack.axis = UILayoutConstraintAxisHorizontal;
        _quickButtonStack.distribution = UIStackViewDistributionFillEqually;
        _quickButtonStack.spacing = 12;
    }
    return _quickButtonStack;
}

- (UIButton *)monthSelectorButton {
    if (!_monthSelectorButton) {
        _monthSelectorButton = [[UIButton alloc] init];
        [_monthSelectorButton setTitleColor:UIColor.ne_lightText forState:UIControlStateNormal];
        _monthSelectorButton.titleLabel.font = [UIFont systemFontOfSize:14];
        _monthSelectorButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [_monthSelectorButton addTarget:self action:@selector(monthSelectorTapped) forControlEvents:UIControlEventTouchUpInside];

        UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage ne_imageNamed:@"history_search_date_arrow_down"]];
        icon.translatesAutoresizingMaskIntoConstraints = NO;
        [_monthSelectorButton addSubview:icon];
        [NSLayoutConstraint activateConstraints:@[
            [icon.centerYAnchor constraintEqualToAnchor:_monthSelectorButton.centerYAnchor],
            [icon.widthAnchor constraintEqualToConstant:12],
            [icon.heightAnchor constraintEqualToConstant:12],
        ]];
        if (_monthSelectorButton.titleLabel) {
            [NSLayoutConstraint activateConstraints:@[
                [icon.leftAnchor constraintEqualToAnchor:_monthSelectorButton.titleLabel.rightAnchor constant:0],
            ]];
        } else {
            [NSLayoutConstraint activateConstraints:@[
                [icon.rightAnchor constraintEqualToAnchor:_monthSelectorButton.rightAnchor constant:0],
            ]];
        }
    }
    return _monthSelectorButton;
}

- (UIStackView *)weekdayHeader {
    if (!_weekdayHeader) {
        NSArray *weekdays = @[
            commonLocalizable(@"weekday_sun"),
            commonLocalizable(@"weekday_mon"),
            commonLocalizable(@"weekday_tue"),
            commonLocalizable(@"weekday_wed"),
            commonLocalizable(@"weekday_thu"),
            commonLocalizable(@"weekday_fri"),
            commonLocalizable(@"weekday_sat"),
        ];
        NSMutableArray *labels = [NSMutableArray array];
        for (NSString *day in weekdays) {
            UILabel *label = [[UILabel alloc] init];
            label.text = day;
            label.textAlignment = NSTextAlignmentCenter;
            label.font = [UIFont systemFontOfSize:14];
            label.textColor = UIColor.ne_lightText;
            [labels addObject:label];
        }
        _weekdayHeader = [[UIStackView alloc] initWithArrangedSubviews:labels];
        _weekdayHeader.axis = UILayoutConstraintAxisHorizontal;
        _weekdayHeader.distribution = UIStackViewDistributionFillEqually;
    }
    return _weekdayHeader;
}

- (UICollectionView *)collectionView {
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionVertical;
        layout.minimumLineSpacing = 0;
        layout.minimumInteritemSpacing = 0;

        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        _collectionView.backgroundColor = UIColor.whiteColor;
        _collectionView.showsVerticalScrollIndicator = NO;
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        [_collectionView registerClass:[NEHistorySearchDateCell class] forCellWithReuseIdentifier:NSStringFromClass([NEHistorySearchDateCell class])];
        [_collectionView registerClass:[NEHistorySearchMonthHeaderView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:NSStringFromClass([NEHistorySearchMonthHeaderView class])];
    }
    return _collectionView;
}

- (NEHistorySearchMonthYearPickerView *)pickerView {
    if (!_pickerView) {
        CGFloat pickerHeight = 350;
        _pickerView = [[NEHistorySearchMonthYearPickerView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.view.bounds), CGRectGetWidth(self.view.bounds), pickerHeight)];
        _pickerView.themeColor = self.selectButtonBackgroundColor;
    }
    return _pickerView;
}

#pragma mark - Setup

- (void)setupUI {
    self.view.backgroundColor = UIColor.whiteColor;
    self.title = chatLocalizable(@"search_message_by_date");
    [self.navigationView setMoreButtonTitle:commonLocalizable(@"complete") color:self.selectButtonBackgroundColor];
    [self.navigationView addMoreButtonTarget:self selector:@selector(doneTapped)];
    self.navigationView.titleBarBottomLine.hidden = NO;

    for (UIView *item in @[self.quickButtonStack, self.monthSelectorButton, self.weekdayHeader, self.collectionView]) {
        item.translatesAutoresizingMaskIntoConstraints = NO;
        [self.view addSubview:item];
    }

    [NSLayoutConstraint activateConstraints:@[
        [self.quickButtonStack.topAnchor constraintEqualToAnchor:self.navigationView.bottomAnchor constant:12],
        [self.quickButtonStack.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [self.quickButtonStack.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        [self.quickButtonStack.heightAnchor constraintEqualToConstant:40],

        [self.monthSelectorButton.topAnchor constraintEqualToAnchor:self.quickButtonStack.bottomAnchor constant:20],
        [self.monthSelectorButton.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [self.monthSelectorButton.widthAnchor constraintEqualToConstant:100],
        [self.monthSelectorButton.heightAnchor constraintEqualToConstant:30],

        [self.weekdayHeader.topAnchor constraintEqualToAnchor:self.monthSelectorButton.bottomAnchor constant:10],
        [self.weekdayHeader.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [self.weekdayHeader.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        [self.weekdayHeader.heightAnchor constraintEqualToConstant:30],

        [self.collectionView.topAnchor constraintEqualToAnchor:self.weekdayHeader.bottomAnchor constant:5],
        [self.collectionView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [self.collectionView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        [self.collectionView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],
    ]];
}

- (UIButton *)createQuickButtonWithTitle:(NSString *)title tag:(NSInteger)tag {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:UIColor.ne_darkText forState:UIControlStateNormal];
    [button setTitleColor:UIColor.whiteColor forState:UIControlStateSelected];
    button.titleLabel.font = [UIFont systemFontOfSize:14];
    button.layer.cornerRadius = 4;
    button.layer.borderWidth = 1;
    button.layer.borderColor = [UIColor ne_colorWithHexString:@"#D9D9D9"].CGColor;
    button.tag = tag;
    [button addTarget:self action:@selector(quickButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)generateMonths {
    [self.months removeAllObjects];

    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [[NSDateComponents alloc] init];
    components.year = 1970;
    components.month = 1;
    components.day = 1;
    NSDate *startDate = [calendar dateFromComponents:components];
    if (!startDate) return;

    NSDateComponents *currentComponents = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth) fromDate:[NSDate date]];
    currentComponents.day = 1;
    NSDate *endDate = [calendar dateFromComponents:currentComponents];
    if (!endDate) return;

    NSDate *date = startDate;
    while ([date compare:endDate] != NSOrderedDescending) {
        [self.months addObject:date];
        NSDate *nextMonth = [calendar dateByAddingUnit:NSCalendarUnitMonth value:1 toDate:date options:0];
        if (!nextMonth) break;
        date = nextMonth;
    }
}

- (void)updateMonthSelectorTitle {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = commonLocalizable(@"ym");
    NSString *title = [formatter stringFromDate:self.currentDisplayMonth];
    [self.monthSelectorButton setTitle:title forState:UIControlStateNormal];
}

- (void)updateQuickButtonState:(NEHistoryQuickSelectType)type {
    self.quickSelectType = type;

    for (UIButton *button in @[self.todayButton, self.last7DaysButton, self.last30DaysButton]) {
        button.selected = NO;
        button.backgroundColor = UIColor.whiteColor;
        button.layer.borderColor = UIColor.lightGrayColor.CGColor;
    }

    UIButton *selectedButton = nil;
    switch (type) {
        case NEHistoryQuickSelectTypeToday:
            selectedButton = self.todayButton;
            break;
        case NEHistoryQuickSelectTypeLast7Days:
            selectedButton = self.last7DaysButton;
            break;
        case NEHistoryQuickSelectTypeLast30Days:
            selectedButton = self.last30DaysButton;
            break;
        default:
            break;
    }

    selectedButton.selected = YES;
    selectedButton.backgroundColor = self.selectButtonBackgroundColor;
    selectedButton.layer.borderColor = self.selectButtonBackgroundColor.CGColor;
}

#pragma mark - Actions

- (void)doneTapped {
    if (!self.selectedDate) {
        [self showToast:chatLocalizable(@"choose")];
        return;
    }

    if (IMKitConfigCenter.shared.enableCloudMessageSearch) {
        if (![[NEChatDetectNetworkTool shareInstance] isNetworkReachability]) {
            [self showToast:commonLocalizable(@"network_error")];
            return;
        }
    }

    int64_t timestamp = MAX((int64_t)self.selectedDate.timeIntervalSince1970, 0);
    [self.delegate datePickerDidSelectDate:timestamp];
}

- (void)quickButtonTapped:(UIButton *)sender {
    NSDate *targetDate = nil;
    NEHistoryQuickSelectType type = NEHistoryQuickSelectTypeNone;
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *today = [NSDate date];

    switch (sender.tag) {
        case 0:
            targetDate = today;
            type = NEHistoryQuickSelectTypeToday;
            break;
        case 1:
            targetDate = [calendar dateByAddingUnit:NSCalendarUnitDay value:-7 toDate:today options:0];
            type = NEHistoryQuickSelectTypeLast7Days;
            break;
        case 2:
            targetDate = [calendar dateByAddingUnit:NSCalendarUnitDay value:-30 toDate:today options:0];
            type = NEHistoryQuickSelectTypeLast30Days;
            break;
        default:
            break;
    }

    if (!targetDate) return;

    [self updateQuickButtonState:type];
    self.selectedDate = [calendar startOfDayForDate:targetDate];
    [self scrollToDate:targetDate animated:YES];
    [self.collectionView reloadData];
}

- (void)monthSelectorTapped {
    [self showMonthPicker];
}

- (void)scrollToToday:(BOOL)animated {
    [self scrollToDate:[NSDate date] animated:animated];
}

- (void)scrollToDate:(NSDate *)date animated:(BOOL)animated {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *targetComponents = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth) fromDate:date];

    for (NSUInteger i = 0; i < self.months.count; i++) {
        NSDate *month = self.months[i];
        NSDateComponents *monthComponents = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth) fromDate:month];
        if (monthComponents.year == targetComponents.year && monthComponents.month == targetComponents.month) {
            NSInteger dayOfMonth = [calendar component:NSCalendarUnitDay fromDate:date];
            NSInteger firstWeekday = [self getFirstWeekdayOfMonth:month];
            NSInteger item = firstWeekday + dayOfMonth - 1;

            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:(NSInteger)i];
            [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:animated];

            if (i > 0) {
                self.currentDisplayMonth = self.months[i - 1];
            } else {
                self.currentDisplayMonth = month;
            }
            [self updateMonthSelectorTitle];
            return;
        }
    }
}

- (void)scrollToMonth:(NSDate *)date animated:(BOOL)animated {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *targetComponents = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth) fromDate:date];

    for (NSUInteger i = 0; i < self.months.count; i++) {
        NSDate *month = self.months[i];
        NSDateComponents *monthComponents = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth) fromDate:month];
        if (monthComponents.year == targetComponents.year && monthComponents.month == targetComponents.month) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:(NSInteger)i];
            [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionTop animated:animated];
            self.currentDisplayMonth = month;
            [self updateMonthSelectorTitle];
            return;
        }
    }
}

- (void)showMonthPicker {
    UIView *dimView = [[UIView alloc] initWithFrame:self.view.bounds];
    dimView.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.5];
    dimView.alpha = 0;
    [self.view addSubview:dimView];
    self.dimView = dimView;

    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissMonthPicker)];
    [dimView addGestureRecognizer:tapGesture];

    self.pickerView.currentDate = self.currentDisplayMonth;
    self.pickerView.themeColor = self.selectButtonBackgroundColor;
    self.pickerView.maxDate = [NSDate date];

    __weak typeof(self) weakSelf = self;
    CGFloat pickerHeight = 350;
    self.pickerView.onConfirm = ^(NSInteger year, NSInteger month) {
        [weakSelf dismissMonthPicker];
        NSDateComponents *components = [[NSDateComponents alloc] init];
        components.year = year;
        components.month = month;
        components.day = 1;
        NSDate *date = [[NSCalendar currentCalendar] dateFromComponents:components];
        if (date) {
            weakSelf.selectedDate = nil;
            [weakSelf updateQuickButtonState:NEHistoryQuickSelectTypeNone];
            [weakSelf scrollToMonth:date animated:NO];
            [weakSelf.collectionView reloadData];
        }
    };
    self.pickerView.onCancel = ^{
        [weakSelf dismissMonthPicker];
    };

    [self.view addSubview:self.pickerView];
    self.monthPickerView = self.pickerView;

    [UIView animateWithDuration:0.3 animations:^{
        dimView.alpha = 1;
        CGRect frame = weakSelf.pickerView.frame;
        frame.origin.y = CGRectGetHeight(weakSelf.view.bounds) - pickerHeight;
        weakSelf.pickerView.frame = frame;
    }];
}

- (void)dismissMonthPicker {
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.3 animations:^{
        weakSelf.dimView.alpha = 0;
        CGRect frame = weakSelf.monthPickerView.frame;
        frame.origin.y = CGRectGetHeight(weakSelf.view.bounds);
        weakSelf.monthPickerView.frame = frame;
    } completion:^(BOOL finished) {
        [weakSelf.dimView removeFromSuperview];
        [weakSelf.monthPickerView removeFromSuperview];
        weakSelf.dimView = nil;
        weakSelf.monthPickerView = nil;
    }];
}

- (NSInteger)getFirstWeekdayOfMonth:(NSDate *)date {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth) fromDate:date];
    components.day = 1;
    NSDate *firstDay = [calendar dateFromComponents:components];
    if (!firstDay) return 0;
    return [calendar component:NSCalendarUnitWeekday fromDate:firstDay] - 1;
}

- (NSInteger)getDaysInMonth:(NSDate *)date {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSRange range = [calendar rangeOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitMonth forDate:date];
    return range.length > 0 ? (NSInteger)range.length : 30;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return (NSInteger)self.months.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSDate *month = self.months[section];
    NSInteger firstWeekday = [self getFirstWeekdayOfMonth:month];
    NSInteger daysInMonth = [self getDaysInMonth:month];
    return firstWeekday + daysInMonth;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NEHistorySearchDateCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([NEHistorySearchDateCell class]) forIndexPath:indexPath];
    cell.selectButtonBackgroundColor = self.selectButtonBackgroundColor;

    NSDate *month = self.months[indexPath.section];
    NSInteger firstWeekday = [self getFirstWeekdayOfMonth:month];

    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *today = [NSDate date];

    if (indexPath.item < firstWeekday) {
        [cell configureWithDay:nil isToday:NO isSelected:NO isFuture:NO];
    } else {
        NSInteger day = indexPath.item - firstWeekday + 1;
        NSDateComponents *components = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth) fromDate:month];
        components.day = day;
        NSDate *date = [calendar dateFromComponents:components];
        if (!date) {
            [cell configureWithDay:nil isToday:NO isSelected:NO isFuture:NO];
            return cell;
        }

        BOOL isToday = [calendar isDateInToday:date];
        BOOL isFuture = ([date compare:today] == NSOrderedDescending) && !isToday;
        BOOL isSelected = self.selectedDate != nil && [calendar isDate:date inSameDayAsDate:self.selectedDate];

        [cell configureWithDay:@(day) isToday:isToday isSelected:isSelected isFuture:isFuture];
    }

    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    NEHistorySearchMonthHeaderView *header = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:NSStringFromClass([NEHistorySearchMonthHeaderView class]) forIndexPath:indexPath];

    NSDate *month = self.months[indexPath.section];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = commonLocalizable(@"m");
    [header configureWithTitle:[formatter stringFromDate:month]];

    return header;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSDate *month = self.months[indexPath.section];
    NSInteger firstWeekday = [self getFirstWeekdayOfMonth:month];
    if (indexPath.item < firstWeekday) return;

    NSInteger day = indexPath.item - firstWeekday + 1;
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSInteger year = [calendar component:NSCalendarUnitYear fromDate:month];
    NSInteger monthValue = [calendar component:NSCalendarUnitMonth fromDate:month];

    NSDateComponents *components = [[NSDateComponents alloc] init];
    components.year = year;
    components.month = monthValue;
    components.day = day;
    components.hour = 0;
    components.minute = 0;
    components.second = 0;

    NSDate *date = [calendar dateFromComponents:components];
    if (!date) return;

    NSDate *today = [NSDate date];
    if ([date compare:today] == NSOrderedDescending && ![calendar isDateInToday:date]) return;

    self.selectedDate = date;

    NSLog(@"选中日期: %ld-%ld-%ld, timestamp: %lld", (long)year, (long)monthValue, (long)day, (int64_t)date.timeIntervalSince1970);

    if ([calendar isDateInToday:date]) {
        [self updateQuickButtonState:NEHistoryQuickSelectTypeToday];
    } else {
        [self updateQuickButtonState:NEHistoryQuickSelectTypeNone];
    }

    [self.collectionView reloadData];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    NSArray<NSIndexPath *> *visibleIndexPaths = [[self.collectionView indexPathsForVisibleItems] sortedArrayUsingSelector:@selector(compare:)];
    if (visibleIndexPaths.count == 0) return;

    NSIndexPath *firstIndexPath = visibleIndexPaths.firstObject;
    NSDate *month = self.months[firstIndexPath.section];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    if (![calendar isDate:month equalToDate:self.currentDisplayMonth toUnitGranularity:NSCalendarUnitMonth]) {
        self.currentDisplayMonth = month;
        [self updateMonthSelectorTitle];
    }
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat width = CGRectGetWidth(collectionView.bounds) / 7.0;
    return CGSizeMake(width, 70);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    return CGSizeMake(CGRectGetWidth(collectionView.bounds), 50);
}

@end
