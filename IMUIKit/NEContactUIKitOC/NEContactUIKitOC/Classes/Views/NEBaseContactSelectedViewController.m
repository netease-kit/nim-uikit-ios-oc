// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseContactSelectedViewController.h"
#import <NEChatKitOC/ChatConstant.h>
#import <NEChatKitOC/ContactRepo.h>
#import <NEChatKitOC/NEFriendUserCache.h>
#import <NEChatKitOC/IMKitConfigCenter.h>
#import <NEChatKitOC/NEChatDetectNetworkTool.h>
#import <NEChatKitOC/UIColor+NECommon.h>
#import <NEChatKitOC/NECoreIM2KitOC.h>
#import <NECommonUIKitOC/NECommonUIKitOC.h>
#import <NECommonUIKitOC/NEConfigManager.h>
#import <NECommonUIKitOC/NECommonUIConstant.h>
#import <NECommonUIKitOC/NENavigationView.h>
#import "NEBaseContactTableViewCell.h"
#import "ContactSectionView.h"
#import "ContactInfo.h"

@interface NEBaseContactSelectedViewController ()
@property (nonatomic, assign) NSInteger lastTitleIndex;
@property (nonatomic, assign) CGFloat collectionBackViewTopMargin;
@property (nonatomic, assign) CGFloat collectionBackViewHeight;
@property (nonatomic, strong, nullable) NSLayoutConstraint *tableViewTopAnchor;
@end

@implementation NEBaseContactSelectedViewController

#pragma mark - Init

- (instancetype)initWithFilterUsers:(NSSet<NSString *> *)filterUsers {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _filterUsers = filterUsers;
    _lastTitleIndex = 0;
    _limit = 10;
    _selectArray = [NSMutableArray array];
    _isCreating = NO;
    _collectionBackViewTopMargin = 0;
    _collectionBackViewHeight = 52;
    _customCells = [NSMutableDictionary dictionary];
    _viewModel = [[ContactViewModel alloc] initWithContactHeaders:nil];
    _sureButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _sureButton.frame = CGRectMake(0, 0, 76, 32);
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  return [super initWithCoder:coder];
}

#pragma mark - Life Cycle

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  self.collectionBackViewTopAnchor.constant = self.topConstant + self.collectionBackViewTopMargin;
  self.tableViewTopAnchor.constant = self.topConstant;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(changeLanguage)
                                               name:NENotificationNameChangeLanguage
                                             object:nil];
  [self changeLanguage];
  [self setupUI];
  [self setupNavRightItem];
  [self loadData];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(loadData)
                                               name:NENotificationFriendCacheInit
                                             object:nil];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - setupUI

