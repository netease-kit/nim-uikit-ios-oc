// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "ConfigTestViewController.h"
#import "AppKey.h"
#import "NEStyleManager.h"
#import "CustomSettingCellModel.h"
#import "CustomSettingTextviewCell.h"
#import "CustomThemeCells.h"
#import <NEChatKit/ChatConstant.h>
#import <NEChatKit/NEConstant.h>
#import <NEChatKit/IMKitConfigCenter.h>
#import <NEChatKit/UIColor+NECommon.h>
#import <NEChatUIKitOC/FunChatUIColor.h>
#import <NECommonUIKitOC/NECommonUIConstant.h>
#import <NECommonUIKitOC/NEConfigManager.h>
#import <NECommonUIKitOC/NENavigationView.h>
#import <NETeamUIKitOC/SettingCellModel.h>
#import <NETeamUIKitOC/SettingSectionModel.h>
#import <NETeamUIKitOC/NEBaseTeamSettingCell.h>

@interface ConfigTestViewController () <UITableViewDelegate, UITableViewDataSource>

@property(nonatomic, strong) NSDictionary<NSNumber *, Class> *cellClassDic;
@property(nonatomic, strong) NSMutableArray<SettingSectionModel *> *sectionData;
@property(nonatomic, strong) UITableView *tableView;
@property(nonatomic, strong) CustomSettingCellModel *recentForwardListMaxCountModel;
@property(nonatomic, strong) CustomSettingCellModel *teamManagerCountModel;

@end

@implementation ConfigTestViewController

