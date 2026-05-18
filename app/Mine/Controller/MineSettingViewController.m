// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "MineSettingViewController.h"
#import "MessageRemindViewController.h"
#import "StyleSelectionViewController.h"
#import "LanguageViewController.h"
#import "ConfigTestViewController.h"
#import "IMPocConfigViewController.h"
#import "IMPushConfigViewController.h"
#import "CustomThemeCells.h"
#import "IMPocConfigManager.h"
#import "NEStyleManager.h"
#import "AppKey.h"
#import <NEChatKitOC/NECoreIM2KitOC.h>
#import <NEChatKitOC/NEConstant.h>
#import <NEChatKitOC/NEFriendUserCache.h>
#import <NEChatKitOC/NESubscribeManager.h>
#import <NECommonUIKitOC/NECommonUIKitOC.h>
#import <NECommonUIKitOC/ViewControllerExtension.h>
#import <NECommonUIKitOC/UIView+YXToast.h>
#import <NEChatKitOC/SettingRepo.h>
#import <NEChatKitOC/UIColor+NECommon.h>
#import <NEChatUIKitOC/FunChatUIColor.h>
#import <NECommonUIKitOC/NENavigationView.h>
#import <NIMSDK/NIMSDK.h>
#import <NETeamUIKitOC/SettingCellModel.h>
#import <NETeamUIKitOC/SettingSectionModel.h>
#import <NETeamUIKitOC/NEBaseTeamSettingCell.h>

static NSString *const kEnableCloudConversationKey = @"nim_enable_v2_cloud_conversation";

@protocol MineSettingViewModelDelegate <NSObject>
- (void)didMessageRemindClick;
- (void)didStyleClick;
- (void)didClickCleanCache;
- (void)didClickConfigTest;
- (void)didClickSDKConfig;
- (void)didClickPushConfig;
- (void)didClickLanguage;
- (void)didChangeConversationType:(void(^)(BOOL cancel))cancel;
@end

@interface MineSettingViewModel : NSObject
@property (nonatomic, strong) NSArray<SettingSectionModel *> *sectionData;
@property (nonatomic, weak) id<MineSettingViewModelDelegate> delegate;
- (void)getData;
@end

@implementation MineSettingViewModel

- (instancetype)init {
  self = [super init];
  if (self) {
    _sectionData = @[];
  }
  return self;
}

- (void)getData {
  self.sectionData = @[
    [self getFirstSection],
    [self getSecondSection],
    [self getThreeSection],
  ];
}

- (SettingSectionModel *)getFirstSection {
  SettingSectionModel *model = [[SettingSectionModel alloc] init];
  __weak typeof(self) weakSelf = self;

  SettingCellModel *remind = [[SettingCellModel alloc] init];
  remind.cellName = NELocalizable(@"message_remind");
  remind.type = SettingCellTypeSettingArrowCell;
  remind.cellClick = ^{
    [weakSelf.delegate didMessageRemindClick];
  };
  [model.cellModels addObject:remind];

  SettingCellModel *style = [[SettingCellModel alloc] init];
  style.cellName = NELocalizable(@"style_selection");
  style.type = SettingCellTypeSettingArrowCell;
  style.cellClick = ^{
    [weakSelf.delegate didStyleClick];
  };
  [model.cellModels addObject:style];

  [model setCornerType];
  return model;
}

- (SettingSectionModel *)getSecondSection {
  SettingSectionModel *model = [[SettingSectionModel alloc] init];
  __weak typeof(self) weakSelf = self;

  SettingCellModel *hasRead = [[SettingCellModel alloc] init];
  hasRead.cellName = NELocalizable(@"message_read_function");
  hasRead.type = SettingCellTypeSettingSwitchCell;
  hasRead.switchOpen = [SettingRepo.shared getShowReadStatus];
  hasRead.swichChange = ^(BOOL isOpen) {
    [SettingRepo.shared setShowReadStatus:isOpen];
  };
  [model.cellModels addObject:hasRead];

  SettingCellModel *cloudConversationModel = [[SettingCellModel alloc] init];
  cloudConversationModel.cellName = NELocalizable(@"cloud_conversation");
  cloudConversationModel.type = SettingCellTypeSettingSwitchCell;
  cloudConversationModel.switchOpen = [NIMSDK sharedSDK].v2Option.enableV2CloudConversation;
  cloudConversationModel.swichChange = ^(BOOL isOpen) {
    [weakSelf.delegate didChangeConversationType:^(BOOL cancel) {
      if (cancel) {
        cloudConversationModel.switchOpen = !isOpen;
      } else {
        [NSUserDefaults.standardUserDefaults setBool:isOpen forKey:kEnableCloudConversationKey];
      }
    }];
  };
  [model.cellModels addObject:cloudConversationModel];

  [model setCornerType];
  return model;
}

