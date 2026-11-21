// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "MeViewController.h"
#import <NEChatKit/NEChatKit.h>
#import <NEBaseUIKitOC/NEAdaptiveDeviceGate.h>
#import "MeViewModel.h"
#import "MineTableViewCell.h"
#import "MineSettingViewController.h"
#import "IntroduceBrandViewController.h"
#import "PersonInfoViewController.h"
#import <NEChatUIKitOC/CollectionMessageController.h>
#import <NEChatUIKitOC/FunCollectionMessageController.h>
#import "NEStyleManager.h"
#import "AppKey.h"
#import <NEChatKit/IMKitConfigCenter.h>
#import <NEChatKit/ContactRepo.h>
#import <NEChatKit/NEFriendUserCache.h>
#import <NEChatKit/UIColor+NECommon.h>
#import <NEBaseUIKitOC/NEBaseUIKitOC.h>
#import <NEBaseUIKitOC/UITableViewCell+NEAdaptiveSelection.h>
#import <NIMSDK/NIMSDK.h>

@interface MeViewController () <UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate>

@property (nonatomic, strong) MeViewModel *viewModel;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong, nullable) NSIndexPath *adaptiveSelectedIndexPath;
@property (nonatomic, strong) NEUserHeaderView *header;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *idLabel;
@property (nonatomic, strong) UIImageView *arrowImageView;
@property (nonatomic, strong) UIButton *personInfoButton;
@property (nonatomic, strong) UIView *headerBackgroundView;

@end

static NSString *const kMineCellId = @"MineTableViewCell";

@implementation MeViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.viewModel = [[MeViewModel alloc] init];

  self.view.backgroundColor = [NEStyleManager.instance isNormalStyle]
    ? [UIColor colorWithRed:0xEF/255.0 green:0xF1/255.0 blue:0xF4/255.0 alpha:1.0]
    : [UIColor colorWithRed:0xED/255.0 green:0xED/255.0 blue:0xED/255.0 alpha:1.0];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(changeLanguage)
                                               name:NENotificationChangeLanguage
                                             object:nil];

  [self setupSubviews];
  [self.viewModel getData];
  [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  self.navigationController.navigationBarHidden = YES;
  [self updateUserInfo];

  if (self.navigationController.viewControllers.count > 0) {
    UIViewController *root = self.navigationController.viewControllers.firstObject;
    if ([root isKindOfClass:[MeViewController class]]) {
      self.navigationController.interactivePopGestureRecognizer.delegate = self;
    }
  }
}

- (void)willMoveToParentViewController:(UIViewController *)parent {
  [super willMoveToParentViewController:parent];
  if (!parent) {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
  }
}

#pragma mark - Language

- (void)changeLanguage {
  [self updateUserInfo];
  [self.viewModel getData];
  [self.tableView reloadData];
}

#pragma mark - UI Setup

