// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunSearchMessageOperationCell.h"
#import "FunChatUIColor.h"
#import <NEChatKitOC/UIColor+NECommon.h>
#import <NECommonUIKitOC/UIView+YXToast.h>

@implementation FunSearchMessageOperationCell

- (void)commonUI {
    [super commonUI];
    [self.imageView removeFromSuperview];

    self.label.textColor = [UIColor funChatQuickHistoryCellTitleTextColor];
    self.label.font = [UIFont systemFontOfSize:16];
    [NSLayoutConstraint activateConstraints:@[
        [self.label.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:0],
    ]];

    [self.label updateLayoutConstraintFirstItem:self.label secondItem:self.label attribute:NSLayoutAttributeHeight constant:48];

    [self.contentView addSubview:self.lineView];
    [NSLayoutConstraint activateConstraints:@[
        [self.lineView.centerYAnchor constraintEqualToAnchor:self.label.centerYAnchor],
        [self.lineView.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor],
        [self.lineView.heightAnchor constraintEqualToConstant:20],
        [self.lineView.widthAnchor constraintEqualToConstant:0.25],
    ]];
}

- (UIView *)lineView {
    if (!_lineView) {
        _lineView = [[UIView alloc] init];
        _lineView.translatesAutoresizingMaskIntoConstraints = NO;
        _lineView.backgroundColor = [UIColor ne_colorWithHexString:@"#C9C9C9"];
    }
    return _lineView;
}

@end
