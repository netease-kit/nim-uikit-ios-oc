// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "ReadViewController.h"
#import "ChatNavigationView.h"
#import <NEChatKitOC/UIColor+NECommon.h>
#import "UserTableViewCell.h"

@implementation ReadViewController

- (instancetype)initWithMessage:(V2NIMMessage *)message teamId:(NSString *)teamId {
    self = [super initWithMessage:message teamId:teamId];
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationView.backgroundColor = UIColor.whiteColor;
    self.navigationController.navigationBar.backgroundColor = UIColor.whiteColor;
}

- (void)commonUI {
    [super commonUI];
    self.navigationView.titleBarBottomLine.hidden = NO;
    [self.readButton setTitleColor:UIColor.ne_normalTheme forState:UIControlStateNormal];
    self.bottonBottomLine.backgroundColor = UIColor.ne_normalTheme;

    [self.readTableView registerClass:[UserTableViewCell class] forCellReuseIdentifier:NSStringFromClass([UserBaseTableViewCell class])];
    self.readTableView.rowHeight = 62;

    [self.unreadTableView registerClass:[UserTableViewCell class] forCellReuseIdentifier:NSStringFromClass([UserBaseTableViewCell class])];
    self.unreadTableView.rowHeight = 62;
}

- (void)readButtonEvent:(UIButton *)button {
    [super readButtonEvent:button];
    [self.readButton setTitleColor:UIColor.ne_normalTheme forState:UIControlStateNormal];
    [self.unreadButton setTitleColor:UIColor.ne_darkText forState:UIControlStateNormal];
}

- (void)unreadButtonEvent:(UIButton *)button {
    [super unreadButtonEvent:button];
    [self.readButton setTitleColor:UIColor.ne_darkText forState:UIControlStateNormal];
    [self.unreadButton setTitleColor:UIColor.ne_normalTheme forState:UIControlStateNormal];
}

@end
