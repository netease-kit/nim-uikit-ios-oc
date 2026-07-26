// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseRobotNicknameEditController.h"
#import "ContactConst.h"
#import "NormalContactUIColor.h"
#import <NEChatKit/UIColor+NECommon.h>
#import <NECommonUIKitOC/NECommonUIKitOC.h>

@implementation NEBaseRobotNicknameEditController

- (instancetype)init {
  self = [super init];
  if (self) {
    _currentName = @"";
    _nameLimit = 15;
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.title = contactLocalizable(@"ai_robot_name");
  self.view.backgroundColor = [UIColor ne_lightBackgroundColor];

  NSNumber *useSystemNavValue = [[NEConfigManager instance] getParameterForKey:useSystemNav];
  if (useSystemNavValue && [useSystemNavValue boolValue]) {
    UIBarButtonItem *doneItem =
        [[UIBarButtonItem alloc] initWithTitle:contactLocalizable(@"done")
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(didTapSave)];
    doneItem.tintColor = [self saveButtonColor];
    self.navigationItem.rightBarButtonItem = doneItem;
  } else {
    [self.navigationView setMoreButtonTitle:contactLocalizable(@"done") color:[self saveButtonColor]];
    [self.navigationView addMoreButtonTarget:self selector:@selector(didTapSave)];
  }

  [self setupNicknameEditUI];
  self.textField.text = self.currentName;
  [self updateCountLabelWithText:self.currentName];

  __weak typeof(self) weakSelf = self;
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    [weakSelf.textField becomeFirstResponder];
  });
}

- (void)setupNicknameEditUI {
  [self.view addSubview:self.textFieldContainer];
  [NSLayoutConstraint activateConstraints:@[
    [self.textFieldContainer.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:self.topConstant + 12.0],
    [self.textFieldContainer.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.textFieldContainer.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [self.textFieldContainer.heightAnchor constraintEqualToConstant:48.0],
  ]];
  [self setupTextFieldContainerStyle];

  self.textField.rightView = [self buildRightView];
  self.textField.rightViewMode = UITextFieldViewModeAlways;

  [self.textFieldContainer addSubview:self.textField];
  [NSLayoutConstraint activateConstraints:@[
    [self.textField.leftAnchor constraintEqualToAnchor:self.textFieldContainer.leftAnchor],
    [self.textField.rightAnchor constraintEqualToAnchor:self.textFieldContainer.rightAnchor constant:-8.0],
    [self.textField.topAnchor constraintEqualToAnchor:self.textFieldContainer.topAnchor],
    [self.textField.bottomAnchor constraintEqualToAnchor:self.textFieldContainer.bottomAnchor],
  ]];
}

- (UIView *)buildRightView {
  CGFloat countLabelW = 40.0;
  CGFloat clearButtonW = 20.0;
  CGFloat spacing = 4.0;
  CGFloat rightPadding = 8.0;
  CGFloat containerW = countLabelW + spacing + clearButtonW + rightPadding;
  CGFloat containerH = 44.0;

  UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, containerW, containerH)];
  container.backgroundColor = [UIColor clearColor];

  self.countLabel.frame = CGRectMake(0, (containerH - 18.0) / 2.0, countLabelW, 18.0);
  [container addSubview:self.countLabel];

  self.clearButton.frame =
      CGRectMake(countLabelW + spacing, (containerH - clearButtonW) / 2.0, clearButtonW, clearButtonW);
  [container addSubview:self.clearButton];
  return container;
}

- (void)setupTextFieldContainerStyle {
}

- (UIColor *)saveButtonColor {
  return [UIColor normalContactThemeColor];
}

- (void)updateCountLabelWithText:(NSString *)text {
  self.countLabel.text = [NSString stringWithFormat:@"%lu/%ld", (unsigned long)text.length, (long)self.nameLimit];
}

- (void)didTapSave {
  NSString *name =
      [self.textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  if (name.length == 0) {
    [self.view ne_makeToast:contactLocalizable(@"ai_robot_name_placeholder")];
    return;
  }
  if (self.onSaved) {
    self.onSaved(name);
  }
  [self.navigationController popViewControllerAnimated:YES];
}

- (void)didTapClear {
  self.textField.text = @"";
  [self updateCountLabelWithText:@""];
}

- (void)textFieldChanged {
  NSString *text = self.textField.text ?: @"";
  if (text.length > self.nameLimit) {
    text = [text substringToIndex:self.nameLimit];
    self.textField.text = text;
  }
  [self updateCountLabelWithText:text];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [textField resignFirstResponder];
  return YES;
}

#pragma mark - Lazy Init

- (UILabel *)countLabel {
  if (!_countLabel) {
    _countLabel = [[UILabel alloc] init];
    _countLabel.font = [UIFont systemFontOfSize:13.0];
    _countLabel.textColor = [UIColor ne_colorWithHexString:@"999999"];
    _countLabel.textAlignment = NSTextAlignmentRight;
    _countLabel.text = [NSString stringWithFormat:@"0/%ld", (long)self.nameLimit];
  }
  return _countLabel;
}

- (UIButton *)clearButton {
  if (!_clearButton) {
    _clearButton = [UIButton buttonWithType:UIButtonTypeCustom];
    if (@available(iOS 13.0, *)) {
      UIImageSymbolConfiguration *config =
          [UIImageSymbolConfiguration configurationWithPointSize:14.0 weight:UIImageSymbolWeightRegular];
      UIImage *image = [UIImage systemImageNamed:@"xmark.circle.fill" withConfiguration:config];
      [_clearButton setImage:image forState:UIControlStateNormal];
      _clearButton.tintColor = [UIColor ne_colorWithHexString:@"CCCCCC"];
    } else {
      [_clearButton setTitle:@"✕" forState:UIControlStateNormal];
      [_clearButton setTitleColor:[UIColor ne_colorWithHexString:@"CCCCCC"] forState:UIControlStateNormal];
      _clearButton.titleLabel.font = [UIFont systemFontOfSize:14.0];
    }
    _clearButton.accessibilityIdentifier = @"id.clear";
    [_clearButton addTarget:self action:@selector(didTapClear) forControlEvents:UIControlEventTouchUpInside];
  }
  return _clearButton;
}

- (UITextField *)textField {
  if (!_textField) {
    _textField = [[UITextField alloc] init];
    _textField.translatesAutoresizingMaskIntoConstraints = NO;
    _textField.font = [UIFont systemFontOfSize:16.0];
    _textField.textColor = [UIColor ne_darkText];
    _textField.clearButtonMode = UITextFieldViewModeNever;
    _textField.returnKeyType = UIReturnKeyDone;
    _textField.delegate = self;
    _textField.accessibilityIdentifier = @"id.editText";
    [_textField addTarget:self action:@selector(textFieldChanged) forControlEvents:UIControlEventEditingChanged];

    UIView *leftPadding = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 16.0, 0)];
    _textField.leftView = leftPadding;
    _textField.leftViewMode = UITextFieldViewModeAlways;
  }
  return _textField;
}

- (UIView *)textFieldContainer {
  if (!_textFieldContainer) {
    _textFieldContainer = [[UIView alloc] init];
    _textFieldContainer.translatesAutoresizingMaskIntoConstraints = NO;
    _textFieldContainer.backgroundColor = [UIColor whiteColor];
  }
  return _textFieldContainer;
}

@end
