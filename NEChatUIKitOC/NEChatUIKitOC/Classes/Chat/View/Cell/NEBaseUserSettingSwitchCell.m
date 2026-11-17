// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseUserSettingSwitchCell.h"

#import "MessageContentModel.h"

@implementation NEBaseUserSettingSwitchCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self setupUI];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    return self;
}

- (UISwitch *)tSwitch {
    if (!_tSwitch) {
        _tSwitch = [[UISwitch alloc] init];
        _tSwitch.translatesAutoresizingMaskIntoConstraints = NO;
        _tSwitch.onTintColor = [NEConstant hexRGB:0x337EFF];
        _tSwitch.accessibilityIdentifier = @"id.tSwitch";
    }
    return _tSwitch;
}

- (void)configure:(id)anyModel {
    [super configure:anyModel];
    if (self.model) {
        self.tSwitch.on = self.model.switchOpen;
    }
}

- (void)setupUI {
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.tSwitch];
    [self.tSwitch addTarget:self action:@selector(switchChange:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)switchChange:(UISwitch *)sender {
    if (self.model.swichChange) {
        self.model.swichChange(sender.isOn);
    }
}

@end
