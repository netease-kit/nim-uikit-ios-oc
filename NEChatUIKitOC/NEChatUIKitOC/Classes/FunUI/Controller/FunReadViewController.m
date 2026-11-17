// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunReadViewController.h"
#import <NEChatKit/UIColor+NECommon.h>
#import "FunUserTableViewCell.h"
#import "FunChatUIColor.h"

@implementation FunReadViewController

- (void)commonUI {
    [super commonUI];
    self.navigationController.navigationBar.backgroundColor = [UIColor whiteColor];
    self.navigationView.backgroundColor = [UIColor whiteColor];

    [self.readButton setTitleColor:[UIColor funChatThemeColor] forState:UIControlStateNormal];
    self.bottonBottomLine.backgroundColor = [UIColor funChatThemeColor];

    [self.readTableView registerClass:[FunUserTableViewCell class] forCellReuseIdentifier:[FunUserTableViewCell description]];
    self.readTableView.rowHeight = 64;

    [self.unreadTableView registerClass:[FunUserTableViewCell class] forCellReuseIdentifier:[FunUserTableViewCell description]];
    self.unreadTableView.rowHeight = 64;

    [self.emptyView setEmptyImageWithName:@"fun_emptyView"];
}

- (void)readButtonEvent:(UIButton *)button {
    [super readButtonEvent:button];
    [self.readButton setTitleColor:[UIColor funChatThemeColor] forState:UIControlStateNormal];
    [self.unreadButton setTitleColor:[UIColor ne_darkText] forState:UIControlStateNormal];
}

- (void)unreadButtonEvent:(UIButton *)button {
    [super unreadButtonEvent:button];
    [self.readButton setTitleColor:[UIColor ne_darkText] forState:UIControlStateNormal];
    [self.unreadButton setTitleColor:[UIColor funChatThemeColor] forState:UIControlStateNormal];
}

@end
