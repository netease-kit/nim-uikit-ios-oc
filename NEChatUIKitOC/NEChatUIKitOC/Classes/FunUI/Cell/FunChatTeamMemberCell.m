// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunChatTeamMemberCell.h"
#import "FunChatUIColor.h"

@implementation FunChatTeamMemberCell

- (UIColor *)searchHighlightColor { return UIColor.ne_searchHighlight; }
- (CGFloat)nameHorizontalSpacing { return 11; }
- (CGFloat)nameTrailingInset { return 29; }

- (void)setupUI {
    [super setupUI];
    self.headerView.layer.cornerRadius = 4;
    [NSLayoutConstraint activateConstraints:@[
        [self.headerView.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:16],
        [self.headerView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
        [self.headerView.widthAnchor constraintEqualToConstant:40],
        [self.headerView.heightAnchor constraintEqualToConstant:40],
    ]];

    UIView *line = [[UIView alloc] init];
    line.translatesAutoresizingMaskIntoConstraints = NO;
    line.backgroundColor = [UIColor funChatLineBorderColor];
    [self.contentView addSubview:line];
    [NSLayoutConstraint activateConstraints:@[
        [line.leftAnchor constraintEqualToAnchor:self.headerView.leftAnchor],
        [line.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor],
        [line.heightAnchor constraintEqualToConstant:0.6],
        [line.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
    ]];
}

@end
