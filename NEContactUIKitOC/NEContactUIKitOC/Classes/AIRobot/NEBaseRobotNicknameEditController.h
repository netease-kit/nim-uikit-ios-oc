// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEContactBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface NEBaseRobotNicknameEditController : NEContactBaseViewController <UITextFieldDelegate>

@property(nonatomic, copy) NSString *currentName;
@property(nonatomic, copy, nullable) void (^onSaved)(NSString *name);
@property(nonatomic, assign, readonly) NSInteger nameLimit;

@property(nonatomic, strong) UILabel *countLabel;
@property(nonatomic, strong) UIButton *clearButton;
@property(nonatomic, strong) UITextField *textField;
@property(nonatomic, strong) UIView *textFieldContainer;

- (void)setupNicknameEditUI;
- (UIView *)buildRightView;
- (void)setupTextFieldContainerStyle;
- (UIColor *)saveButtonColor;
- (void)updateCountLabelWithText:(NSString *)text;

- (void)didTapSave;
- (void)didTapClear;
- (void)textFieldChanged;

@end

NS_ASSUME_NONNULL_END
