// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseTeamInfoViewController.h"
#import "TeamConstant.h"
#import "NEBaseTeamSettingCell.h"
#import <NEChatKit/NECoreIM2Constant.h>

@interface NEBaseTeamInfoViewController ()
@property (nonatomic, strong, readwrite) TeamInfoViewModel *viewModel;
@property (nonatomic, strong, readwrite) UITableView *contentTableView;
@end

@implementation NEBaseTeamInfoViewController

- (instancetype)initWithTeam:(V2NIMTeam *)team {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _team = team;
    _registerCellDic = [NSMutableDictionary dictionary];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    _registerCellDic = [NSMutableDictionary dictionary];
  }
  return self;
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  if ([self.team.serverExtension containsString:discussTeamKey]) {
    self.title = NETeamUIKitLocalizable(@"discuss_info");
  } else {
    self.title = NETeamUIKitLocalizable(@"group_info");
  }
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.viewModel.delegate = self;
  [self.viewModel getData:self.team];
  [self setupUI];
}

- (void)setupUI {
  [self.view addSubview:self.contentTableView];
  [NSLayoutConstraint activateConstraints:@[
    [self.contentTableView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.contentTableView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [self.contentTableView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:self.topConstant],
    [self.contentTableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
  ]];

  [self.registerCellDic enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, Class  _Nonnull cls, __unused BOOL * _Nonnull stop) {
    [self.contentTableView registerClass:cls forCellReuseIdentifier:key.stringValue];
  }];
  self.navigationView.moreButton.hidden = YES;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.viewModel.cellDatas.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  SettingCellModel *model = self.viewModel.cellDatas[indexPath.row];
  return model.rowHeight;
}

- (void)teamInfoDidUpdate:(V2NIMTeam *)team {
  self.team = team;
  [self.contentTableView reloadData];
}

- (TeamInfoViewModel *)viewModel {
  if (!_viewModel) {
    _viewModel = [[TeamInfoViewModel alloc] init];
  }
  return _viewModel;
}

- (UITableView *)contentTableView {
  if (!_contentTableView) {
    _contentTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _contentTableView.translatesAutoresizingMaskIntoConstraints = NO;
    _contentTableView.backgroundColor = UIColor.clearColor;
    _contentTableView.dataSource = self;
    _contentTableView.delegate = self;
    _contentTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _contentTableView.sectionHeaderHeight = 0.0;
    _contentTableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    _contentTableView.estimatedRowHeight = 0.0;
    _contentTableView.estimatedSectionHeaderHeight = 0.0;
    _contentTableView.estimatedSectionFooterHeight = 0.0;
    if (@available(iOS 15.0, *)) {
      _contentTableView.sectionHeaderTopPadding = 0.0;
    }
  }
  return _contentTableView;
}

@end