- (SettingSectionModel *)getThreeSection {
  SettingSectionModel *model = [[SettingSectionModel alloc] init];
  __weak typeof(self) weakSelf = self;

  SettingCellModel *configTest = [[SettingCellModel alloc] init];
  configTest.cellName = @"全局配置";
  configTest.type = SettingCellTypeSettingArrowCell;
  configTest.cellClick = ^{
    [weakSelf.delegate didClickConfigTest];
  };
  [model.cellModels addObject:configTest];

  SettingCellModel *sdkConfigModel = [[SettingCellModel alloc] init];
  sdkConfigModel.cellName = @"私有云环境配置";
  sdkConfigModel.type = SettingCellTypeSettingArrowCell;
  sdkConfigModel.cellClick = ^{
    [weakSelf.delegate didClickSDKConfig];
  };
  [model.cellModels addObject:sdkConfigModel];

  SettingCellModel *pushConfigModel = [[SettingCellModel alloc] init];
  pushConfigModel.cellName = @"推送配置";
  pushConfigModel.type = SettingCellTypeSettingArrowCell;
  pushConfigModel.cellClick = ^{
    [weakSelf.delegate didClickPushConfig];
  };
  [model.cellModels addObject:pushConfigModel];

  SettingCellModel *languageConfigModel = [[SettingCellModel alloc] init];
  languageConfigModel.cellName = NELocalizable(@"app_language");
  languageConfigModel.type = SettingCellTypeSettingArrowCell;
  languageConfigModel.cellClick = ^{
    [weakSelf.delegate didClickLanguage];
  };
  [model.cellModels addObject:languageConfigModel];

  [model setCornerType];
  return model;
}

@end

@interface MineSettingViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIButton    *logoutButton;
@property (nonatomic, strong) MineSettingViewModel *viewModel;
@property (nonatomic, strong) NSDictionary<NSNumber *, Class> *cellClassDic;

@end

@interface MineSettingViewController () <MineSettingViewModelDelegate>
@end

@implementation MineSettingViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.viewModel = [[MineSettingViewModel alloc] init];
  self.viewModel.delegate = self;
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(changeLanguage)
                                               name:NENotificationChangeLanguage
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(handleStyleChanged)
                                               name:NENotificationChangeUI
                                             object:nil];
  [self initialConfig];
  [self setupSubviews];
  [self changeLanguage];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
}

- (void)willMoveToParentViewController:(UIViewController *)parent {
  [super willMoveToParentViewController:parent];
  if (!parent) {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
  }
}

- (void)initialConfig {
  self.title = NELocalizable(@"setting");
  if ([NEStyleManager.instance isNormalStyle]) {
    self.view.backgroundColor = [UIColor ne_backgroundColor];
    self.navigationView.backgroundColor = [UIColor ne_backgroundColor];
    self.navigationController.navigationBar.backgroundColor = [UIColor ne_backgroundColor];
  } else {
    self.view.backgroundColor = [UIColor funChatBackgroundColor];
  }
  self.navigationView.moreButton.hidden = YES;
}

- (void)changeLanguage {
  [self.viewModel getData];
  self.title = NELocalizable(@"setting");
  self.tableView.tableFooterView = [self getFooterView];
  [self.tableView reloadData];
}

- (void)handleStyleChanged {
  [self initialConfig];
  [self.viewModel getData];
  self.tableView.tableFooterView = [self getFooterView];
  [self.tableView reloadData];
}

