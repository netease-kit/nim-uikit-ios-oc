// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "ValidationPageController.h"
#import <NEChatKit/IMKitConfigCenter.h>
#import <NEChatKit/UIColor+NECommon.h>
#import "AddApplicationViewController.h"
#import "TeamJoinActionViewController.h"
#import "ContactConst.h"
#import "NormalContactUIColor.h"

@implementation ValidationPageController

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  self.pagingViewControllerTopAnchor.constant = self.topConstant;
}

- (void)initNav {
  [super initNav];
  UIBarButtonItem *clearItem = [[UIBarButtonItem alloc] initWithTitle:contactLocalizable(@"clear")
                                                               style:UIBarButtonItemStyleDone
                                                              target:self
                                                              action:@selector(toSetting)];
  clearItem.tintColor = [UIColor ne_darkText];
  NSMutableDictionary *textAttributes = [NSMutableDictionary dictionary];
  textAttributes[NSFontAttributeName] = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];

  [clearItem setTitleTextAttributes:textAttributes forState:UIControlStateNormal];
  self.navigationItem.rightBarButtonItem = clearItem;

  self.navigationView.moreButton.titleLabel.font = [UIFont systemFontOfSize:16];
}

- (void)getContentControllers {
  if (self.contentControllers.count == 0) {
    AddApplicationViewController *addApplicationViewController = [[AddApplicationViewController alloc] init];
    [self.contentControllers addObject:addApplicationViewController];

    if ([IMKitConfigCenter shared].enableTeamJoinAgreeModelAuth) {
      TeamJoinActionViewController *teamJoinActionViewController = [[TeamJoinActionViewController alloc] init];
      [self.contentControllers addObject:teamJoinActionViewController];
    }
  }
}

- (void)setupPageContent {
  [super setupPageContent];
  self.pagingViewController.selectedTextColor = [UIColor contactBlueDividerLineColor];
  self.pagingViewController.textColor = [UIColor contactNormalTextColor];
  self.pagingViewController.indicatorColor = [UIColor contactBlueDividerLineColor];
}

@end
