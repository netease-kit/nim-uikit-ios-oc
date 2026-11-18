// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "IMPocConfigViewController.h"
#import <NEBaseUIKitOC/NEAdaptiveDeviceGate.h>
#import "AppKey.h"
#import "IMPocConfigManager.h"
#import "NEStyleManager.h"
#import "CustomSettingCellModel.h"
#import "CustomSettingInputCell.h"
#import "CustomSettingTextviewCell.h"
#import "CustomThemeCells.h"
#import "ArrowTitleCustomTeamSettingSwitchCell.h"
#import <NEChatKit/NEConstant.h>
#import <NEChatKit/UIColor+NECommon.h>
#import <NEChatUIKitOC/FunChatUIColor.h>
#import <NEBaseUIKitOC/NEBaseUIKitOC.h>
#import <NEBaseUIKitOC/NECommonUIConstant.h>
#import <NEBaseUIKitOC/NENavigationView.h>
#import <NIMSDK/NIMSDK.h>
#import <NETeamUIKitOC/SettingCellModel.h>
#import <NETeamUIKitOC/SettingSectionModel.h>
#import <NETeamUIKitOC/NEBaseTeamSettingCell.h>

@interface IMPocConfigViewController () <UITableViewDelegate, UITableViewDataSource>

@property(nonatomic, strong) NSDictionary<NSNumber *, Class> *cellClassDic;
@property(nonatomic, strong) NSMutableArray<SettingSectionModel *> *sectionData;
@property(nonatomic, strong) UITableView *contentTableView;
@property(nonatomic, strong) IMPocConfigModel *configModel;
@property(nonatomic, strong) SettingSectionModel *twoSectionModel;
@property(nonatomic, strong) SettingSectionModel *customSectionModel;
@property(nonatomic, strong) CustomSettingCellModel *autoConfig;
@property(nonatomic, assign) BOOL isCustomJsonParse;

@end

@implementation IMPocConfigViewController

