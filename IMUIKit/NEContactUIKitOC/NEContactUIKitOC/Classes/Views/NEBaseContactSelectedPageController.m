// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseContactSelectedPageController.h"
#import <NEChatKitOC/ContactRepo.h>
#import <NEChatKitOC/NEFriendUserCache.h>
#import <NEChatKitOC/TeamRepo.h>
#import <NEChatKitOC/IMKitConfigCenter.h>
#import <NEChatKitOC/NEChatDetectNetworkTool.h>
#import <NEChatKitOC/NECoreIM2KitOC.h>
#import <NECommonUIKitOC/NECommonUIKitOC.h>
#import "ContactConst.h"

@interface NEBaseContactSelectedPageController ()
@property (nonatomic, assign) BOOL isRequesting;
@end

@implementation NEBaseContactSelectedPageController

- (instancetype)initWithFilterUsers:(NSSet<NSString *> *)filterUsers {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _limit = 10;
    _childrenControllers = [NSMutableArray array];
    _selectedSureButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _selectedSureButton.frame = CGRectMake(0, 0, 76, 32);
    _isRequesting = NO;
    _contentControllers = [NSMutableArray array];
    _selectArray = [NSMutableArray array];
    _collectionBackViewTopMargin = 0;
    _collectionBackViewHeight = 52;
    NSArray *controllers = [self getContentControllers:filterUsers];
    if (controllers) {
      [_contentControllers addObjectsFromArray:controllers];
    }
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  return [super initWithCoder:coder];
}

- (void)setLimit:(NSInteger)limit {
  _limit = limit;
  for (NEBaseFusionContactSelectedController *controller in self.childrenControllers) {
    controller.limit = limit;
  }
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(changeLanguage)
                                               name:NENotificationNameChangeLanguage
                                             object:nil];
  [self changeLanguage];
  [self setupNavSureItem];
  [self setupPageContent];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSArray<NEBaseFusionContactSelectedController *> *)getContentControllers:(NSSet<NSString *> *)filterUsers {
  return nil;
}

- (void)setupPageContent {
  [self.view addSubview:self.selectCollectionBackView];
  self.collectionBackViewTopAnchor = [self.selectCollectionBackView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:self.topConstant + self.collectionBackViewTopMargin];
  self.collectionBackViewTopAnchor.active = YES;
  [NSLayoutConstraint activateConstraints:@[
    [self.selectCollectionBackView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:16],
    [self.selectCollectionBackView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant:-16],
    [self.selectCollectionBackView.heightAnchor constraintEqualToConstant:self.collectionBackViewHeight],
  ]];

  self.selectCollectionView.backgroundColor = [UIColor clearColor];
  self.selectCollectionView.delegate = self;
  self.selectCollectionView.dataSource = self;
  self.selectCollectionView.allowsMultipleSelection = NO;
  self.selectCollectionView.translatesAutoresizingMaskIntoConstraints = NO;
  [self.selectCollectionBackView addSubview:self.selectCollectionView];
  [NSLayoutConstraint activateConstraints:@[
    [self.selectCollectionView.centerYAnchor constraintEqualToAnchor:self.selectCollectionBackView.centerYAnchor],
    [self.selectCollectionView.leftAnchor constraintEqualToAnchor:self.selectCollectionBackView.leftAnchor],
    [self.selectCollectionView.rightAnchor constraintEqualToAnchor:self.selectCollectionBackView.rightAnchor],
    [self.selectCollectionView.heightAnchor constraintEqualToConstant:self.collectionBackViewHeight],
  ]];
}

