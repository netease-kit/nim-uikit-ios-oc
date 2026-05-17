// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "MessageRemindViewController.h"
#import "NEStyleManager.h"
#import "CustomThemeCells.h"
#import "AppKey.h"
#import <NEChatKitOC/SettingRepo.h>
#import <NEChatKitOC/UIColor+NECommon.h>
#import <NEChatUIKitOC/FunChatUIColor.h>
#import <NECommonUIKitOC/NENavigationView.h>
#import <NETeamUIKitOC/SettingCellModel.h>
#import <NETeamUIKitOC/SettingSectionModel.h>
#import <NETeamUIKitOC/NEBaseTeamSettingCell.h>

@interface MessageRemindViewModel : NSObject
@property (nonatomic, strong) NSArray<SettingSectionModel *> *sectionData;
- (void)getData;
@end

@implementation MessageRemindViewModel

- (instancetype)init {
  self = [super init];
  if (self) {
    _sectionData = @[];
  }
  return self;
}

- (void)getData {
  self.sectionData = @[[self getFirstSection]];
}

- (SettingSectionModel *)getFirstSection {
  SettingSectionModel *model = [[SettingSectionModel alloc] init];
  __weak typeof(self) weakSelf = self;

  SettingCellModel *messageNotify = [[SettingCellModel alloc] init];
  messageNotify.cellName = NELocalizable(@"new_message_remind");
  messageNotify.type = SettingCellTypeSettingSwitchCell;
  messageNotify.switchOpen = [SettingRepo.shared getPushEnable];
  messageNotify.swichChange = ^(BOOL isOpen) {
    [weakSelf setMessageNotifyModel:messageNotify isOpen:isOpen];
  };
  [model.cellModels addObject:messageNotify];

  SettingCellModel *messageDetailItem = [[SettingCellModel alloc] init];
  messageDetailItem.cellName = NELocalizable(@"display_message_detail");
  messageDetailItem.type = SettingCellTypeSettingSwitchCell;
  messageDetailItem.switchOpen = [SettingRepo.shared getPushDetailEnable];
  messageDetailItem.swichChange = ^(BOOL isOpen) {
    [weakSelf setPushDetailModel:messageDetailItem isOpen:isOpen];
  };
  [model.cellModels addObject:messageDetailItem];

  [model setCornerType];
  return model;
}

- (void)setMessageNotifyModel:(SettingCellModel *)model isOpen:(BOOL)isOpen {
  [SettingRepo.shared setMessageNotify:isOpen completion:^(NSError *error) {
    if (error) {
      model.switchOpen = !isOpen;
    }
  }];
}

- (void)setPushDetailModel:(SettingCellModel *)model isOpen:(BOOL)isOpen {
  [SettingRepo.shared setPushShowDetail:isOpen completion:^(NSError *error) {
    if (error) {
      model.switchOpen = !isOpen;
    }
  }];
}

@end

@interface MessageRemindViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) MessageRemindViewModel *viewModel;
@property (nonatomic, strong) NSDictionary<NSNumber *, Class> *cellClassDic;

@end

@implementation MessageRemindViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.viewModel = [[MessageRemindViewModel alloc] init];
  [self.viewModel getData];
  [self setupSubviews];
  [self initialConfig];
}

- (void)initialConfig {
  self.title = NELocalizable(@"message_remind");
  if ([NEStyleManager.instance isNormalStyle]) {
    self.view.backgroundColor = [UIColor ne_backgroundColor];
    self.navigationView.backgroundColor = [UIColor ne_backgroundColor];
    self.navigationController.navigationBar.backgroundColor = [UIColor ne_backgroundColor];
  } else {
    self.view.backgroundColor = [UIColor funChatBackgroundColor];
  }
  self.navigationView.moreButton.hidden = YES;
}

- (void)setupSubviews {
  BOOL isNormalStyle = [NEStyleManager.instance isNormalStyle];
  self.cellClassDic = @{
    @(SettingCellTypeSettingSwitchCell): [CustomTeamSettingSwitchCell class],
  };

  self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
  self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
  self.tableView.backgroundColor = UIColor.clearColor;
  self.tableView.dataSource = self;
  self.tableView.delegate = self;
  self.tableView.separatorColor = UIColor.clearColor;
  self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
  self.tableView.sectionHeaderHeight = 12.0;
  self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
  self.tableView.estimatedRowHeight = 0;
  self.tableView.estimatedSectionHeaderHeight = 0;
  self.tableView.estimatedSectionFooterHeight = 0;
  if (@available(iOS 15.0, *)) {
    self.tableView.sectionHeaderTopPadding = 0;
  }

  for (NSNumber *key in self.cellClassDic) {
    [self.tableView registerClass:self.cellClassDic[key]
           forCellReuseIdentifier:[NSString stringWithFormat:@"%ld", (long)key.integerValue]];
  }

  [self.view addSubview:self.tableView];

  CGFloat top = self.topConstant + (isNormalStyle ? 12.0 : 0.0);
  [NSLayoutConstraint activateConstraints:@[
    [self.tableView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.tableView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [self.tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:top],
    [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
  ]];
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
  }
  return cell;
}

#pragma mark - UITableViewDelegate

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
  UIView *headerView = [[UIView alloc] init];
  headerView.backgroundColor = [UIColor ne_lightBackgroundColor];
  return headerView;
}

@end
