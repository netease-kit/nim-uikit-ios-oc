// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "TeamAvatarViewController.h"
#import <NEBaseUIKitOC/NEAdaptiveDeviceGate.h>
#import "TeamDefaultIconCell.h"
#import "TeamConstant.h"
#import <NEChatKit/NECommonLoader.h>
#import <NEChatKit/NEConstant.h>
#import <NEChatKit/UIColor+NECommon.h>
#import <NEBaseUIKitOC/NECommonUIConstant.h>
#import <NEBaseUIKitOC/NEUserHeaderView.h>

@implementation TeamAvatarViewController

- (void)setupUI {
  [super setupUI];
  self.headerView.layer.cornerRadius = 40.0;

  [self addRightActionWithTitle:NETeamUIKitLocalizable(@"save") action:@selector(savePhoto) target:self];
  if (![self getChangePermission]) {
    self.rightNavButton.hidden = YES;
    self.navigationView.moreButton.hidden = YES;
    self.navigationItem.rightBarButtonItem = nil;
  }
  self.view.backgroundColor = UIColor.ne_lightBackgroundColor;
  self.navigationView.backgroundColor = UIColor.ne_lightBackgroundColor;
  [self.navigationView setBackButtonTitle:commonLocalizable(@"cancel")];
  [self.navigationView.backButton setTitleColor:UIColor.ne_greyText forState:UIControlStateNormal];
  self.navigationController.navigationBar.backgroundColor = UIColor.ne_lightBackgroundColor;

  self.headerBackView.layer.cornerRadius = 8.0;
  [NSLayoutConstraint activateConstraints:@[
    [self.headerBackView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:12.0 + NEUIKitAdaptiveNavigationAndStatusHeight()],
    [self.headerBackView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:20.0],
    [self.headerBackView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant:-20.0],
    [self.headerBackView.heightAnchor constraintEqualToConstant:128.0],
  ]];

  [NSLayoutConstraint activateConstraints:@[
    [self.photoImageView.rightAnchor constraintEqualToAnchor:self.headerView.rightAnchor],
    [self.photoImageView.bottomAnchor constraintEqualToAnchor:self.headerView.bottomAnchor],
  ]];

  self.defaultHeaderBackView.layer.cornerRadius = 8.0;
  [NSLayoutConstraint activateConstraints:@[
    [self.defaultHeaderBackView.leftAnchor constraintEqualToAnchor:self.headerBackView.leftAnchor],
    [self.defaultHeaderBackView.rightAnchor constraintEqualToAnchor:self.headerBackView.rightAnchor],
    [self.defaultHeaderBackView.topAnchor constraintEqualToAnchor:self.headerBackView.bottomAnchor constant:12.0],
    [self.defaultHeaderBackView.heightAnchor constraintEqualToConstant:114.0],
  ]];

  [NSLayoutConstraint activateConstraints:@[
    [self.tagLabel.leftAnchor constraintEqualToAnchor:self.defaultHeaderBackView.leftAnchor constant:16.0],
    [self.tagLabel.topAnchor constraintEqualToAnchor:self.defaultHeaderBackView.topAnchor constant:15.0],
  ]];

  [self.iconsCollectionView registerClass:TeamDefaultIconCell.class forCellWithReuseIdentifier:NSStringFromClass(TeamDefaultIconCell.class)];
  [NSLayoutConstraint activateConstraints:@[
    [self.iconsCollectionView.topAnchor constraintEqualToAnchor:self.tagLabel.bottomAnchor constant:16.0],
    [self.iconsCollectionView.leftAnchor constraintEqualToAnchor:self.defaultHeaderBackView.leftAnchor constant:18.0],
    [self.iconsCollectionView.rightAnchor constraintEqualToAnchor:self.defaultHeaderBackView.rightAnchor constant:-18.0],
    [self.iconsCollectionView.heightAnchor constraintEqualToConstant:48.0],
  ]];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  TeamDefaultIconCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(TeamDefaultIconCell.class)
                                                                        forIndexPath:indexPath];
  cell.iconImageView.image = [NETeamUIKitLoader() loadImage:[NSString stringWithFormat:@"icon_%ld", (long)indexPath.row]];
  cell.iconImageView.accessibilityIdentifier = [NSString stringWithFormat:@"id.default%ld", (long)indexPath.row + 1];
  return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
  (void)collectionViewLayout;
  return CGSizeMake(48.0, 48.0);
}

@end
