// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "CustomSettingInputCell.h"
#import "NEStyleManager.h"

@implementation CustomSettingInputCell

- (void)setupUI {
  [self.contentView addSubview:self.titleLabel];
  [self.contentView addSubview:self.inputTextField];

  if ([NEStyleManager.instance isNormalStyle]) {
    [NSLayoutConstraint activateConstraints:@[
      [self.titleLabel.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:36],
      [self.titleLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:15],
      [self.titleLabel.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-36],
    ]];
    self.titleWidthAnchor = [self.titleLabel.widthAnchor constraintEqualToConstant:0.0];
    self.titleWidthAnchor.active = YES;

    [NSLayoutConstraint activateConstraints:@[
      [self.inputTextField.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:36],
      [self.inputTextField.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-36],
      [self.inputTextField.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:10],
      [self.inputTextField.heightAnchor constraintEqualToConstant:40],
    ]];
  } else {
    UIView *whiteBgView = [[UIView alloc] init];
    whiteBgView.backgroundColor = UIColor.whiteColor;
    whiteBgView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView insertSubview:whiteBgView belowSubview:self.dividerLine];
    [NSLayoutConstraint activateConstraints:@[
      [whiteBgView.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor],
      [whiteBgView.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor],
      [whiteBgView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
      [whiteBgView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
    ]];

    [NSLayoutConstraint activateConstraints:@[
      [self.titleLabel.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:20],
      [self.titleLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:15],
      [self.titleLabel.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-20],
    ]];
    self.titleWidthAnchor = [self.titleLabel.widthAnchor constraintEqualToConstant:0.0];
    self.titleWidthAnchor.active = YES;

    [NSLayoutConstraint activateConstraints:@[
      [self.inputTextField.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:20],
      [self.inputTextField.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-20],
      [self.inputTextField.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:10],
      [self.inputTextField.heightAnchor constraintEqualToConstant:40],
    ]];
    self.dividerLineLeftMargin.constant = 20.0;
    self.dividerLineRightMargin.constant = 0.0;
  }
}

- (void)configure:(id)anyModel {
  [super configure:anyModel];
  if ([anyModel isKindOfClass:[CustomSettingCellModel class]]) {
    CustomSettingCellModel *model = (CustomSettingCellModel *)anyModel;
    self.inputTextField.placeholder = model.placeholder;
    self.inputTextField.text = model.customInputText;
    self.titleLabel.text = model.cellName;
    self.cornerType = model.cornerType;
    self.dataModel = model;
  }
}

- (BOOL)textField:(UITextField *)textField
    shouldChangeCharactersInRange:(NSRange)range
                replacementString:(NSString *)string {
  NSString *changeString = [textField.text stringByReplacingCharactersInRange:range withString:string];
  self.dataModel.customInputText = changeString;
  return YES;
}

- (UITextField *)inputTextField {
  if (!_inputTextField) {
    _inputTextField = [[UITextField alloc] init];
    _inputTextField.translatesAutoresizingMaskIntoConstraints = NO;
    _inputTextField.font = [UIFont systemFontOfSize:14];
    _inputTextField.textColor = UIColor.blackColor;
    _inputTextField.borderStyle = UITextBorderStyleRoundedRect;
    _inputTextField.textAlignment = NSTextAlignmentLeft;
    _inputTextField.delegate = self;
  }
  return _inputTextField;
}

@end