- (void)setupSubviews {
  // ── 头像 ──
  _header = [[NEUserHeaderView alloc] initWithFrame:CGRectZero];
  _header.titleLabel.font = [UIFont systemFontOfSize:22.0];
  _header.translatesAutoresizingMaskIntoConstraints = NO;
  _header.clipsToBounds = YES;
  _header.layer.cornerRadius = [NEStyleManager.instance isNormalStyle] ? 30 : 4;
  [self.view addSubview:_header];

  [NSLayoutConstraint activateConstraints:@[
    [_header.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:20],
    [_header.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:32],
    [_header.widthAnchor constraintEqualToConstant:60],
    [_header.heightAnchor constraintEqualToConstant:60],
  ]];

  // ── 昵称 ──
  _nameLabel = [[UILabel alloc] init];
  _nameLabel.textColor = [UIColor ne_darkText];
  _nameLabel.font = [UIFont systemFontOfSize:22.0];
  _nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
  _nameLabel.accessibilityIdentifier = @"id.name";
  [self.view addSubview:_nameLabel];

  [NSLayoutConstraint activateConstraints:@[
    [_nameLabel.leftAnchor constraintEqualToAnchor:_header.rightAnchor constant:15],
    [_nameLabel.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant:-30],
    [_nameLabel.topAnchor constraintEqualToAnchor:_header.topAnchor],
  ]];

  // ── 账号 ID ──
  _idLabel = [[UILabel alloc] init];
  _idLabel.textColor = [UIColor ne_darkText];
  _idLabel.font = [UIFont systemFontOfSize:16.0];
  _idLabel.translatesAutoresizingMaskIntoConstraints = NO;
  _idLabel.accessibilityIdentifier = @"id.account";
  [self.view addSubview:_idLabel];

  [NSLayoutConstraint activateConstraints:@[
    [_idLabel.leftAnchor constraintEqualToAnchor:_nameLabel.leftAnchor],
    [_idLabel.rightAnchor constraintEqualToAnchor:_nameLabel.rightAnchor],
    [_idLabel.topAnchor constraintEqualToAnchor:_nameLabel.bottomAnchor constant:8],
  ]];

  [self updateUserInfo];

  // ── 分割线 ──
  UIView *divider = [[UIView alloc] init];
  divider.translatesAutoresizingMaskIntoConstraints = NO;
  divider.backgroundColor = UIColor.clearColor;
  [self.view addSubview:divider];

  [NSLayoutConstraint activateConstraints:@[
    [divider.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [divider.heightAnchor constraintEqualToConstant:6],
    [divider.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [divider.topAnchor constraintEqualToAnchor:_header.bottomAnchor constant:32],
  ]];

  // ── 列表 ──
  _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
  _tableView.translatesAutoresizingMaskIntoConstraints = NO;
  _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
  _tableView.delegate = self;
  _tableView.dataSource = self;
  _tableView.rowHeight = 52;
  _tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
  _tableView.estimatedRowHeight = 0;
  _tableView.estimatedSectionHeaderHeight = 0;
  _tableView.estimatedSectionFooterHeight = 0;
  [_tableView registerClass:[MineTableViewCell class] forCellReuseIdentifier:kMineCellId];
  if (@available(iOS 15.0, *)) {
    _tableView.sectionHeaderTopPadding = 0;
  }
  _tableView.backgroundColor = [NEStyleManager.instance isNormalStyle] ? UIColor.whiteColor : UIColor.clearColor;
  [self.view addSubview:_tableView];

  // ── 箭头 ──
  _arrowImageView = [[UIImageView alloc] initWithImage:[coreLoader() loadImage:@"arrow_right"]];
  _arrowImageView.translatesAutoresizingMaskIntoConstraints = NO;
  _arrowImageView.accessibilityIdentifier = @"id.rightArrow";
  [self.view addSubview:_arrowImageView];

  // ── 个人信息点击按钮 ──
  _personInfoButton = [UIButton buttonWithType:UIButtonTypeCustom];
  _personInfoButton.translatesAutoresizingMaskIntoConstraints = NO;
  [_personInfoButton addTarget:self action:@selector(personInfoButtonClick) forControlEvents:UIControlEventTouchUpInside];
  _personInfoButton.accessibilityIdentifier = @"id.personInfo";
  [self.view addSubview:_personInfoButton];

  [NSLayoutConstraint activateConstraints:@[
    [_tableView.topAnchor constraintEqualToAnchor:divider.bottomAnchor],
    [_tableView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [_tableView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [_tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

    [_arrowImageView.centerYAnchor constraintEqualToAnchor:_header.centerYAnchor],
    [_arrowImageView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant:-20],

    [_personInfoButton.topAnchor constraintEqualToAnchor:_header.topAnchor],
    [_personInfoButton.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [_personInfoButton.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [_personInfoButton.bottomAnchor constraintEqualToAnchor:divider.topAnchor],
  ]];

  // ── 头部白色背景 ──
  _headerBackgroundView = [[UIView alloc] init];
  _headerBackgroundView.translatesAutoresizingMaskIntoConstraints = NO;
  _headerBackgroundView.backgroundColor = UIColor.whiteColor;
  [self.view insertSubview:_headerBackgroundView belowSubview:_header];

  [NSLayoutConstraint activateConstraints:@[
    [_headerBackgroundView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
    [_headerBackgroundView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [_headerBackgroundView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [_headerBackgroundView.bottomAnchor constraintEqualToAnchor:divider.topAnchor],
  ]];
}

#pragma mark - User Info

- (void)setupUserInfo:(NEUserWithFriend *)userFriend {
  NSString *accountId = userFriend.user.accountId ?: @"";
  self.idLabel.text = [NSString stringWithFormat:@"%@:%@", NELocalizable(@"account"), accountId];
  self.nameLabel.text = [userFriend showName];
  [self.header configHeadData:userFriend.user.avatar
                         name:[userFriend shortName:YES count:2] ?: @""
                          uid:accountId];
}

- (void)updateUserInfo {
  NSString *accountId = [[IMKitClient instance] account];
  if (!accountId.length) {
    return;
  }

  NEUserWithFriend *userFriend = [[NEFriendUserCache shared] getFriendInfo:accountId];
  if (userFriend) {
    [self setupUserInfo:userFriend];
    return;
  }

  __weak typeof(self) weakSelf = self;
  [[ContactRepo shared] getUserListFromCloud:@[accountId] completion:^(NSArray<NEUserWithFriend *> *users, NSError *error) {
    (void)error;
    dispatch_async(dispatch_get_main_queue(), ^{
      [weakSelf setupUserInfo:users.firstObject];
    });
  }];
}

#pragma mark - Actions

- (void)personInfoButtonClick {
  // 个人信息页不是左列的行：清掉过期选中，避免旧行继续高亮。
  [self clearAdaptiveSelection];
  PersonInfoViewController *vc = [[PersonInfoViewController alloc] init];
  [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.viewModel.mineData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  MineTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kMineCellId forIndexPath:indexPath];
  NSDictionary<NSString *, NSString *> *data = self.viewModel.mineData[indexPath.row];
  [cell configCellWithData:data];
  NSString *cellTitle = data.allKeys.firstObject ?: [NSString stringWithFormat:@"config%ld", (long)indexPath.row];
  cell.accessibilityIdentifier = [NSString stringWithFormat:@"id.%@", cellTitle];
  BOOL shouldSelect = self.listSelectionBackgroundColor != nil &&
                      [indexPath isEqual:self.adaptiveSelectedIndexPath];
  // cell 复用可能带着上一次的选中底色：先还原再记录原始底色，
  // 然后只覆盖底色、不改变 selectionStyle；按下期间不会出现系统高亮。
  [cell ne_applyAdaptiveSelectionColor:nil selected:NO];
  [cell ne_captureAdaptiveSelectionBackground];
  [cell ne_applyAdaptiveSelectionColor:self.listSelectionBackgroundColor selected:shouldSelect];
  return cell;
}

#pragma mark - UITableViewDelegate

- (void)setListSelectionBackgroundColor:(UIColor *)listSelectionBackgroundColor {
  _listSelectionBackgroundColor = listSelectionBackgroundColor;
  [self refreshAdaptiveSelectionTint];
}

- (void)refreshAdaptiveSelectionTint {
  if (!self.isViewLoaded) {
    return;
  }
  for (UITableViewCell *cell in self.tableView.visibleCells) {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    BOOL selected = self.listSelectionBackgroundColor != nil && indexPath &&
                    [indexPath isEqual:self.adaptiveSelectedIndexPath];
    [cell ne_applyAdaptiveSelectionColor:self.listSelectionBackgroundColor selected:selected];
  }
}

/// 右列回到空白占位或进入非行入口时调用：清掉记住的行并取消表格选中。
- (void)clearAdaptiveSelection {
  self.adaptiveSelectedIndexPath = nil;
  NSIndexPath *selected = [self.tableView indexPathForSelectedRow];
  if (selected) {
    [self.tableView deselectRowAtIndexPath:selected animated:NO];
  }
  [self refreshAdaptiveSelectionTint];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:NO];
  UIViewController *pushed = nil;
  // 先更新选中行并刷新底色，再 push；选中态只由 adaptiveSelectedIndexPath 决定。
  self.adaptiveSelectedIndexPath = indexPath;
  [self refreshAdaptiveSelectionTint];
  if ([IMKitConfigCenter shared].enableCollectionMessage) {
    if (indexPath.row == 0) {
      MineSettingViewController *vc = [[MineSettingViewController alloc] init];
      [self.navigationController pushViewController:vc animated:YES];
      pushed = vc;
    } else if (indexPath.row == 1) {
      UIViewController *collectionVC = [NEStyleManager.instance isNormalStyle]
        ? [[CollectionMessageController alloc] init]
        : [[FunCollectionMessageController alloc] init];
      [self.navigationController pushViewController:collectionVC animated:YES];
      pushed = collectionVC;
    } else if (indexPath.row == 2) {
      IntroduceBrandViewController *vc = [[IntroduceBrandViewController alloc] init];
      [self.navigationController pushViewController:vc animated:YES];
      pushed = vc;
    }
  } else {
    if (indexPath.row == 0) {
      MineSettingViewController *vc = [[MineSettingViewController alloc] init];
      [self.navigationController pushViewController:vc animated:YES];
      pushed = vc;
    } else if (indexPath.row == 1) {
      IntroduceBrandViewController *vc = [[IntroduceBrandViewController alloc] init];
      [self.navigationController pushViewController:vc animated:YES];
      pushed = vc;
    }
  }
  (void)pushed;
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
  if (self.navigationController &&
      [self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)] &&
      gestureRecognizer == self.navigationController.interactivePopGestureRecognizer &&
      self.navigationController.visibleViewController == self.navigationController.viewControllers.firstObject) {
    return NO;
  }
  return YES;
}

@end
