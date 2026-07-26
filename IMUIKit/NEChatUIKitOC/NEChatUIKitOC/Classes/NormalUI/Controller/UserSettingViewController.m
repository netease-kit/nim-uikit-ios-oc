// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "UserSettingViewController.h"
#import "UserSettingSwitchCell.h"
#import "UserSettingSelectCell.h"
#import "ChatNavigationView.h"
#import <NEChatKit/IMKitConfigCenter.h>

@implementation UserSettingViewController

- (instancetype)initWithUserId:(NSString *)userId {
    self = [super initWithUserId:userId];
    if (self) {
        self.cellClassDic = @{
            @(UserSettingTypeSwitchType): [UserSettingSwitchCell class],
            @(UserSettingTypeSelectType): [UserSettingSelectCell class],
        };
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    return self;
}

- (void)setupUI {
    [super setupUI];
    self.navigationView.backgroundColor = UIColor.whiteColor;
    self.navigationController.navigationBar.backgroundColor = UIColor.whiteColor;
    self.userHeaderView.layer.cornerRadius = [IMKitConfigCenter shared].enableTeam ? 21.0 : 30.0;
}

@end