- (void)setupSubviews {
  BOOL isNormalStyle = [NEStyleManager.instance isNormalStyle];
  self.cellClassDic = @{
    @(SettingCellTypeSettingArrowCell): [CustomTeamArrowSettingCell class],
    @(SettingCellTypeSettingSwitchCell): [CustomTeamSettingSwitchCell class],
  };

  _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
  _tableView.translatesAutoresizingMaskIntoConstraints = NO;
  _tableView.backgroundColor = UIColor.clearColor;
  _tableView.dataSource = self;
  _tableView.delegate = self;
  _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
  _tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
  _tableView.estimatedRowHeight = 0;
  _tableView.estimatedSectionHeaderHeight = 0;
  _tableView.estimatedSectionFooterHeight = 0;
  if (@available(iOS 15.0, *)) {
    _tableView.sectionHeaderTopPadding = 0;
  }

  for (NSNumber *key in self.cellClassDic) {
    [_tableView registerClass:self.cellClassDic[key]
       forCellReuseIdentifier:[NSString stringWithFormat:@"%ld", (long)key.integerValue]];
  }
  [self.view addSubview:_tableView];

  CGFloat topOffset = self.topConstant + (isNormalStyle ? 12.0 : 0.0);
  [NSLayoutConstraint activateConstraints:@[
    [_tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:topOffset],
    [_tableView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [_tableView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [_tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
  ]];

  self.tableView.tableFooterView = [self getFooterView];

  UIButton *delAccountBtn = [UIButton buttonWithType:UIButtonTypeCustom];
  delAccountBtn.translatesAutoresizingMaskIntoConstraints = NO;
  [delAccountBtn setTitleColor:[UIColor ne_lightText] forState:UIControlStateNormal];
  delAccountBtn.titleLabel.font = [UIFont systemFontOfSize:12.0];
  [delAccountBtn setTitle:NSLocalizedString(@"account_Cancellation", nil) forState:UIControlStateNormal];
  [delAccountBtn addTarget:self action:@selector(delAccountBtnClick) forControlEvents:UIControlEventTouchUpInside];
  delAccountBtn.accessibilityIdentifier = @"id.serverConfig";
  [self.view addSubview:delAccountBtn];
  [NSLayoutConstraint activateConstraints:@[
    [delAccountBtn.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-10.0 - NEConstant.statusBarHeight],
    [delAccountBtn.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
  ]];
}

- (UIView *)getFooterView {
  BOOL isNormalStyle = [NEStyleManager.instance isNormalStyle];
  UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 64)];
  _logoutButton = [UIButton buttonWithType:UIButtonTypeCustom];
  _logoutButton.backgroundColor = UIColor.whiteColor;
  _logoutButton.clipsToBounds = YES;
  _logoutButton.layer.cornerRadius = isNormalStyle ? 8.0 : 0.0;
  [_logoutButton setTitleColor:[UIColor colorWithRed:0xE6/255.0 green:0x60/255.0 blue:0x5C/255.0 alpha:1.0] forState:UIControlStateNormal];
  _logoutButton.titleLabel.font = [UIFont systemFontOfSize:16];
  [_logoutButton setTitle:NELocalizable(@"logout") forState:UIControlStateNormal];
  [_logoutButton addTarget:self action:@selector(logoutAction) forControlEvents:UIControlEventTouchUpInside];
  _logoutButton.accessibilityIdentifier = @"id.logout";
  [footerView addSubview:_logoutButton];
  if (isNormalStyle) {
    _logoutButton.frame = CGRectMake(20.0, 12.0, self.view.frame.size.width - 40.0, 40.0);
  } else {
    _logoutButton.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
      [_logoutButton.leftAnchor constraintEqualToAnchor:footerView.leftAnchor],
      [_logoutButton.rightAnchor constraintEqualToAnchor:footerView.rightAnchor],
      [_logoutButton.topAnchor constraintEqualToAnchor:footerView.topAnchor constant:12.0],
      [_logoutButton.heightAnchor constraintEqualToConstant:40.0],
    ]];
  }
  return footerView;
}

#pragma mark - Actions

- (void)showCloudConversationAlert:(BOOL)isOn {
  __weak typeof(self) weakSelf = self;
  [self showAlert:nil
          message:NELocalizable(@"restart_tips")
         sureText:NELocalizable(@"exit")
       cancelText:nil
    sureTextColor:[UIColor ne_colorWithHexString:@"0xE6605C"]
  cancelTextColor:nil
         sureBack:^{
           [NSUserDefaults.standardUserDefaults setBool:isOn forKey:kEnableCloudConversationKey];
           [NSUserDefaults.standardUserDefaults synchronize];
           exit(0);
         }
       cancelBack:^{
         [weakSelf.viewModel getData];
         [weakSelf.tableView reloadData];
       }];
}