- (void)setupNavSureItem {
  NSNumber *useSystemNavValue = [[NEConfigManager instance] getParameterForKey:useSystemNav];
  if (useSystemNavValue && [useSystemNavValue boolValue]) {
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithCustomView:self.selectedSureButton];
    self.navigationItem.rightBarButtonItem = rightItem;
    [self.selectedSureButton addTarget:self action:@selector(selectSureClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.selectedSureButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.selectedSureButton.layer.cornerRadius = 4;
    self.selectedSureButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    self.selectedSureButton.titleLabel.font = [UIFont systemFontOfSize:16.0];
  } else {
    [self.navigationView setMoreButtonTitle:commonLocalizable(@"sure")];
    [self.navigationView setMoreButtonWidth:90];
    [self.navigationView.moreButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.navigationView.moreButton.layer.cornerRadius = 4;
    self.navigationView.moreButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    [self.navigationView addMoreButtonTarget:self selector:@selector(selectSureClick:)];
    self.selectedSureButton = self.navigationView.moreButton;
    self.navigationView.backgroundColor = [UIColor whiteColor];
  }
  [self didChangeSelectUser];
}

- (void)selectSureClick:(UIButton *)sender {
  if (self.isRequesting) return;

  if (self.selectArray.count <= 0) {
    [self.view ne_makeToast:contactLocalizable(@"select_contact")];
    return;
  }

  if (![[NEChatDetectNetworkTool shareInstance] isNetworkReachability]) {
    [self.view ne_makeToast:commonLocalizable(@"network_error")];
    return;
  }

  self.isRequesting = YES;
  NSMutableArray<NSString *> *accids = [NSMutableArray array];
  NSMutableArray<NSString *> *names = [NSMutableArray array];
  dispatch_group_t group = dispatch_group_create();
  __block NEUserWithFriend *mine = nil;

  NEUserWithFriend *mineInfo = [[NEFriendUserCache shared] getFriendInfo:[[IMKitClient instance] account]];
  if (mineInfo) {
    mine = mineInfo;
  } else {
    dispatch_group_enter(group);
    [[ContactRepo shared] getUserListFromCloud:@[[[IMKitClient instance] account]] completion:^(NSArray<NEUserWithFriend *> * _Nullable users, NSError * _Nullable error) {
      mine = users.firstObject;
      dispatch_group_leave(group);
    }];
  }

  __weak typeof(self) weakSelf = self;
  dispatch_group_notify(group, dispatch_get_main_queue(), ^{
    NSString *myName = [mine showName] ?: [[IMKitClient instance] account];
    [names addObject:myName];
    NSMutableArray<V2NIMUser *> *users = [NSMutableArray array];
    for (NEFusionContactCellModel *model in weakSelf.selectArray) {
      [accids addObject:[model getAccountId]];

      NSString *name = [model getShowName];
      NSString *accountId = [model getAccountId];
      if (names.count > 0) {
        [names addObject:name];
      } else if (accountId.length > 0) {
        [names addObject:accountId];
      }
      if (model.user.user) {
        [users addObject:model.user.user];
      } else if (model.aiUser) {
        [users addObject:model.aiUser];
      }
    }

    if (weakSelf.userId) {
      [accids addObject:weakSelf.userId];
    }

    NSString *nameString = [names componentsJoinedByString:@"、"];
    NSLog(@"name string : %@", nameString);
    [[Router shared] use:ContactSelectedUsersRouter
              parameters:@{@"accids": accids, @"names": nameString, @"im_user": users}
                 closure:nil];
    [weakSelf.navigationController popViewControllerAnimated:YES];
    weakSelf.isRequesting = NO;
  });
}

#pragma mark - FusionContactSelectedDelegate

- (BOOL)didSelectedUser:(NEFusionContactCellModel *)model {
  if ((NSInteger)self.selectArray.count >= self.limit) {
    return NO;
  }
  [self.selectArray addObject:model];
  [self didChangeSelectUser];
  return YES;
}

- (void)didUnselectedUser:(NEFusionContactCellModel *)model {
  NSMutableArray *toRemove = [NSMutableArray array];
  for (NEFusionContactCellModel *selectModel in self.selectArray) {
    NSString *selectAccountId = [selectModel getAccountId];
    NSString *rmAccountId = [model getAccountId];
    if (selectAccountId.length > 0 && [rmAccountId isEqualToString:selectAccountId]) {
      [toRemove addObject:selectModel];
    }
  }
  [self.selectArray removeObjectsInArray:toRemove];
  [self didChangeSelectUser];
}

- (void)didChangeSelectUser {
  if (self.selectArray.count > 0) {
    [self.selectedSureButton setTitle:[NSString stringWithFormat:@"%@(%lu)", commonLocalizable(@"sure"), (unsigned long)self.selectArray.count] forState:UIControlStateNormal];
  } else {
    [self.selectedSureButton setTitle:commonLocalizable(@"sure") forState:UIControlStateNormal];
  }
  if (self.selectArray.count <= 0) {
    self.selectCollectionBackView.hidden = YES;
    self.pagingViewControllerTopAnchor.constant = self.topConstant;
  } else {
    self.selectCollectionBackView.hidden = NO;
    self.pagingViewControllerTopAnchor.constant = self.topConstant + self.collectionBackViewHeight + self.collectionBackViewTopMargin * 2;
  }
  [self.selectCollectionView reloadData];
}

- (void)changeLanguage {
  self.title = contactLocalizable(@"select");
  [self didChangeSelectUser];
}

- (void)didUnselect:(NEFusionContactCellModel *)model {
  for (NEBaseFusionContactSelectedController *controller in self.childrenControllers) {
    [controller unselectModel:model];
  }
  [self didUnselectedUser:model];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  return self.selectArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  return [[UICollectionViewCell alloc] init];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
  NEFusionContactCellModel *model = self.selectArray[indexPath.row];
  [self didUnselect:model];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
  return CGSizeMake(46, self.collectionBackViewHeight);
}

#pragma mark - Lazy Init

- (UIView *)selectCollectionBackView {
  if (!_selectCollectionBackView) {
    _selectCollectionBackView = [[UIView alloc] init];
    _selectCollectionBackView.translatesAutoresizingMaskIntoConstraints = NO;
    _selectCollectionBackView.backgroundColor = [UIColor clearColor];
    _selectCollectionBackView.layer.cornerRadius = 4;
    _selectCollectionBackView.hidden = YES;
  }
  return _selectCollectionBackView;
}

- (UICollectionView *)selectCollectionView {
  if (!_selectCollectionView) {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.minimumLineSpacing = 0;
    layout.minimumInteritemSpacing = 0;
    _selectCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    _selectCollectionView.contentInset = UIEdgeInsetsMake(0, 5, 0, 5);
    _selectCollectionView.accessibilityIdentifier = @"id.selected";
  }
  return _selectCollectionView;
}

@end
