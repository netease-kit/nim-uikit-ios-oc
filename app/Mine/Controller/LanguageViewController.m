// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "LanguageViewController.h"
#import "NEStyleManager.h"
#import "CustomThemeCells.h"
#import "AppKey.h"
#import <NEChatKit/NEAppLanguageUtil.h>
#import <NEChatKit/UIColor+NECommon.h>
#import <NEChatUIKitOC/FunChatUIColor.h>
#import <NECommonUIKitOC/NECommonUIConstant.h>
#import <NECommonUIKitOC/NENavigationView.h>
#import <NECommonUIKitOC/UIView+YXToast.h>
#import <NETeamUIKitOC/SettingCellModel.h>
#import <NETeamUIKitOC/SettingSectionModel.h>
#import <NETeamUIKitOC/NEBaseTeamSettingCell.h>

@interface LanguageViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray<SettingSectionModel *> *sectionData;
@property (nonatomic, strong) SettingCellModel *selectedModel;

@end

@implementation LanguageViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.sectionData = [NSMutableArray array];
  [self rebuildSectionData];
  [self setupSubviews];
  [self initialConfig];
}

- (void)initialConfig {
  self.title = NELocalizable(@"app_language");
  if ([NEStyleManager.instance isNormalStyle]) {
    self.view.backgroundColor = [UIColor ne_backgroundColor];
    self.navigationView.backgroundColor = [UIColor ne_backgroundColor];
    self.navigationController.navigationBar.backgroundColor = [UIColor ne_backgroundColor];
    [self.navigationView setMoreButtonTitle:NELocalizable(@"save") color:[UIColor ne_normalTheme]];
  } else {
    self.view.backgroundColor = [UIColor funChatBackgroundColor];
    [self.navigationView setMoreButtonTitle:NELocalizable(@"complete") color:[UIColor ne_funTheme]];
    [self.navigationView setMoreButtonWidth:[NEAppLanguageUtil getCurrentLanguage] == NEAppLanguageEnglish ? 80.0 : 34.0];
  }
  [self.navigationView addMoreButtonTarget:self selector:@selector(saveAction)];
}

- (void)rebuildSectionData {
  [self.sectionData removeAllObjects];

  BOOL isChinese = [NEAppLanguageUtil getCurrentLanguage] == NEAppLanguageChinese;
  SettingSectionModel *section = [[SettingSectionModel alloc] init];

  SettingCellModel *zh = [[SettingCellModel alloc] init];
  zh.cellName = NELocalizable(@"app_language_zh");
  zh.defaultHeadData = @"zh-Hans";
  zh.type = SettingCellTypeSettingSubtitleCustomCell;
  zh.titleWidth = 60.0;
  zh.rightCustomViewIcon = isChinese ? [UIImage imageNamed:@"language_select"] : UIImage.new;
  if (isChinese) {
    self.selectedModel = zh;
  }
  [section.cellModels addObject:zh];

  SettingCellModel *en = [[SettingCellModel alloc] init];
  en.cellName = NELocalizable(@"app_language_en");
  en.defaultHeadData = @"en";
  en.type = SettingCellTypeSettingSubtitleCustomCell;
  en.titleWidth = 60.0;
  en.rightCustomViewIcon = !isChinese ? [UIImage imageNamed:@"language_select"] : UIImage.new;
  if (!isChinese) {
    self.selectedModel = en;
  }
  [section.cellModels addObject:en];

  [section setCornerType];
  [self.sectionData addObject:section];
}

- (void)setupSubviews {
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
  [self.tableView registerClass:[CustomTeamSettingRightCustomCell class]
         forCellReuseIdentifier:[NSString stringWithFormat:@"%ld", (long)SettingCellTypeSettingSubtitleCustomCell]];
  [self.view addSubview:self.tableView];

  CGFloat top = self.topConstant + ([NEStyleManager.instance isNormalStyle] ? 12.0 : 0.0);
  [NSLayoutConstraint activateConstraints:@[
    [self.tableView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.tableView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [self.tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:top],
    [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
  ]];
}

- (void)saveAction {
  if (self.selectedModel.defaultHeadData.length > 0) {
    NEAppLanguage language = [self.selectedModel.defaultHeadData isEqualToString:@"zh-Hans"] ? NEAppLanguageChinese : NEAppLanguageEnglish;
    [NEAppLanguageUtil setCurrentLanguage:language];
    [[NSNotificationCenter defaultCenter] postNotificationName:NENotificationChangeLanguage object:nil];
  } else {
    [self.view ne_makeToast:commonLocalizable(@"failed_operation")];
  }
  [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return self.sectionData.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.sectionData.count > section ? self.sectionData[section].cellModels.count : 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  SettingCellModel *model = self.sectionData[indexPath.section].cellModels[indexPath.row];
  UITableViewCell *cell =
      [tableView dequeueReusableCellWithIdentifier:[NSString stringWithFormat:@"%ld", (long)model.type]
                                      forIndexPath:indexPath];
  if ([cell isKindOfClass:[NEBaseTeamSettingCell class]]) {
    [(NEBaseTeamSettingCell *)cell configure:model];
  }
  return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  for (NSInteger i = 0; i < (NSInteger)self.sectionData[indexPath.section].cellModels.count; i++) {
    SettingCellModel *model = self.sectionData[indexPath.section].cellModels[i];
    BOOL isSelected = i == indexPath.row;
    model.rightCustomViewIcon = isSelected ? [UIImage imageNamed:@"language_select"] : UIImage.new;
    if (isSelected) {
      self.selectedModel = model;
    }
  }
  [tableView reloadData];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  SettingCellModel *model = self.sectionData[indexPath.section].cellModels[indexPath.row];
  return model.rowHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  if (section == 0) {
    return 0.0;
  }
  return self.sectionData.count > section && self.sectionData[section].cellModels.count > 0 ? 12.0 : 0.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  UIView *headerView = [[UIView alloc] init];
  headerView.backgroundColor = [UIColor ne_lightBackgroundColor];
  return headerView;
}

@end
