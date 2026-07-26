// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "CustomSettingTextviewCell.h"
#import <NEChatKit/UIColor+NECommon.h>
#import "NEStyleManager.h"

@implementation CustomSettingTextviewCell

- (void)setupUI {
  [self.contentView addSubview:self.titleLabel];
  [self.contentView addSubview:self.inputTextView];

  if ([NEStyleManager.instance isNormalStyle]) {
    [NSLayoutConstraint activateConstraints:@[
      [self.titleLabel.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:36],
      [self.titleLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:15],
      [self.titleLabel.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-36],
    ]];
    self.titleWidthAnchor = [self.titleLabel.widthAnchor constraintEqualToConstant:0.0];
    self.titleWidthAnchor.active = YES;

    [NSLayoutConstraint activateConstraints:@[
      [self.inputTextView.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:36],
      [self.inputTextView.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-36],
      [self.inputTextView.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:10],
      [self.inputTextView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-10],
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
      [self.inputTextView.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:20],
      [self.inputTextView.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-20],
      [self.inputTextView.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:10],
      [self.inputTextView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-10],
    ]];
    self.dividerLineLeftMargin.constant = 20.0;
    self.dividerLineRightMargin.constant = 0.0;
  }
}

- (void)configure:(id)anyModel {
  [super configure:anyModel];
  if ([anyModel isKindOfClass:[CustomSettingCellModel class]]) {
    CustomSettingCellModel *model = (CustomSettingCellModel *)anyModel;
    self.titleLabel.text = model.cellName;
    self.cornerType = model.cornerType;
    self.inputTextView.text = model.customInputText;
    self.dataModel = model;
  }
}

- (BOOL)textView:(UITextView *)textView
    shouldChangeTextInRange:(NSRange)range
            replacementText:(NSString *)text {
  NSString *changeString = [textView.text stringByReplacingCharactersInRange:range withString:text];
  self.dataModel.customInputText = changeString;
  return YES;
}

- (UITextView *)inputTextView {
  if (!_inputTextView) {
    _inputTextView = [[UITextView alloc] init];
    _inputTextView.translatesAutoresizingMaskIntoConstraints = NO;
    _inputTextView.font = [UIFont systemFontOfSize:14];
    _inputTextView.textColor = [UIColor ne_darkText];
    _inputTextView.textAlignment = NSTextAlignmentLeft;
    _inputTextView.layer.cornerRadius = 4;
    _inputTextView.layer.borderWidth = 1;
    _inputTextView.layer.borderColor = [UIColor ne_outlineColor].CGColor;
    _inputTextView.delegate = self;
  }
  return _inputTextView;
}

@end
