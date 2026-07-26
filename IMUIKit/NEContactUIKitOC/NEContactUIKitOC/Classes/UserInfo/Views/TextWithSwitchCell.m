// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

#import "TextWithSwitchCell.h"
#import <NEChatKit/UIColor+NECommon.h>
#import <NECommonUIKitOC/NECommonUIKitOC.h>

@implementation TextWithSwitchCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    self.switchButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.switchButton.onTintColor = [UIColor ne_colorWithHexString:@"#337EFF"];
    self.switchButton.accessibilityIdentifier = @"id.tSwitch";
    [self.switchButton addTarget:self action:@selector(valueChanged:) forControlEvents:UIControlEventTouchUpInside];

    [self.contentView addSubview:self.switchButton];
    [NSLayoutConstraint activateConstraints:@[
      [self.switchButton.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-20],
      [self.switchButton.widthAnchor constraintEqualToConstant:46],
      [self.switchButton.heightAnchor constraintEqualToConstant:28],
      [self.switchButton.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    ]];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  return [super initWithCoder:coder];
}

- (void)valueChanged:(UISwitch *)switchBtn {
  NSLog(@"switchBtn:%d", switchBtn.isOn);
  if (self.block) {
    self.block(self.titleLabel.text, switchBtn.isOn);
  }
}

- (UISwitch *)switchButton {
  if (!_switchButton) { _switchButton = [[UISwitch alloc] init]; }
  return _switchButton;
}

@end