- (instancetype)init {
  self = [super init];
  if (self) {
    _cellClassDic = @{
      @(SettingCellTypeSettingSwitchCell) : [CustomTeamSettingSwitchCell class],
      @(SettingCellTypeSettingSubtitleCell) : [CustomSettingTextviewCell class],
    };
    _sectionData = [NSMutableArray array];
    _recentForwardListMaxCountModel = [[CustomSettingCellModel alloc] init];
    _teamManagerCountModel = [[CustomSettingCellModel alloc] init];
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [self.sectionData addObject:[self getSectionData]];
  [self setupSubviews];
  [self initialConfig];
}

- (SettingSectionModel *)getSectionData {
  SettingSectionModel *model = [[SettingSectionModel alloc] init];

  SettingCellModel *useSysNav = [[SettingCellModel alloc] init];
  useSysNav.cellName = @"使用系统导航栏";
  useSysNav.type = SettingCellTypeSettingSwitchCell;
  id sysNavValue = [NEConfigManager.instance getParameterForKey:useSystemNav];
  useSysNav.switchOpen = [sysNavValue isKindOfClass:[NSNumber class]] ? [sysNavValue boolValue] : NO;
  useSysNav.swichChange = ^(BOOL isOpen) {
    [NEConfigManager.instance setParameter:@(isOpen) forKey:useSystemNav];
  };
  [model.cellModels addObject:useSysNav];

#define NE_ADD_SWITCH_ITEM(_name, _getter, _setter) \
  do { \
    SettingCellModel *item = [[SettingCellModel alloc] init]; \
    item.cellName = _name; \
    item.type = SettingCellTypeSettingSwitchCell; \
    item.switchOpen = (_getter); \
    item.swichChange = ^(BOOL isOpen) { _setter = isOpen; }; \
    [model.cellModels addObject:item]; \
  } while (0)

  NE_ADD_SWITCH_ITEM(@"显示群聊", IMKitConfigCenter.shared.enableTeam, IMKitConfigCenter.shared.enableTeam);
  NE_ADD_SWITCH_ITEM(@"群聊申请邀请功能", IMKitConfigCenter.shared.enableTeamJoinAgreeModelAuth, IMKitConfigCenter.shared.enableTeamJoinAgreeModelAuth);
  NE_ADD_SWITCH_ITEM(@"显示收藏", IMKitConfigCenter.shared.enableCollectionMessage, IMKitConfigCenter.shared.enableCollectionMessage);
  NE_ADD_SWITCH_ITEM(@"显示标记", IMKitConfigCenter.shared.enablePinMessage, IMKitConfigCenter.shared.enablePinMessage);
  NE_ADD_SWITCH_ITEM(@"显示置顶", IMKitConfigCenter.shared.enableTopMessage, IMKitConfigCenter.shared.enableTopMessage);
  NE_ADD_SWITCH_ITEM(@"显示在线状态", IMKitConfigCenter.shared.enableOnlineStatus, IMKitConfigCenter.shared.enableOnlineStatus);
  NE_ADD_SWITCH_ITEM(@"撤回消息后是否插入提示消息", IMKitConfigCenter.shared.enableInsertLocalMsgWhenRevoke, IMKitConfigCenter.shared.enableInsertLocalMsgWhenRevoke);

  SettingCellModel *cloudSearch = [[SettingCellModel alloc] init];
  cloudSearch.cellName = @"使用云端搜索";
  cloudSearch.type = SettingCellTypeSettingSwitchCell;
  cloudSearch.switchOpen = IMKitConfigCenter.shared.enableCloudMessageSearch;
  cloudSearch.swichChange = ^(BOOL isOpen) {
    IMKitConfigCenter.shared.enableCloudMessageSearch = isOpen;
    [NSUserDefaults.standardUserDefaults setBool:isOpen forKey:@"yxEnableCloudMessageSearch"];
  };
  [model.cellModels addObject:cloudSearch];

  NE_ADD_SWITCH_ITEM(@"陌生人能否进行音视频通话", IMKitConfigCenter.shared.enableOnlyFriendCall, IMKitConfigCenter.shared.enableOnlyFriendCall);
  NE_ADD_SWITCH_ITEM(@"无效群聊是否删除会话", IMKitConfigCenter.shared.enableDismissTeamDeleteConversation, IMKitConfigCenter.shared.enableDismissTeamDeleteConversation);
  NE_ADD_SWITCH_ITEM(@"开启数字人", IMKitConfigCenter.shared.enableAIUser, IMKitConfigCenter.shared.enableAIUser);
  NE_ADD_SWITCH_ITEM(@"消息流式输出", IMKitConfigCenter.shared.enableAIStream, IMKitConfigCenter.shared.enableAIStream);
  NE_ADD_SWITCH_ITEM(@"AI 助聊", IMKitConfigCenter.shared.enableAIChatHelper, IMKitConfigCenter.shared.enableAIChatHelper);
  NE_ADD_SWITCH_ITEM(@"允许发送【换行消息】", IMKitConfigCenter.shared.enableRichTextMessage, IMKitConfigCenter.shared.enableRichTextMessage);
  NE_ADD_SWITCH_ITEM(@"文本安全提示", IMKitConfigCenter.shared.enableAntiSpamTipMessage, IMKitConfigCenter.shared.enableAntiSpamTipMessage);

#undef NE_ADD_SWITCH_ITEM

  self.recentForwardListMaxCountModel.cellName = @"最近转发的会话 id 列表最大长度";
  self.recentForwardListMaxCountModel.type = SettingCellTypeSettingSubtitleCell;
  self.recentForwardListMaxCountModel.customInputText =
      [NSString stringWithFormat:@"%ld", (long)IMKitConfigCenter.shared.recentForwardListMaxCount];
  [model.cellModels addObject:self.recentForwardListMaxCountModel];

  self.teamManagerCountModel.cellName = @"允许添加的管理员人数( -1 表示无限制)";
  self.teamManagerCountModel.type = SettingCellTypeSettingSubtitleCell;
  self.teamManagerCountModel.customInputText =
      [NSString stringWithFormat:@"%ld", (long)IMKitConfigCenter.shared.teamManagerMaxCount];
  [model.cellModels addObject:self.teamManagerCountModel];

  [model setCornerType];
  return model;
}

- (void)initialConfig {
  self.title = @"全局配置";
  if ([NEStyleManager.instance isNormalStyle]) {
    self.view.backgroundColor = [UIColor ne_backgroundColor];
    self.navigationView.backgroundColor = [UIColor ne_backgroundColor];
    self.navigationController.navigationBar.backgroundColor = [UIColor ne_backgroundColor];
    [self.navigationView.moreButton setTitleColor:[UIColor ne_greyText] forState:UIControlStateNormal];
  } else {
    self.view.backgroundColor = [UIColor funChatBackgroundColor];
    [self.navigationView.moreButton setTitleColor:[UIColor ne_funTheme] forState:UIControlStateNormal];
  }
}

- (void)setupSubviews {
  self.navigationView.moreButton.hidden = NO;
  [self.navigationView setMoreButtonTitle:@"保存" color:[UIColor ne_normalTheme]];
  [self.navigationView addMoreButtonTarget:self selector:@selector(saveConfig)];

  UILabel *tipLabel = [[UILabel alloc] init];
  tipLabel.translatesAutoresizingMaskIntoConstraints = NO;
  tipLabel.text = @"点击保存生效";
  tipLabel.textColor = [UIColor ne_greyText];
  tipLabel.font = [UIFont systemFontOfSize:14];
  tipLabel.textAlignment = NSTextAlignmentCenter;
  [self.view addSubview:tipLabel];
  [NSLayoutConstraint activateConstraints:@[
    [tipLabel.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [tipLabel.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [tipLabel.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:NEConstant.navigationAndStatusHeight],
    [tipLabel.heightAnchor constraintEqualToConstant:20],
  ]];

  [self.view addSubview:self.tableView];
  [NSLayoutConstraint activateConstraints:@[
    [self.tableView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.tableView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [self.tableView.topAnchor constraintEqualToAnchor:tipLabel.bottomAnchor],
    [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
  ]];

  for (NSNumber *key in self.cellClassDic) {
    [self.tableView registerClass:self.cellClassDic[key]
           forCellReuseIdentifier:[NSString stringWithFormat:@"%ld", (long)key.integerValue]];
  }
}

- (void)saveConfig {
  NSString *forwardText = self.recentForwardListMaxCountModel.customInputText;
  if (forwardText.length > 0) {
    NSInteger val = forwardText.integerValue;
    if (val > 0) {
      IMKitConfigCenter.shared.recentForwardListMaxCount = val;
    }
  }

  NSString *managerText = self.teamManagerCountModel.customInputText;
  if (managerText.length > 0) {
    NSInteger val = managerText.integerValue;
    if (val >= -1) {
      IMKitConfigCenter.shared.teamManagerMaxCount = val;
    }
  }

  [[NSNotificationCenter defaultCenter] postNotificationName:NENotificationChangeUI object:nil];
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
  cell.accessibilityIdentifier = [NSString stringWithFormat:@"id.%@", model.cellName ?: @""];
  return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  (void)tableView;
  return self.sectionData[indexPath.section].cellModels[indexPath.row].rowHeight;
}

- (UITableView *)tableView {
  if (!_tableView) {
    _tableView = [[UITableView alloc] init];
    _tableView.translatesAutoresizingMaskIntoConstraints = NO;
    _tableView.backgroundColor = UIColor.clearColor;
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.separatorColor = UIColor.clearColor;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.sectionHeaderHeight = 12.0;
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
