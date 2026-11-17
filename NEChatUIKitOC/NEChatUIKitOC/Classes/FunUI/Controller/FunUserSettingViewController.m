// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunUserSettingViewController.h"
#import "FunUserSettingSwitchCell.h"
#import "FunUserSettingSelectCell.h"
#import "FunP2PChatViewController.h"
#import <NEChatKit/IMKitConfigCenter.h>
#import "NEChatUIConstant.h"
#import "FunChatUIColor.h"

@implementation FunUserSettingViewController

- (instancetype)initWithUserId:(NSString *)userId {
    self = [super initWithUserId:userId];
    if (self) {
        self.cellClassDic = [@{
            @(UserSettingTypeSwitchType): [FunUserSettingSwitchCell class],
            @(UserSettingTypeSelectType): [FunUserSettingSelectCell class],
        } mutableCopy];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor funChatBackgroundColor];
    for (UserSettingCellModel *cellModel in self.viewModel.cellDatas) {
        cellModel.cornerType = CornerTypeNone;
    }
}

- (void)setupUI {
    [super setupUI];
    self.navigationController.navigationBar.backgroundColor = [UIColor whiteColor];
    self.navigationView.backgroundColor = [UIColor whiteColor];
    self.navigationView.titleBarBottomLine.hidden = NO;
    self.userHeaderView.layer.cornerRadius = 4.0;
    [self.addButton setImage:chatLoadImage(@"fun_setting_add") forState:UIControlStateNormal];
    self.contentTable.rowHeight = 56;
}

- (UIView *)headerView {
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 117)];
    headerView.backgroundColor = [UIColor clearColor];
    UIView *cornerBackView = [[UIView alloc] init];
    cornerBackView.backgroundColor = [UIColor whiteColor];
    cornerBackView.translatesAutoresizingMaskIntoConstraints = NO;
    [headerView addSubview:cornerBackView];
    [NSLayoutConstraint activateConstraints:@[
        [cornerBackView.bottomAnchor constraintEqualToAnchor:headerView.bottomAnchor constant:-8],
        [cornerBackView.leftAnchor constraintEqualToAnchor:headerView.leftAnchor],
        [cornerBackView.rightAnchor constraintEqualToAnchor:headerView.rightAnchor],
        [cornerBackView.heightAnchor constraintEqualToConstant:109.0],
    ]];

    [cornerBackView addSubview:self.userHeaderView];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] init];
    [self.userHeaderView addGestureRecognizer:tap];
    tap.numberOfTapsRequired = 1;
    tap.numberOfTouchesRequired = 1;

    NSString *url = self.viewModel.userInfo.user.avatar;
    NSString *name = [self.viewModel.userInfo shortName:YES count:2] ?: @"";
    NSString *accountId = self.viewModel.userInfo.user.accountId ?: @"";
    [self.userHeaderView configHeadData:url name:name uid:accountId];

    self.nameLabel.text = [self.viewModel.userInfo showName];
    [cornerBackView addSubview:self.nameLabel];

    if ([self shouldShowAddMemberButton]) {
        [NSLayoutConstraint activateConstraints:@[
            [self.userHeaderView.leftAnchor constraintEqualToAnchor:cornerBackView.leftAnchor constant:22],
            [self.userHeaderView.topAnchor constraintEqualToAnchor:cornerBackView.topAnchor constant:22],
            [self.userHeaderView.widthAnchor constraintEqualToConstant:50],
            [self.userHeaderView.heightAnchor constraintEqualToConstant:50],
        ]];

        self.nameLabel.font = [NEConstant defaultTextFont:12];
        self.nameLabel.textAlignment = NSTextAlignmentCenter;
        [NSLayoutConstraint activateConstraints:@[
            [self.nameLabel.topAnchor constraintEqualToAnchor:self.userHeaderView.bottomAnchor constant:3.0],
            [self.nameLabel.centerXAnchor constraintEqualToAnchor:self.userHeaderView.centerXAnchor],
            [self.nameLabel.widthAnchor constraintEqualToAnchor:self.userHeaderView.widthAnchor],
        ]];

        [self.addButton addTarget:self action:@selector(createDiscuss) forControlEvents:UIControlEventTouchUpInside];
        [cornerBackView addSubview:self.addButton];
        [NSLayoutConstraint activateConstraints:@[
            [self.addButton.leftAnchor constraintEqualToAnchor:self.userHeaderView.rightAnchor constant:20.0],
            [self.addButton.topAnchor constraintEqualToAnchor:self.userHeaderView.topAnchor],
            [self.addButton.widthAnchor constraintEqualToConstant:50.0],
            [self.addButton.heightAnchor constraintEqualToConstant:50.0],
        ]];
    } else {
        [NSLayoutConstraint activateConstraints:@[
            [self.userHeaderView.leftAnchor constraintEqualToAnchor:cornerBackView.leftAnchor constant:16],
            [self.userHeaderView.centerYAnchor constraintEqualToAnchor:cornerBackView.centerYAnchor],
            [self.userHeaderView.widthAnchor constraintEqualToConstant:60],
            [self.userHeaderView.heightAnchor constraintEqualToConstant:60],
        ]];

        self.nameLabel.font = [NEConstant defaultTextFont:16];
        self.nameLabel.textAlignment = NSTextAlignmentLeft;
        [NSLayoutConstraint activateConstraints:@[
            [self.nameLabel.leftAnchor constraintEqualToAnchor:self.userHeaderView.rightAnchor constant:16.0],
            [self.nameLabel.rightAnchor constraintEqualToAnchor:cornerBackView.rightAnchor],
            [self.nameLabel.centerYAnchor constraintEqualToAnchor:self.userHeaderView.centerYAnchor],
        ]];
    }

    return headerView;
}

- (NSArray<UIViewController *> *)filterStackViewController {
    NSMutableArray *filtered = [NSMutableArray array];
    for (UIViewController *vc in self.navigationController.viewControllers) {
        if ([vc isKindOfClass:[FunP2PChatViewController class]] ||
            [vc isKindOfClass:[FunUserSettingViewController class]]) {
            continue;
        }
        [filtered addObject:vc];
    }
    return filtered;
}

- (void)didLoadData {
    [self.viewModel setFunType];
}

@end
