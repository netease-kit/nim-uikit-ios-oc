// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "SelectLanguageViewController.h"
#import "UIImage+Chat.h"
#import <NEChatKit/UIColor+NECommon.h>
#import "LanguageCell.h"

@implementation SelectLanguageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)setupLanguageUI {
    [super setupLanguageUI];
    [self.viewModel setupData:NO];

    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    backButton.translatesAutoresizingMaskIntoConstraints = NO;
    backButton.accessibilityIdentifier = @"id.cancel";
    [backButton addTarget:self action:@selector(cancelClick) forControlEvents:UIControlEventTouchUpInside];
    [backButton setImage:[UIImage ne_imageNamed:@"arrowDown"] forState:UIControlStateNormal];
    backButton.titleLabel.textColor = UIColor.ne_greyText;
    backButton.titleLabel.font = [UIFont systemFontOfSize:18.0];
    [self.view addSubview:backButton];
    [NSLayoutConstraint activateConstraints:@[
        [backButton.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [backButton.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [backButton.widthAnchor constraintEqualToConstant:50],
        [backButton.heightAnchor constraintEqualToConstant:50],
    ]];

    UILabel *navTitleLabel = [[UILabel alloc] init];
    navTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    navTitleLabel.text = chatLocalizable(@"language_title");
    navTitleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    navTitleLabel.textAlignment = NSTextAlignmentCenter;
    navTitleLabel.textColor = UIColor.ne_darkText;
    [self.view addSubview:navTitleLabel];
    [NSLayoutConstraint activateConstraints:@[
        [navTitleLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:0],
        [navTitleLabel.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [navTitleLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:0],
        [navTitleLabel.heightAnchor constraintEqualToConstant:50],
    ]];

    [self.view addSubview:self.languageTableView];
    [NSLayoutConstraint activateConstraints:@[
        [self.languageTableView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
        [self.languageTableView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
        [self.languageTableView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:58],
        [self.languageTableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];
    self.languageTableView.backgroundColor = UIColor.clearColor;

    [self.languageTableView registerClass:[LanguageCell class] forCellReuseIdentifier:NSStringFromClass([NEBaseLanguageCell class])];
}

@end
