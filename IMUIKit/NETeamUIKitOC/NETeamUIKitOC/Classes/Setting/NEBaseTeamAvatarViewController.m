// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseTeamAvatarViewController.h"
#import "TeamConstant.h"
#import "TeamRouter.h"
#import <NEChatKitOC/NEChatKitOC.h>
#import <NEChatUIKitOC/ChatUIConfig.h>
#import <NEChatKitOC/NEChatDetectNetworkTool.h>
#import <NEChatKitOC/NECommonLoader.h>
#import <NEChatKitOC/NEConstant.h>
#import <NEChatKitOC/NSObject+NECommon.h>
#import <NEChatKitOC/UIColor+NECommon.h>
#import <NECommonUIKitOC/NEUserHeaderView.h>
#import <NECommonUIKitOC/UIView+YXToast.h>
#import <NEChatKitOC/IMKitClient.h>
#import <NEChatKitOC/NEALog.h>
#import <NEChatKitOC/NECoreIM2Constant.h>
#import <NEChatKitOC/NEPathUtils.h>
#import <Photos/Photos.h>
#import <SDWebImage/UIImageView+WebCache.h>

@interface NEBaseTeamAvatarViewController ()
@property (nonatomic, strong, readwrite) NEUserHeaderView *headerView;
@property (nonatomic, strong, readwrite) UIButton *clickButton;
@property (nonatomic, strong, readwrite) UICollectionView *iconsCollectionView;
@end

@implementation NEBaseTeamAvatarViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    _repo = [TeamRepo shared];
    _iconUrls = [TeamRouter iconUrls];
    _viewModel = [[TeamAvatarViewModel alloc] init];
    _headerUrl = @"";
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    _repo = [TeamRepo shared];
    _iconUrls = [TeamRouter iconUrls];
    _viewModel = [[TeamAvatarViewModel alloc] init];
    _headerUrl = @"";
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  __weak typeof(self) weakSelf = self;
  [self.viewModel getCurrentUserTeamMember:self.team.teamId completion:^(NSError * _Nullable error) {
    [weakSelf setupUI];
    if (error) {
      [weakSelf.view ne_makeToast:NETeamUIKitErrorToast(error)];
    }
  }];
}

- (void)setupUI {
  self.title = NETeamUIKitLocalizable(@"modify_headImage");
  [self addRightActionWithTitle:NETeamUIKitLocalizable(@"save") action:@selector(savePhoto) target:self];
  [self.navigationView setMoreButtonTitle:NETeamUIKitLocalizable(@"save")];
  [self.navigationView addMoreButtonTarget:self selector:@selector(savePhoto)];
  self.view.backgroundColor = UIColor.ne_lightBackgroundColor;

  self.headerBackView.backgroundColor = UIColor.whiteColor;
  self.headerBackView.clipsToBounds = YES;
  self.headerBackView.translatesAutoresizingMaskIntoConstraints = NO;
  [self.view addSubview:self.headerBackView];

  [self.headerBackView addSubview:self.headerView];
  [NSLayoutConstraint activateConstraints:@[
    [self.headerView.centerXAnchor constraintEqualToAnchor:self.headerBackView.centerXAnchor],
    [self.headerView.centerYAnchor constraintEqualToAnchor:self.headerBackView.centerYAnchor],
    [self.headerView.heightAnchor constraintEqualToConstant:80.0],
    [self.headerView.widthAnchor constraintEqualToConstant:80.0],
  ]];

  NSString *url = self.team.avatar ?: @"";
  if (url.length > 0) {
    [self.headerView sd_setImageWithURL:[NSURL URLWithString:url] completed:nil];
    self.headerUrl = url;
  }

  self.photoImageView.translatesAutoresizingMaskIntoConstraints = NO;
  self.photoImageView.image = [NETeamUIKitLoader() loadImage:@"photo"];
  self.photoImageView.accessibilityIdentifier = @"id.camera";
  [self.headerBackView addSubview:self.photoImageView];

  [self.headerBackView addSubview:self.clickButton];
  [self.clickButton addTarget:self action:@selector(uploadPhoto) forControlEvents:UIControlEventTouchUpInside];
  [NSLayoutConstraint activateConstraints:@[
    [self.clickButton.leftAnchor constraintEqualToAnchor:self.headerView.leftAnchor],
    [self.clickButton.topAnchor constraintEqualToAnchor:self.headerView.topAnchor],
    [self.clickButton.bottomAnchor constraintEqualToAnchor:self.headerView.bottomAnchor],
    [self.clickButton.rightAnchor constraintEqualToAnchor:self.headerView.rightAnchor constant:10.0],
  ]];

  self.defaultHeaderBackView.translatesAutoresizingMaskIntoConstraints = NO;
  self.defaultHeaderBackView.clipsToBounds = YES;
  self.defaultHeaderBackView.backgroundColor = UIColor.whiteColor;
  [self.view addSubview:self.defaultHeaderBackView];

  self.tagLabel.translatesAutoresizingMaskIntoConstraints = NO;
  self.tagLabel.text = NETeamUIKitLocalizable(@"default_icon");
  self.tagLabel.font = [NEConstant defaultTextFont:16.0];
  self.tagLabel.textColor = [NEConstant hexRGB:0x333333];
  [self.defaultHeaderBackView addSubview:self.tagLabel];
  [self.defaultHeaderBackView addSubview:self.iconsCollectionView];

  for (NSInteger index = 0; index < self.iconUrls.count; index++) {
    NSString *itemUrl = self.iconUrls[index];
    if ([itemUrl isEqualToString:self.headerUrl]) {
      NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
      [self.iconsCollectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionRight];
    }
  }

  if (![self getChangePermission]) {
    self.rightNavButton.hidden = YES;
    self.navigationView.moreButton.hidden = YES;
    self.photoImageView.hidden = YES;
    self.defaultHeaderBackView.hidden = YES;
  }
}

