// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "ContactSelectedPageController.h"
#import "FusionContactSelectedController.h"
#import "FusionContactUnCheckCell.h"
#import "NormalContactUIColor.h"
#import <NECommonUIKitOC/NECommonUIKitOC.h>

@interface ContactSelectedPageController ()
@end

@implementation ContactSelectedPageController

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  self.pagingViewControllerTopAnchor.constant = self.topConstant;
}

- (NSArray<NEBaseFusionContactSelectedController *> *)getContentControllers:(NSSet<NSString *> *)filterUsers {
  if (self.childrenControllers.count == 0) {
    FusionContactSelectedController *userSelectController = [[FusionContactSelectedController alloc] initWithFilterIds:filterUsers type:FusionContactTypeUser];
    userSelectController.delegate = self;
    userSelectController.limit = self.limit;
    FusionContactSelectedController *aiUserSelectController = [[FusionContactSelectedController alloc] initWithFilterIds:filterUsers type:FusionContactTypeAIUser];
    aiUserSelectController.delegate = self;
    aiUserSelectController.limit = self.limit;
    [self.childrenControllers addObject:userSelectController];
    [self.childrenControllers addObject:aiUserSelectController];
  }
  return self.childrenControllers;
}

- (void)setupPageContent {
  [super setupPageContent];
  self.view.backgroundColor = [UIColor ne_backcolor];
  self.pagingViewController = [[NEPagingViewController alloc] initWithViewControllers:self.contentControllers];
  [self addChildViewController:self.pagingViewController];
  [self.view addSubview:self.pagingViewController.view];
  self.pagingViewController.view.backgroundColor = [UIColor whiteColor];
  self.pagingViewControllerTopAnchor = [self.pagingViewController.view.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:self.topConstant];
  self.pagingViewControllerTopAnchor.active = YES;
  self.pagingViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
  [NSLayoutConstraint activateConstraints:@[
    [self.pagingViewController.view.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.pagingViewController.view.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [self.pagingViewController.view.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
  ]];
  self.pagingViewController.selectedTextColor = [UIColor contactBlueDividerLineColor];
  self.pagingViewController.textColor = [UIColor contactNormalTextColor];
  self.pagingViewController.indicatorColor = [UIColor contactBlueDividerLineColor];
  self.pagingViewController.indicatorOptions =
    [NEPagingIndicatorOptions visibleWithHeight:2 zIndex:NSIntegerMax spacing:UIEdgeInsetsZero insets:UIEdgeInsetsZero];
  self.pagingViewController.borderOptions =
    [NEPagingBorderOptions visibleWithHeight:1 zIndex:NSIntegerMax insets:UIEdgeInsetsZero];
  [self.pagingViewController didMoveToParentViewController:self];
  [self.selectCollectionView registerClass:[FusionContactUnCheckCell class] forCellWithReuseIdentifier:NSStringFromClass([FusionContactUnCheckCell class])];
}

- (void)setupNavSureItem {
  [super setupNavSureItem];
  self.navigationView.moreButton.backgroundColor = [UIColor clearColor];
  [self.navigationView.moreButton setTitleColor:[UIColor contactFusionSelectButtonBGColor] forState:UIControlStateNormal];
  self.selectedSureButton.backgroundColor = [UIColor clearColor];
  [self.selectedSureButton setTitleColor:[UIColor contactFusionSelectButtonBGColor] forState:UIControlStateNormal];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  id contactInfo = self.selectArray[indexPath.row];
  FusionContactUnCheckCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([FusionContactUnCheckCell class])
                                                                             forIndexPath:indexPath];
  [cell configure:contactInfo];
  return cell ?: [[UICollectionViewCell alloc] init];
}

@end
