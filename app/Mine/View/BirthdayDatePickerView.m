// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "BirthdayDatePickerView.h"
#import "AppKey.h"
#import <NEChatKit/UIColor+NECommon.h>
#import <NEBaseUIKitOC/NECommonUIConstant.h>

@interface BirthdayDatePickerView ()
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) UIButton *sureButton;
@property (nonatomic, strong) UIView   *bottomLine;
@property (nonatomic, strong) UIView   *pickerBackView;
@property (nonatomic, copy)   NSString *selectTime;
@end

@implementation BirthdayDatePickerView

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.25];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(removeFromSuperview)];
    [self addGestureRecognizer:tap];
    [self setupSubviews];
  }
  return self;
}

- (void)setupSubviews {
  _pickerBackView = [[UIView alloc] init];
  _pickerBackView.translatesAutoresizingMaskIntoConstraints = NO;
  _pickerBackView.backgroundColor = UIColor.whiteColor;
  [self addSubview:_pickerBackView];

  _cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
  _cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
  [_cancelButton setTitle:commonLocalizable(@"cancel") forState:UIControlStateNormal];
  [_cancelButton setTitleColor:[UIColor ne_normalTheme] forState:UIControlStateNormal];
  _cancelButton.titleLabel.font = [UIFont systemFontOfSize:14];
  [_cancelButton addTarget:self action:@selector(removeFromSuperview) forControlEvents:UIControlEventTouchUpInside];
  _cancelButton.accessibilityIdentifier = @"id.adaptiveBack";
  [_pickerBackView addSubview:_cancelButton];

  _sureButton = [UIButton buttonWithType:UIButtonTypeCustom];
  _sureButton.translatesAutoresizingMaskIntoConstraints = NO;
  [_sureButton setTitle:commonLocalizable(@"ok") forState:UIControlStateNormal];
  [_sureButton setTitleColor:[UIColor ne_normalTheme] forState:UIControlStateNormal];
  _sureButton.titleLabel.font = [UIFont systemFontOfSize:14];
  [_sureButton addTarget:self action:@selector(sureBtnClick) forControlEvents:UIControlEventTouchUpInside];
  _sureButton.accessibilityIdentifier = @"id.sureButton";
  [_pickerBackView addSubview:_sureButton];

  _bottomLine = [[UIView alloc] init];
  _bottomLine.translatesAutoresizingMaskIntoConstraints = NO;
  _bottomLine.backgroundColor = [UIColor colorWithRed:0xDB/255.0 green:0xE0/255.0 blue:0xE8/255.0 alpha:1.0];
  [_pickerBackView addSubview:_bottomLine];

  _picker = [[UIDatePicker alloc] init];
  _picker.translatesAutoresizingMaskIntoConstraints = NO;
  _picker.locale = [NSLocale localeWithLocaleIdentifier:@"zh_CN"];
  _picker.datePickerMode = UIDatePickerModeDate;
  _picker.maximumDate = [NSDate date];
  if (@available(iOS 13.4, *)) {
    _picker.preferredDatePickerStyle = UIDatePickerStyleWheels;
  }
  [_picker addTarget:self action:@selector(dateChanged:) forControlEvents:UIControlEventValueChanged];
  [_pickerBackView addSubview:_picker];

  [NSLayoutConstraint activateConstraints:@[
    [_pickerBackView.leftAnchor constraintEqualToAnchor:self.leftAnchor],
    [_pickerBackView.rightAnchor constraintEqualToAnchor:self.rightAnchor],
    [_pickerBackView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
    [_pickerBackView.heightAnchor constraintEqualToConstant:229],

    [_cancelButton.leftAnchor constraintEqualToAnchor:_pickerBackView.leftAnchor constant:15],
    [_cancelButton.topAnchor constraintEqualToAnchor:_pickerBackView.topAnchor constant:8],
    [_cancelButton.widthAnchor constraintEqualToConstant:45],
    [_cancelButton.heightAnchor constraintEqualToConstant:20],

    [_sureButton.rightAnchor constraintEqualToAnchor:_pickerBackView.rightAnchor constant:-15],
    [_sureButton.topAnchor constraintEqualToAnchor:_pickerBackView.topAnchor constant:8],
    [_sureButton.widthAnchor constraintEqualToConstant:45],
    [_sureButton.heightAnchor constraintEqualToConstant:20],

    [_bottomLine.leftAnchor constraintEqualToAnchor:_pickerBackView.leftAnchor],
    [_bottomLine.rightAnchor constraintEqualToAnchor:_pickerBackView.rightAnchor],
    [_bottomLine.topAnchor constraintEqualToAnchor:_cancelButton.bottomAnchor constant:8],
    [_bottomLine.heightAnchor constraintEqualToConstant:0.5],

    [_picker.leftAnchor constraintEqualToAnchor:_pickerBackView.leftAnchor],
    [_picker.rightAnchor constraintEqualToAnchor:_pickerBackView.rightAnchor],
    [_picker.topAnchor constraintEqualToAnchor:_bottomLine.bottomAnchor],
    [_picker.bottomAnchor constraintEqualToAnchor:_pickerBackView.bottomAnchor],
  ]];
}

- (void)dateChanged:(UIDatePicker *)datePicker {
  NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
  fmt.dateFormat = @"yyyy-MM-dd";
  self.selectTime = [fmt stringFromDate:datePicker.date];
}

- (void)removeFromSuperview {
  [super removeFromSuperview];
  void (^dismiss)(void) = self.onDismiss;
  if (dismiss) {
    dismiss();
  }
}

- (void)sureBtnClick {
  [self removeFromSuperview];
  if (!self.selectTime) {
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    fmt.dateFormat = @"yyyy-MM-dd";
    self.selectTime = [fmt stringFromDate:self.picker.date];
  }
  if (self.timeCallBack) {
    self.timeCallBack(self.selectTime);
  }
}

@end