- (BOOL)getChangePermission {
  NSString *ownerId = self.team.ownerAccountId ?: @"";
  if (ownerId.length > 0 && [[IMKitClient instance] isMe:ownerId]) {
    return YES;
  }
  if (self.team.updateInfoMode == V2NIM_TEAM_UPDATE_INFO_MODE_ALL) {
    return YES;
  }
  if (self.viewModel.currentTeamMember.memberRole == V2NIM_TEAM_MEMBER_ROLE_MANAGER) {
    return YES;
  }
  return NO;
}

- (void)uploadPhoto {
  if (![self getChangePermission]) {
    return;
  }

  NEChatInputPhotoClickBlock callback = [ChatUIConfig shared].chatInputPhotoClick;
  if (callback) {
    __weak typeof(self) weakSelf = self;
    UIAlertAction *takingPicturesAction = [UIAlertAction actionWithTitle:commonLocalizable(@"take_picture")
                                                                   style:UIAlertActionStyleDefault
                                                                 handler:^(__unused UIAlertAction * _Nonnull action) {
      [weakSelf goCameraWithDelegate:weakSelf editing:YES];
    }];

    UIAlertAction *photoAction = [UIAlertAction actionWithTitle:commonLocalizable(@"select_from_album")
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(__unused UIAlertAction * _Nonnull action) {
      __strong typeof(weakSelf) strongSelf = weakSelf;
      if (!strongSelf) {
        return;
      }
      callback(strongSelf, NEMediaTypeImage, avatarImageCountLimit, ^(NSArray<NEResultModel *> *results, __unused BOOL isOriginal) {
        for (NEResultModel *model in results) {
          if (model.asset.mediaType == PHAssetMediaTypeVideo) {
            [strongSelf showToast:commonLocalizable(@"only_support_choose_image")];
            return;
          }
          if (model.asset.mediaType == PHAssetMediaTypeImage && results.count > avatarImageCountLimit) {
            [strongSelf showToast:[NSString stringWithFormat:commonLocalizable(@"image_count_over_limit"), (int)avatarImageCountLimit]];
            return;
          }
          [strongSelf uploadHeadImage:model.image];
        }
      });
    }];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:commonLocalizable(@"cancel")
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    [self showActionSheet:@[ takingPicturesAction, photoAction, cancelAction ]];
    return;
  }

  [self showBottomAlertWithDelegate:self
                            editing:YES
                       checkNetwork:YES
                      clickedAction:nil
                  presentCompletion:nil];
}

