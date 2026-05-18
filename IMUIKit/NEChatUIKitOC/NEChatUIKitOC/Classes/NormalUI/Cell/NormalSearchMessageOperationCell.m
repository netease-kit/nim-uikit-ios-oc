// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NormalSearchMessageOperationCell.h"
#import "NormalChatUIColor.h"

@implementation NormalSearchMessageOperationCell

- (void)commonUI {
    [super commonUI];

    UIView *backView = [[UIView alloc] init];
    backView.translatesAutoresizingMaskIntoConstraints = NO;
    backView.backgroundColor = UIColor.normalSearchMessageCellBg;
    backView.layer.cornerRadius = 24;
    [self.contentView insertSubview:backView belowSubview:self.imageView];
    [NSLayoutConstraint activateConstraints:@[
        [backView.centerXAnchor constraintEqualToAnchor:self.imageView.centerXAnchor],
        [backView.centerYAnchor constraintEqualToAnchor:self.imageView.centerYAnchor],
        [backView.widthAnchor constraintEqualToConstant:48],
        [backView.heightAnchor constraintEqualToConstant:48],
    ]];

    // 更新 imageView 尺寸约束为 48x48
    for (NSLayoutConstraint *c in self.imageView.constraints) {
        if (c.firstAttribute == NSLayoutAttributeWidth && c.firstItem == self.imageView && c.secondItem == nil) {
            c.constant = 48;
        }
        if (c.firstAttribute == NSLayoutAttributeHeight && c.firstItem == self.imageView && c.secondItem == nil) {
            c.constant = 48;
        }
    }
    // 更新 label 到 imageView 的间距
    for (NSLayoutConstraint *c in self.contentView.constraints) {
        if (c.firstAttribute == NSLayoutAttributeTop && c.firstItem == self.label && c.secondItem == self.imageView) {
            c.constant = 12;
        }
    }
}

@end
