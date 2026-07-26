// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunTeamAvatarViewController.h"
#import "FunTeamDefaultIconCell.h"
#import "FunTeamUIColor.h"
#import "TeamRouter.h"
#import "TeamConstant.h"
#import <NEChatUIKitOC/ChatUIConfig.h>
#import <NEChatKit/NEResultModel.h>
#import <NEChatKit/NECommonLoader.h>
#import <NECommonUIKitOC/NECustomActionSheetController.h>
#import <NECommonUIKitOC/NECommonUIConstant.h>
#import <NECommonUIKitOC/NEUserHeaderView.h>
#import <NEChatKit/NEConstant.h>
#import <Photos/Photos.h>

static NSInteger const NETwitterAvatarImageCountLimit = 1;

@implementation FunTeamAvatarViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    self.iconUrls = [TeamRouter iconUrlsFun];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    self.iconUrls = [TeamRouter iconUrlsFun];
  }
  return self;
}

- (void)setupUI {
  [super setupUI];
  self.headerView.layer.cornerRadius = 6.4;
  self.navigationController.navigationBar.backgroundColor = UIColor.whiteColor;
  [self addRightActionWithTitle:NETeamUIKitLocalizable(@"save")
                         action:@selector(savePhoto)
                         target:self
                          color:UIColor.funTeamThemeColor];
  if (![self getChangePermission]) {
    self.rightNavButton.hidden = YES;
    self.navigationView.moreButton.hidden = YES;
    self.navigationItem.rightBarButtonItem = nil;
  }
  [self.navigationView.moreButton setTitleColor:UIColor.funTeamThemeColor forState:UIControlStateNormal];
  self.navigationView.backgroundColor = UIColor.whiteColor;
  self.view.backgroundColor = UIColor.funTeamBackgroundColor;

  [NSLayoutConstraint activateConstraints:@[
    [self.headerBackView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:NEConstant.navigationAndStatusHeight],
    [self.headerBackView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.headerBackView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [self.headerBackView.heightAnchor constraintEqualToConstant:128.0],
  ]];

  [NSLayoutConstraint activateConstraints:@[
    [self.photoImageView.rightAnchor constraintEqualToAnchor:self.headerView.rightAnchor],
    [self.photoImageView.bottomAnchor constraintEqualToAnchor:self.headerView.bottomAnchor],
  ]];

  [NSLayoutConstraint activateConstraints:@[
    [self.defaultHeaderBackView.leftAnchor constraintEqualToAnchor:self.headerBackView.leftAnchor],
    [self.defaultHeaderBackView.rightAnchor constraintEqualToAnchor:self.headerBackView.rightAnchor],
    [self.defaultHeaderBackView.topAnchor constraintEqualToAnchor:self.headerBackView.bottomAnchor constant:8.0],
    [self.defaultHeaderBackView.heightAnchor constraintEqualToConstant:124.0],
  ]];

  [NSLayoutConstraint activateConstraints:@[
    [self.tagLabel.leftAnchor constraintEqualToAnchor:self.defaultHeaderBackView.leftAnchor constant:16.0],
    [self.tagLabel.topAnchor constraintEqualToAnchor:self.defaultHeaderBackView.topAnchor constant:16.0],
    [self.tagLabel.heightAnchor constraintEqualToConstant:18.0],
  ]];

  [self.iconsCollectionView registerClass:FunTeamDefaultIconCell.class forCellWithReuseIdentifier:NSStringFromClass(FunTeamDefaultIconCell.class)];
  [NSLayoutConstraint activateConstraints:@[
    [self.iconsCollectionView.topAnchor constraintEqualToAnchor:self.tagLabel.bottomAnchor],
    [self.iconsCollectionView.leftAnchor constraintEqualToAnchor:self.defaultHeaderBackView.leftAnchor constant:16.0],
    [self.iconsCollectionView.rightAnchor constraintEqualToAnchor:self.defaultHeaderBackView.rightAnchor constant:-16.0],
    [self.iconsCollectionView.heightAnchor constraintEqualToConstant:90.0],
  ]];
}

- (void)uploadPhoto {
  if (![self getChangePermission]) {
    return;
  }

  __weak typeof(self) weakSelf = self;
  NEChatInputPhotoClickBlock callback = [ChatUIConfig shared].chatInputPhotoClick;
  if (callback) {
    NECustomAlertAction *takingPicturesAction = [NECustomAlertAction actionWithTitle:commonLocalizable(@"take_picture") handler:^{
      [weakSelf goCameraWithDelegate:weakSelf editing:YES];
    }];
    NECustomAlertAction *photoAction = [NECustomAlertAction actionWithTitle:commonLocalizable(@"select_from_album") handler:^{
      __strong typeof(weakSelf) strongSelf = weakSelf;
      if (!strongSelf) {
        return;
      }
      callback(strongSelf, NEMediaTypeImage, NETwitterAvatarImageCountLimit, ^(NSArray<NEResultModel *> *results, __unused BOOL isOriginal) {
        for (NEResultModel *model in results) {
          if (model.asset.mediaType == PHAssetMediaTypeVideo) {
            [strongSelf showToast:commonLocalizable(@"only_support_choose_image")];
            return;
          }
          if (model.asset.mediaType == PHAssetMediaTypeImage && results.count > NETwitterAvatarImageCountLimit) {
            [strongSelf showToast:[NSString stringWithFormat:commonLocalizable(@"image_count_over_limit"), (int)NETwitterAvatarImageCountLimit]];
            return;
          }
          [strongSelf uploadHeadImage:model.image];
        }
      });
    }];
    [self showCustomActionSheet:@[ takingPicturesAction, photoAction ]];
    return;
  }

  [self showCustomBottomAlertWithDelegate:self editing:YES checkNetwork:YES];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  FunTeamDefaultIconCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(FunTeamDefaultIconCell.class)
                                                                            forIndexPath:indexPath];
  cell.iconImageView.image = [NETeamUIKitLoader() loadImage:[NSString stringWithFormat:@"fun_icon_%ld", (long)indexPath.row]];
  cell.iconImageView.accessibilityIdentifier = [NSString stringWithFormat:@"id.default%ld", (long)indexPath.row + 1];
  return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
  (void)collectionView;
  (void)collectionViewLayout;
  CGFloat space = (NEConstant.screenWidth - 312.0) / 4.0;
  if (indexPath.row == 0) {
    return CGSizeMake(56.0, 56.0);
  }
  return CGSizeMake(56.0 + space, 56.0);
}

@end