- (void)savePhoto {
  if (![[NEChatDetectNetworkTool shareInstance] isNetworkReachability]) {
    [self showToast:commonLocalizable(@"network_error")];
    return;
  }

  NSString *teamId = self.team.teamId ?: @"";
  if (teamId.length <= 0) {
    return;
  }

  __weak typeof(self) weakSelf = self;
  [self.view ne_makeToastActivity:NEToastPositionCenter];
  [self.viewModel updateTeamAvatar:self.headerUrl
                            teamId:teamId
                    antispamConfig:nil
                        completion:^(NSError * _Nullable error) {
    [NEALog infoLog:[NSString stringWithFormat:@"%@ %@", NETeamUIKitModuleName, [[self class] className]]
               desc:[NSString stringWithFormat:@"%@CALLBACK %@", NSStringFromSelector(_cmd), error.localizedDescription ?: @"no error"]];
    [weakSelf.view ne_hideToastActivity];
    if (error) {
      if (error.code == protocolSendFailed) {
        [weakSelf showToast:commonLocalizable(@"network_error")];
      } else if (error.code == noPermissionOperationCode) {
        [weakSelf showToast:NETeamUIKitLocalizable(@"no_permission_tip")];
      } else {
        [weakSelf showToast:commonLocalizable(@"failed_operation")];
      }
      return;
    }

    if (weakSelf.block) {
      weakSelf.block();
    }
    [weakSelf.navigationController popViewControllerAnimated:YES];
  }];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  (void)collectionView;
  (void)section;
  return 5;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  (void)collectionView;
  (void)indexPath;
  return [[UICollectionViewCell alloc] init];
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
  (void)collectionView;
  (void)collectionViewLayout;
  (void)indexPath;
  return CGSizeZero;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
  (void)collectionView;
  if (self.iconUrls.count > indexPath.row) {
    self.headerUrl = self.iconUrls[indexPath.row];
    [self.headerView sd_setImageWithURL:[NSURL URLWithString:self.headerUrl] completed:nil];
  }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
  UIImage *image = info[UIImagePickerControllerEditedImage];
  if (!image) {
    image = info[UIImagePickerControllerOriginalImage];
  }
  if (image) {
    [self uploadHeadImage:image];
  }
  [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)uploadHeadImage:(UIImage *)image {
  if (![[NEChatDetectNetworkTool shareInstance] isNetworkReachability]) {
    [self showToast:commonLocalizable(@"network_error")];
    return;
  }

  NSData *imageData = UIImageJPEGRepresentation(image, 0.6);
  NSString *filePath = [NEPathUtils getDirectoryForDocuments:[NSString stringWithFormat:@"%@image/", imkitDir]];
  if (imageData.length <= 0 || filePath.length <= 0) {
    return;
  }

  [self.view ne_makeToastActivity:NEToastPositionCenter];
  filePath = [filePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_avatar.jpg", self.team.teamId ?: @"team"]];
  if (![imageData writeToFile:filePath atomically:YES]) {
    [self.view ne_hideToastActivity];
    return;
  }

  __weak typeof(self) weakSelf = self;
  V2NIMUploadFileTask *fileTask = [self.viewModel createTask:filePath];
  [self.viewModel uploadImageFile:fileTask progress:nil completion:^(NSString * _Nullable urlString, NSError * _Nullable error) {
    if (!error) {
      weakSelf.headerView.image = image;
      if (urlString.length > 0) {
        weakSelf.headerUrl = urlString;
      }
    }
    [weakSelf.view ne_hideToastActivity];
  }];
}

- (NEUserHeaderView *)headerView {
  if (!_headerView) {
    _headerView = [[NEUserHeaderView alloc] initWithFrame:CGRectZero];
    _headerView.translatesAutoresizingMaskIntoConstraints = NO;
    _headerView.clipsToBounds = YES;
    _headerView.userInteractionEnabled = YES;
    _headerView.accessibilityIdentifier = @"id.icon";
  }
  return _headerView;
}

- (UIView *)headerBackView {
  if (!_headerBackView) {
    _headerBackView = [[UIView alloc] initWithFrame:CGRectZero];
  }
  return _headerBackView;
}

- (UIImageView *)photoImageView {
  if (!_photoImageView) {
    _photoImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
  }
  return _photoImageView;
}

- (UIView *)defaultHeaderBackView {
  if (!_defaultHeaderBackView) {
    _defaultHeaderBackView = [[UIView alloc] initWithFrame:CGRectZero];
  }
  return _defaultHeaderBackView;
}

- (UILabel *)tagLabel {
  if (!_tagLabel) {
    _tagLabel = [[UILabel alloc] initWithFrame:CGRectZero];
  }
  return _tagLabel;
}

- (UIButton *)clickButton {
  if (!_clickButton) {
    _clickButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _clickButton.translatesAutoresizingMaskIntoConstraints = NO;
    _clickButton.backgroundColor = UIColor.clearColor;
  }
  return _clickButton;
}

- (UICollectionView *)iconsCollectionView {
  if (!_iconsCollectionView) {
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    flowLayout.minimumLineSpacing = 0.0;
    flowLayout.minimumInteritemSpacing = 0.0;
    _iconsCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
    _iconsCollectionView.translatesAutoresizingMaskIntoConstraints = NO;
    _iconsCollectionView.delegate = self;
    _iconsCollectionView.dataSource = self;
    _iconsCollectionView.backgroundColor = UIColor.clearColor;
    _iconsCollectionView.showsHorizontalScrollIndicator = NO;
    _iconsCollectionView.showsVerticalScrollIndicator = NO;
    _iconsCollectionView.clipsToBounds = NO;
    _iconsCollectionView.scrollEnabled = NO;
  }
  return _iconsCollectionView;
}

@end
