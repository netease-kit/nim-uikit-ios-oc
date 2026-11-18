// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunValidationPageController.h"
#import <NEChatKit/IMKitConfigCenter.h>
#import <NEChatKit/UIColor+NECommon.h>
#import "FunAddApplicationViewController.h"
#import "FunTeamJoinActionViewController.h"
#import "FunContactUIColor.h"
#import "ContactConst.h"
#import <NEBaseUIKitOC/NEBaseUIKitOC.h>

@implementation FunValidationPageController

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
  NSDictionary *textAttributes = @{NSFontAttributeName: [UIFont systemFontOfSize:16 weight:UIFontWeightRegular]};

  [clearItem setTitleTextAttributes:textAttributes forState:UIControlStateNormal];
  self.navigationItem.rightBarButtonItem = clearItem;

  self.navigationView.moreButton.titleLabel.font = [UIFont systemFontOfSize:16];
}

- (void)getContentControllers {
  if (self.contentControllers.count == 0) {
    FunAddApplicationViewController *funAddApplicationViewController = [[FunAddApplicationViewController alloc] init];
    [self.contentControllers addObject:funAddApplicationViewController];

    if ([IMKitConfigCenter shared].enableTeamJoinAgreeModelAuth) {
      FunTeamJoinActionViewController *funTeamJoinActionViewController = [[FunTeamJoinActionViewController alloc] init];
      [self.contentControllers addObject:funTeamJoinActionViewController];
    }
  }
}

- (void)setupPageContent {
  [super setupPageContent];
  self.pagingViewController.selectedTextColor = [UIColor funContactGreenDividerLineColor];
  self.pagingViewController.textColor = [UIColor funContactNormalTextColor];
  self.pagingViewController.indicatorColor = [UIColor funContactGreenDividerLineColor];
}

@end
