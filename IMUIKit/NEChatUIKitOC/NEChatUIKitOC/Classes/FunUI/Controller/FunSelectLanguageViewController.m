// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunSelectLanguageViewController.h"
#import "UIImage+Chat.h"
#import <NEChatKitOC/UIColor+NECommon.h>
#import "FunLanguageCell.h"
#import "FunChatUIColor.h"

@implementation FunSelectLanguageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)setupLanguageUI {
    [super setupLanguageUI];
    self.view.backgroundColor = [UIColor funChatBackgroundColor];
    [self.viewModel setupData:YES];

    UIButton *funBackButton = [UIButton buttonWithType:UIButtonTypeCustom];
    funBackButton.translatesAutoresizingMaskIntoConstraints = NO;
    funBackButton.accessibilityIdentifier = @"id.cancel";
    [funBackButton setImage:[UIImage ne_imageNamed:@"arrowDown"] forState:UIControlStateNormal];
    [funBackButton addTarget:self action:@selector(cancelClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:funBackButton];
    [NSLayoutConstraint activateConstraints:@[
        [funBackButton.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [funBackButton.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [funBackButton.widthAnchor constraintEqualToConstant:50],
        [funBackButton.heightAnchor constraintEqualToConstant:50],
    ]];

    UILabel *funNavTitleLabel = [[UILabel alloc] init];
    funNavTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    funNavTitleLabel.text = chatLocalizable(@"language_title");
    funNavTitleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    funNavTitleLabel.textAlignment = NSTextAlignmentCenter;
    funNavTitleLabel.textColor = [UIColor ne_darkText];
    [self.view addSubview:funNavTitleLabel];
    [NSLayoutConstraint activateConstraints:@[
        [funNavTitleLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:0],
        [funNavTitleLabel.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [funNavTitleLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:0],
        [funNavTitleLabel.heightAnchor constraintEqualToConstant:50],
    ]];

    [self.view addSubview:self.languageTableView];
    [NSLayoutConstraint activateConstraints:@[
        [self.languageTableView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
        [self.languageTableView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
        [self.languageTableView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:58],
        [self.languageTableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];

    [self.languageTableView registerClass:[FunLanguageCell class] forCellReuseIdentifier:NSStringFromClass([NEBaseLanguageCell class])];
}

@end