- (instancetype)init {
  self = [super init];
  if (self) {
    _configModel = [[IMPocConfigManager instance] getConfig];
    _cellClassDic = @{
      @(SettingCellTypeSettingSwitchCell) : [CustomTeamSettingSwitchCell class],
      @(SettingCellTypeSettingArrowCell) : [ArrowTitleCustomTeamSettingSwitchCell class],
      @(SettingCellTypeSettingSubtitleCell) : [CustomSettingInputCell class],
      @(SettingCellTypeSettingSubtitleCustomCell) : [CustomSettingTextviewCell class],
    };
    _sectionData = [NSMutableArray array];
    _twoSectionModel = [[SettingSectionModel alloc] init];
    _customSectionModel = [[SettingSectionModel alloc] init];
    _autoConfig = [[CustomSettingCellModel alloc] init];
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.title = NELocalizable(@"private_cloud_config");
  [self setupCellData];
  [self setupConfigUI];
}

- (void)setupConfigUI {
  self.navigationView.moreButton.hidden = YES;
  self.view.backgroundColor = [NEStyleManager.instance isNormalStyle] ? [UIColor ne_backgroundColor] : [UIColor funChatBackgroundColor];

  self.contentTableView = [[UITableView alloc] init];
  self.contentTableView.separatorColor = UIColor.clearColor;
  self.contentTableView.translatesAutoresizingMaskIntoConstraints = NO;
  self.contentTableView.backgroundColor = UIColor.clearColor;
  self.contentTableView.dataSource = self;
  self.contentTableView.delegate = self;
  self.contentTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
  self.contentTableView.sectionHeaderHeight = 12.0;
  self.contentTableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
  self.contentTableView.estimatedRowHeight = 0;
  self.contentTableView.estimatedSectionHeaderHeight = 0;
  self.contentTableView.estimatedSectionFooterHeight = 0;
  if (@available(iOS 15.0, *)) {
    self.contentTableView.sectionHeaderTopPadding = 0.0;
  }

  [self.view addSubview:self.contentTableView];
  [NSLayoutConstraint activateConstraints:@[
    [self.contentTableView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.contentTableView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [self.contentTableView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:NEUIKitStatusBarHeight() + NEConstant.navigationHeight],
    [self.contentTableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
  ]];

  self.contentTableView.tableFooterView = [self getFooterView];

  for (NSNumber *key in self.cellClassDic) {
    [self.contentTableView registerClass:self.cellClassDic[key]
                  forCellReuseIdentifier:[NSString stringWithFormat:@"%ld", (long)key.integerValue]];
  }
}

- (void)setupCellData {
  SettingSectionModel *oneSectionModel = [[SettingSectionModel alloc] init];
  [self.sectionData addObject:oneSectionModel];

  SettingCellModel *usePrivateConfigModel = [[SettingCellModel alloc] init];
  usePrivateConfigModel.cellName = @"私有化环境配置生效";
  usePrivateConfigModel.type = SettingCellTypeSettingSwitchCell;
  usePrivateConfigModel.switchOpen = self.configModel.enableCustomConfig.boolValue;
  __weak typeof(self) weakSelf = self;
  usePrivateConfigModel.swichChange = ^(BOOL isOpen) {
    weakSelf.configModel.enableCustomConfig = @(isOpen);
  };
  [oneSectionModel.cellModels addObject:usePrivateConfigModel];
  [oneSectionModel setCornerType];

  SettingCellModel *configType = [[SettingCellModel alloc] init];
  configType.cellName = @"配置方式";
  configType.subTitle = @"手动填写";
  configType.type = SettingCellTypeSettingArrowCell;
  [self.twoSectionModel.cellModels addObject:configType];

#define NE_ADD_INPUT_ITEM(_title, _key) \
  do { \
    CustomSettingCellModel *item = [[CustomSettingCellModel alloc] init]; \
    item.cellName = _title; \
    item.type = SettingCellTypeSettingSubtitleCell; \
    item.inputKey = _key; \
    id value = self.configModel.configMap[item.inputKey]; \
    if ([value isKindOfClass:[NSString class]]) { \
      item.customInputText = value; \
    } \
    [self.twoSectionModel.cellModels addObject:item]; \
  } while (0)

  NE_ADD_INPUT_ITEM(@"AppKey", @"appKey");
  NE_ADD_INPUT_ITEM(@"Module", @"module");
  NE_ADD_INPUT_ITEM(@"服务器Link地址", @"linkAddress");
  NE_ADD_INPUT_ITEM(@"LBS服务器地址", @"lbsAddress");
  NE_ADD_INPUT_ITEM(@"NOS上传LBS服务器地址", @"nosLbsAddress");
  NE_ADD_INPUT_ITEM(@"NOS上传LBS服务器默认Link服务器地址", @"nosUploadAddress");
  NE_ADD_INPUT_ITEM(@"NOS拼接下载地址", @"nosDownloadAddress");
  NE_ADD_INPUT_ITEM(@"NOS上传服务器主机地址", @"nosUploadHost");

#undef NE_ADD_INPUT_ITEM

  [self.twoSectionModel setCornerType];

  CustomSettingCellModel *autoConfigType = [[CustomSettingCellModel alloc] init];
  autoConfigType.cellName = @"配置方式";
  autoConfigType.subTitle = @"一键自动解析";
  autoConfigType.type = SettingCellTypeSettingArrowCell;
  autoConfigType.rowHeight = 49.0;
  [self.customSectionModel.cellModels addObject:autoConfigType];

  self.autoConfig.cellName = @"填写私有化配置内容";
  self.autoConfig.type = SettingCellTypeSettingSubtitleCustomCell;
  self.autoConfig.rowHeight = 200.0;
  self.autoConfig.customInputText = self.configModel.customJson;
  [self.customSectionModel.cellModels addObject:self.autoConfig];
  [self.customSectionModel setCornerType];

  [self.sectionData addObject:self.customSectionModel];
}

- (void)didSave {
  for (SettingCellModel *model in self.twoSectionModel.cellModels) {
    if ([model isKindOfClass:[CustomSettingCellModel class]]) {
      CustomSettingCellModel *customModel = (CustomSettingCellModel *)model;
      if (customModel.inputKey.length > 0) {
        if (customModel.customInputText.length > 0) {
          self.configModel.configMap[customModel.inputKey] = customModel.customInputText;
        } else {
          [self.configModel.configMap removeObjectForKey:customModel.inputKey];
        }
      }
    }
  }

  self.configModel.customJson = self.autoConfig.customInputText.length > 0 ? self.autoConfig.customInputText : nil;
  [self showToast:@"保存成功，请重新启动应用登录"];
  [[IMPocConfigManager instance] saveConfig:self.configModel];
  [self.navigationController popViewControllerAnimated:YES];
}

- (void)autoParse {
  if (self.sectionData.count == 2) {
    [self.sectionData removeObjectAtIndex:1];
    [self.sectionData addObject:self.customSectionModel];
  }
  self.isCustomJsonParse = YES;
  [self.contentTableView reloadData];
}

- (void)customParse {
  if (self.sectionData.count == 2) {
    [self.sectionData removeObjectAtIndex:1];
    [self.sectionData addObject:self.twoSectionModel];
  }
  self.isCustomJsonParse = NO;
  [self.contentTableView reloadData];
}

- (void)changeParseModel {
  if ([NEStyleManager.instance isNormalStyle]) {
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    __weak typeof(self) weakSelf = self;
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"一键自动解析" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
      [weakSelf autoParse];
    }]];
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"手动填写" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
      [weakSelf customParse];
    }]];
    [actionSheet addAction:[UIAlertAction actionWithTitle:commonLocalizable(@"cancel") style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:actionSheet animated:YES completion:nil];
  } else {
    __weak typeof(self) weakSelf = self;
    NECustomAlertAction *autoAction = [NECustomAlertAction actionWithTitle:@"一键自动解析" handler:^{
      [weakSelf autoParse];
    }];
    NECustomAlertAction *customAction = [NECustomAlertAction actionWithTitle:@"手动填写" handler:^{
      [weakSelf customParse];
    }];
    [self showCustomActionSheet:@[ autoAction, customAction ]];
  }
}

