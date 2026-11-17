// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NETeamBaseViewController.h"
#import "TeamAvatarViewModel.h"
#import <NIMSDK/NIMSDK.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^NETeamAvatarSaveCompletion)(void);

@class NEUserHeaderView;
@class TeamRepo;

@interface NEBaseTeamAvatarViewController : NETeamBaseViewController <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, copy, nullable) NETeamAvatarSaveCompletion block;
@property (nonatomic, strong, nullable) V2NIMTeam *team;
@property (nonatomic, strong) TeamRepo *repo;
@property (nonatomic, strong) UIView *headerBackView;
@property (nonatomic, strong) UIImageView *photoImageView;
@property (nonatomic, strong) UIView *defaultHeaderBackView;
@property (nonatomic, strong) UILabel *tagLabel;
@property (nonatomic, strong) NSArray<NSString *> *iconUrls;
@property (nonatomic, strong) TeamAvatarViewModel *viewModel;
@property (nonatomic, strong) NEUserHeaderView *headerView;
@property (nonatomic, copy) NSString *headerUrl;
@property (nonatomic, strong) UIButton *clickButton;
@property (nonatomic, strong) UICollectionView *iconsCollectionView;

- (void)setupUI;
/// 候选格边长（Normal 48 / Fun 56），基类按容器宽度均分间距时使用。
- (CGFloat)defaultIconSideLength;
- (BOOL)getChangePermission;
- (void)uploadPhoto;
- (void)savePhoto;
- (void)uploadHeadImage:(UIImage *)image;
- (void)uploadHeadImageWithImage:(UIImage *)image;

@end

NS_ASSUME_NONNULL_END