- (void)logoutAction {
  __weak typeof(self) weakSelf = self;
  [self showAlert:nil
          message:NELocalizable(@"want_to_logout")
         sureText:nil
       cancelText:nil
    sureTextColor:nil
  cancelTextColor:nil
         sureBack:^{
    weakSelf.logoutButton.enabled = NO;
    [[IMKitClient instance] logoutIMWithCompletion:^(NSError * _Nullable logoutError) {
      weakSelf.logoutButton.enabled = YES;
      if (logoutError) {
        [weakSelf.view ne_makeToast:logoutError.localizedDescription ?: @""];
        return;
      }

      IMPocConfigModel *config = [[IMPocConfigManager instance] getConfig];
      config.accountId = nil;
      config.accountIdToken = nil;
      [[IMPocConfigManager instance] saveConfig:config];
      [[NEFriendUserCache shared] removeAllFriendInfo];
      [[NESubscribeManager shared] cleanCache];
      [[NSNotificationCenter defaultCenter] postNotificationName:NENotificationLogout object:nil];
    }];
  } cancelBack:nil];
}

- (void)delAccountBtnClick {
  __weak typeof(self) weakSelf = self;
  [self showAlert:nil
          message:NSLocalizedString(@"want_to_delete_account", nil)
         sureText:nil
       cancelText:nil
    sureTextColor:nil
  cancelTextColor:nil
         sureBack:^{
    [[IMKitClient instance] logoutIMWithCompletion:^(NSError * _Nullable logoutError) {
      if (logoutError) {
        [weakSelf.view ne_makeToast:logoutError.localizedDescription ?: @""];
        return;
      }
      [[NSNotificationCenter defaultCenter] postNotificationName:NENotificationLogout object:nil];
    }];
  } cancelBack:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return self.viewModel.sectionData.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.viewModel.sectionData.count > section ? self.viewModel.sectionData[section].cellModels.count : 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  SettingCellModel *model = self.viewModel.sectionData[indexPath.section].cellModels[indexPath.row];
  UITableViewCell *cell =
      [tableView dequeueReusableCellWithIdentifier:[NSString stringWithFormat:@"%ld", (long)model.type]
                                      forIndexPath:indexPath];
  if ([cell isKindOfClass:[NEBaseTeamSettingCell class]]) {
    [(NEBaseTeamSettingCell *)cell configure:model];
    cell.accessibilityIdentifier = [NSString stringWithFormat:@"id.%@", model.cellName ?: [NSString stringWithFormat:@"config%ld%ld", (long)indexPath.section, (long)indexPath.row]];
  }
  return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  SettingCellModel *model = self.viewModel.sectionData[indexPath.section].cellModels[indexPath.row];
  if (model.cellClick) {
    model.cellClick();
  }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  SettingCellModel *model = self.viewModel.sectionData[indexPath.section].cellModels[indexPath.row];
  return model.rowHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  if (section == 0) {
    return 0.0;
  }
  return self.viewModel.sectionData.count > section && self.viewModel.sectionData[section].cellModels.count > 0 ? 12.0 : 0.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  UIView *v = [[UIView alloc] init];
  v.backgroundColor = UIColor.clearColor;
  return v;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
  return section == self.viewModel.sectionData.count - 1 ? 12.0 : 0.0;
}

#pragma mark - MineSettingViewModelDelegate

- (void)didMessageRemindClick {
  [self.navigationController pushViewController:[[MessageRemindViewController alloc] init] animated:YES];
}

- (void)didStyleClick {
  [self.navigationController pushViewController:[[StyleSelectionViewController alloc] init] animated:YES];
}

- (void)didClickCleanCache {
}

- (void)didClickConfigTest {
  [self.navigationController pushViewController:[[ConfigTestViewController alloc] init] animated:YES];
}

- (void)didClickSDKConfig {
  [self.navigationController pushViewController:[[IMPocConfigViewController alloc] init] animated:YES];
}

- (void)didClickPushConfig {
  [self.navigationController pushViewController:[[IMPushConfigViewController alloc] init] animated:YES];
}

- (void)didClickLanguage {
  [self.navigationController pushViewController:[[LanguageViewController alloc] init] animated:YES];
}

- (void)didChangeConversationType:(void (^)(BOOL))cancel {
  __weak typeof(self) weakSelf = self;
  [self showAlert:nil
          message:NELocalizable(@"restart_tips")
         sureText:NELocalizable(@"exit")
       cancelText:nil
    sureTextColor:[UIColor ne_colorWithHexString:@"0xE6605C"]
  cancelTextColor:nil
         sureBack:^{
           if (cancel) {
             cancel(NO);
           }
           exit(0);
         }
       cancelBack:^{
         if (cancel) {
           cancel(YES);
         }
         [weakSelf.tableView reloadData];
       }];
}

@end