- (UIView *)getFooterView {
  UIView *back = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 60)];
  back.backgroundColor = UIColor.clearColor;
  ExpandButton *button = [[ExpandButton alloc] init];
  [back addSubview:button];
  if (NEAdaptiveDeviceGate.adaptiveHostActive) {
    button.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  }
  [button setTitle:NELocalizable(@"save") forState:UIControlStateNormal];
  [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
  if ([NEStyleManager.instance isNormalStyle]) {
    button.backgroundColor = [UIColor ne_normalTheme];
    button.frame = CGRectMake(20, 10, self.view.frame.size.width - 40, 40);
  } else {
    button.frame = CGRectMake(0, 10, self.view.frame.size.width, 40);
    button.backgroundColor = [UIColor ne_funTheme];
  }
  [button addTarget:self action:@selector(didSave) forControlEvents:UIControlEventTouchUpInside];
  return back;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  (void)tableView;
  return self.sectionData.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  (void)tableView;
  if ((NSUInteger)section < self.sectionData.count) {
    return self.sectionData[section].cellModels.count;
  }
  return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  SettingCellModel *model = self.sectionData[indexPath.section].cellModels[indexPath.row];
  NEBaseTeamSettingCell *cell = [tableView dequeueReusableCellWithIdentifier:[NSString stringWithFormat:@"%ld", (long)model.type]
                                                                forIndexPath:indexPath];
  [cell configure:model];
  return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  (void)tableView;
  return self.sectionData[indexPath.section].cellModels[indexPath.row].rowHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  (void)tableView;
  (void)section;
  return 10.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
  (void)tableView;
  return section == 0 ? 40.0 : 0.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  (void)tableView;
  (void)section;
  UIView *headerView = [[UIView alloc] init];
  headerView.backgroundColor = UIColor.clearColor;
  return headerView;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
  (void)tableView;
  UIView *footerView = [[UIView alloc] init];
  footerView.backgroundColor = UIColor.clearColor;
  UILabel *label = [[UILabel alloc] init];
  label.translatesAutoresizingMaskIntoConstraints = NO;
  label.textColor = [UIColor ne_darkText];
  label.font = [UIFont systemFontOfSize:16];
  label.text = @"配置私有化参数";
  [footerView addSubview:label];

  CGFloat leftMargin = [NEStyleManager.instance isNormalStyle] ? 36.0 : 20.0;
  CGFloat rightMargin = [NEStyleManager.instance isNormalStyle] ? -36.0 : -20.0;
  [NSLayoutConstraint activateConstraints:@[
    [label.leftAnchor constraintEqualToAnchor:footerView.leftAnchor constant:leftMargin],
    [label.rightAnchor constraintEqualToAnchor:footerView.rightAnchor constant:rightMargin],
    [label.bottomAnchor constraintEqualToAnchor:footerView.bottomAnchor],
  ]];
  return section == 0 ? footerView : nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  (void)tableView;
  if (indexPath.section == 1 && indexPath.row == 0) {
    [self changeParseModel];
  }
}

@end