- (void)setupUI {
  [self.view addSubview:self.collectionBackView];
  self.collectionBackViewTopAnchor = [self.collectionBackView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:self.topConstant + self.collectionBackViewTopMargin];
  self.collectionBackViewTopAnchor.active = YES;
  [NSLayoutConstraint activateConstraints:@[
    [self.collectionBackView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:16],
    [self.collectionBackView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant:-16],
    [self.collectionBackView.heightAnchor constraintEqualToConstant:self.collectionBackViewHeight],
  ]];

  self.collectionView.backgroundColor = [UIColor clearColor];
  self.collectionView.delegate = self;
  self.collectionView.dataSource = self;
  self.collectionView.allowsMultipleSelection = NO;
  self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
  [self.collectionBackView addSubview:self.collectionView];
  [NSLayoutConstraint activateConstraints:@[
    [self.collectionView.centerYAnchor constraintEqualToAnchor:self.collectionBackView.centerYAnchor],
    [self.collectionView.leftAnchor constraintEqualToAnchor:self.collectionBackView.leftAnchor],
    [self.collectionView.rightAnchor constraintEqualToAnchor:self.collectionBackView.rightAnchor],
    [self.collectionView.heightAnchor constraintEqualToConstant:self.collectionBackViewHeight],
  ]];

  [self.view addSubview:self.tableView];
  self.tableViewTopAnchor = [self.tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:self.topConstant];
  self.tableViewTopAnchor.active = YES;
  [NSLayoutConstraint activateConstraints:@[
    [self.tableView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.tableView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
  ]];

  [self.tableView registerClass:[ContactSectionView class]
      forHeaderFooterViewReuseIdentifier:NSStringFromClass([ContactSectionView class])];

  for (NSNumber *key in self.customCells) {
    Class value = self.customCells[key];
    [self.tableView registerClass:value forCellReuseIdentifier:NSStringFromClass(value)];
  }

  [self.view addSubview:self.emptyView];
  [NSLayoutConstraint activateConstraints:@[
    [self.emptyView.topAnchor constraintEqualToAnchor:self.tableView.topAnchor],
    [self.emptyView.bottomAnchor constraintEqualToAnchor:self.tableView.bottomAnchor],
    [self.emptyView.leftAnchor constraintEqualToAnchor:self.tableView.leftAnchor],
    [self.emptyView.rightAnchor constraintEqualToAnchor:self.tableView.rightAnchor],
  ]];
}

- (void)loadData {
  __weak typeof(self) weakSelf = self;
  [self.viewModel loadData:self.filterUsers completion:^(NSError * _Nullable error, NSInteger userSectionCount) {
    weakSelf.emptyView.hidden = userSectionCount > 0;
    [weakSelf.tableView reloadData];
  }];
}

- (void)setupNavRightItem {
  NSNumber *useSystemNavValue = [[NEConfigManager instance] getParameterForKey:useSystemNav];
  if (useSystemNavValue && [useSystemNavValue boolValue]) {
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithCustomView:self.sureButton];
    self.navigationItem.rightBarButtonItem = rightItem;
    [self.sureButton addTarget:self action:@selector(sureClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.sureButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.sureButton.layer.cornerRadius = 4;
    self.sureButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    self.sureButton.titleLabel.font = [UIFont systemFontOfSize:16.0];
  } else {
    [self.navigationView setMoreButtonTitle:commonLocalizable(@"sure")];
    [self.navigationView setMoreButtonWidth:90];
    [self.navigationView.moreButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.navigationView.moreButton.layer.cornerRadius = 4;
    self.navigationView.moreButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    [self.navigationView addMoreButtonTarget:self selector:@selector(sureClick:)];
    self.sureButton = self.navigationView.moreButton;
  }
  [self refreshSelectCount];
}

- (void)sureClick:(UIButton *)sender {
  if (self.isCreating) return;

  if (self.selectArray.count <= 0) {
    [self.view ne_makeToast:contactLocalizable(@"select_contact")];
    return;
  }

  if (![[NEChatDetectNetworkTool shareInstance] isNetworkReachability]) {
    [self.view ne_makeToast:commonLocalizable(@"network_error")];
    return;
  }

  if (self.callBack) {
    self.callBack(self.selectArray);
    [self.navigationController popViewControllerAnimated:YES];
    return;
  }

  self.isCreating = YES;
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
    for (ContactInfo *c in weakSelf.selectArray) {
      [accids addObject:c.user.user.accountId ?: @""];
      NSString *name = c.user.user.name;
      if (name != nil) {
        [names addObject:name];
      } else {
        NSString *accid = c.user.user.accountId;
        if (accid.length > 0) {
          [names addObject:accid];
        }
      }
      if (c.user.user) {
        [users addObject:c.user.user];
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
    weakSelf.isCreating = NO;
  });
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return self.viewModel.contactSections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.viewModel.contactSections[section].contacts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  ContactInfo *info = self.viewModel.contactSections[indexPath.section].contacts[indexPath.row];
  Class cellClass = self.customCells[@(info.contactCellType)];
  if (cellClass) {
    NEBaseContactTableViewCell *anyCell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass(cellClass) forIndexPath:indexPath];
    [anyCell setModel:info];
    if (anyCell) {
      return anyCell;
    }
  }
  return [[UITableViewCell alloc] init];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  if (self.viewModel.contactSections[section].initial.length > 0) {
    return 40;
  }
  return 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  ContactInfo *info = self.viewModel.contactSections[indexPath.section].contacts[indexPath.row];
  if (info.isSelected == YES) {
    [self didUnselectContact:info];
  } else {
    if ((NSInteger)self.selectArray.count >= self.limit) {
      [self.view ne_makeToast:[NSString stringWithFormat:contactLocalizable(@"exceeded_limit"), (long)self.limit]];
      return;
    }
    [self didSelectContact:info];
  }
}

- (NSArray<NSString *> *)sectionIndexTitlesForTableView:(UITableView *)tableView {
  return self.viewModel.indexs;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
  for (NSInteger i = 0; i < (NSInteger)self.viewModel.contactSections.count; i++) {
    ContactSection *t = self.viewModel.contactSections[i];
    if ([t.initial isEqualToString:title]) {
      self.lastTitleIndex = i;
      return i;
    }
  }
  return self.lastTitleIndex;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  return self.selectArray.count;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
  ContactInfo *contactInfo = self.selectArray[indexPath.row];
  [self didUnselectContact:contactInfo];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  return [[UICollectionViewCell alloc] init];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
  return CGSizeMake(46, self.collectionBackViewHeight);
}

#pragma mark - Select/Unselect

- (void)didSelectContact:(ContactInfo *)contact {
  contact.isSelected = YES;
  BOOL exists = NO;
  for (ContactInfo *c in self.selectArray) {
    if (contact == c) {
      exists = YES;
      break;
    }
  }
  if (!exists) {
    [self.selectArray addObject:contact];
    if (self.collectionBackView.isHidden) {
      self.collectionBackView.hidden = NO;
      self.tableViewTopAnchor.constant += self.collectionBackViewHeight + self.collectionBackViewTopMargin * 2;
    }
  }
  [self.collectionView reloadData];
  [self.tableView reloadData];
  [self refreshSelectCount];
}

- (void)didUnselectContact:(ContactInfo *)contact {
  contact.isSelected = NO;
  NSMutableArray *toRemove = [NSMutableArray array];
  for (ContactInfo *c in self.selectArray) {
    if (contact == c) {
      [toRemove addObject:c];
    }
  }
  [self.selectArray removeObjectsInArray:toRemove];
  if (self.selectArray.count <= 0) {
    self.collectionBackView.hidden = YES;
    self.tableViewTopAnchor.constant -= self.collectionBackViewHeight + self.collectionBackViewTopMargin * 2;
  }
  [self.collectionView reloadData];
  [self.tableView reloadData];
  [self refreshSelectCount];
}

- (void)refreshSelectCount {
  if (self.selectArray.count > 0) {
    [self.sureButton setTitle:[NSString stringWithFormat:@"%@(%lu)",
                               commonLocalizable(@"sure"),
                               (unsigned long)self.selectArray.count]
                     forState:UIControlStateNormal];
  } else {
    [self.sureButton setTitle:commonLocalizable(@"sure") forState:UIControlStateNormal];
  }
}

- (void)changeLanguage {
  self.title = contactLocalizable(@"select");
  self.emptyView.message = contactLocalizable(@"no_friend");
  [self refreshSelectCount];
}

#pragma mark - Lazy Init

- (UIView *)collectionBackView {
  if (!_collectionBackView) {
    _collectionBackView = [[UIView alloc] init];
    _collectionBackView.translatesAutoresizingMaskIntoConstraints = NO;
    _collectionBackView.backgroundColor = [UIColor clearColor];
    _collectionBackView.layer.cornerRadius = 4;
    _collectionBackView.hidden = YES;
  }
  return _collectionBackView;
}

- (UICollectionView *)collectionView {
  if (!_collectionView) {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.minimumLineSpacing = 0;
    layout.minimumInteritemSpacing = 0;
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    _collectionView.contentInset = UIEdgeInsetsMake(0, 5, 0, 5);
    _collectionView.accessibilityIdentifier = @"id.selected";
  }
  return _collectionView;
}

- (UITableView *)tableView {
  if (!_tableView) {
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _tableView.backgroundColor = [UIColor clearColor];
    _tableView.sectionIndexColor = [UIColor ne_greyText];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.translatesAutoresizingMaskIntoConstraints = NO;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.contentInset = UIEdgeInsetsMake(-10, 0, 0, 0);
    _tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;

    _tableView.estimatedRowHeight = 0;
    _tableView.estimatedSectionHeaderHeight = 0;
    _tableView.estimatedSectionFooterHeight = 0;

    if (@available(iOS 15.0, *)) {
      _tableView.sectionHeaderTopPadding = 0.0;
    }
  }
  return _tableView;
}

@end
