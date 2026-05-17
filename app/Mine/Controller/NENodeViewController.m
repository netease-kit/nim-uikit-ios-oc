// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NENodeViewController.h"
#import "AppKey.h"
#import "NodeSelectCell.h"
#import "NodeViewModel.h"
#import <NEChatKitOC/NEConstant.h>
#import <NEChatKitOC/SettingRepo.h>
#import <NEChatKitOC/UIColor+NECommon.h>
#import <NECommonUIKitOC/NECommonUIConstant.h>
#import <NECommonUIKitOC/NENavigationView.h>

@interface NENodeViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NodeViewModel *viewModel;
@property (nonatomic, strong) UITableView *tableView;

@end

@implementation NENodeViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.viewModel = [[NodeViewModel alloc] init];
  [self.viewModel getData];
  [self setupUI];
}

- (void)setupUI {
  self.title = NELocalizable(@"node_select");
  self.view.backgroundColor = [UIColor ne_lightBackgroundColor];
  self.navigationView.backgroundColor = [UIColor ne_lightBackgroundColor];

  [self.view addSubview:self.tableView];
  [NSLayoutConstraint activateConstraints:@[
    [self.tableView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.tableView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [self.tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:NEConstant.navigationAndStatusHeight],
    [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
  ]];

  [self.tableView registerClass:[NodeSelectCell class]
         forCellReuseIdentifier:NSStringFromClass([NodeSelectCell class])];
}

- (void)showAlertForDomestic:(BOOL)isDomestic {
  UIAlertController *alertController =
      [UIAlertController alertControllerWithTitle:NELocalizable(@"change_node")
                                          message:NELocalizable(@"restart_take_effect")
                                   preferredStyle:UIAlertControllerStyleAlert];

  UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:commonLocalizable(@"cancel")
                                                         style:UIAlertActionStyleDefault
                                                       handler:nil];
  [alertController addAction:cancelAction];

  UIAlertAction *sureAction = [UIAlertAction actionWithTitle:NELocalizable(@"exit")
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(__unused UIAlertAction *action) {
    [[SettingRepo shared] setNodeValue:isDomestic];
    exit(0);
  }];
  [alertController addAction:sureAction];
  [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  (void)tableView;
  return self.viewModel.sectionData.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  (void)tableView;
  if ((NSUInteger)section < self.viewModel.sectionData.count) {
    return self.viewModel.sectionData[section].cellModels.count;
  }
  return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  SettingCellModel *model = self.viewModel.sectionData[indexPath.section].cellModels[indexPath.row];
  NodeSelectCell *cell =
      [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([NodeSelectCell class])
                                      forIndexPath:indexPath];
  [cell configureWithModel:model];
  return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  (void)tableView;
  [self showAlertForDomestic:(indexPath.row == 0)];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  (void)tableView;
  SettingCellModel *model = self.viewModel.sectionData[indexPath.section].cellModels[indexPath.row];
  return model.rowHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  (void)tableView;
  if ((NSUInteger)section < self.viewModel.sectionData.count &&
      self.viewModel.sectionData[section].cellModels.count > 0) {
    return 12.0;
  }
  return 0.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  (void)tableView;
  (void)section;
  UIView *headerView = [[UIView alloc] init];
  headerView.backgroundColor = [UIColor ne_lightBackgroundColor];
  return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
  (void)tableView;
  (void)section;
  return 0.0;
}

- (UITableView *)tableView {
  if (!_tableView) {
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _tableView.translatesAutoresizingMaskIntoConstraints = NO;
    _tableView.backgroundColor = [UIColor ne_lightBackgroundColor];
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
