// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseTeamMemberSelectController.h"
#import "TeamConstant.h"
#import "NESelectTeamMember.h"
#import "NEBaseTeamMemberSelectCell.h"
#import <NEChatKitOC/NEChatKitOC.h>
#import <NEChatKitOC/NECommonLoader.h>
#import <NEChatKitOC/NEConstant.h>
#import <NEChatKitOC/UIColor+NECommon.h>
#import <NECommonUIKitOC/UIView+YXToast.h>

@interface NEBaseTeamMemberSelectController ()
@property (nonatomic, strong, readwrite) TeamMemberSelectViewModel *viewModel;
@property (nonatomic, strong, readwrite) UITextField *searchInput;
@property (nonatomic, strong, readwrite) UITableView *contentTableView;
@property (nonatomic, strong, readwrite) UIView *searchBackView;
@property (nonatomic, strong, readwrite) UIImageView *searchImageView;
@end

@implementation NEBaseTeamMemberSelectController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    _showAllMembers = NO;
    _selectCountLimit = 10;
    _cellClassDic = [NSMutableDictionary dictionary];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    _showAllMembers = NO;
    _selectCountLimit = 10;
    _cellClassDic = [NSMutableDictionary dictionary];
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  [self.emptyView setEmptyImageName:@"user_empty"];
  self.emptyView.message = NETeamUIKitLocalizable(@"member_select_no_member");
  self.viewModel.delegate = self;
  [self setupUI];
  if (self.teamId.length > 0) {
    __weak typeof(self) weakSelf = self;
    [self.viewModel getTeamInfo:self.teamId showAllMembers:self.showAllMembers completion:^(NSError * _Nullable error) {
      if (error) {
        [weakSelf.view ne_makeToast:NETeamUIKitErrorToast(error)];
      } else {
        [weakSelf didReloadTableData];
      }
    }];
  }
}

- (void)didReloadTableData {
  self.emptyView.hidden = self.viewModel.showDatas.count > 0;
  [self.contentTableView reloadData];
}

- (void)setupUI {
  self.view.backgroundColor = UIColor.whiteColor;
  [self.view addSubview:self.contentTableView];

  [self.view addSubview:self.searchBackView];
  self.searchBackView.backgroundColor = [UIColor ne_colorWithHexString:@"#F2F4F5"];
  self.searchBackView.translatesAutoresizingMaskIntoConstraints = NO;
  self.searchBackView.clipsToBounds = YES;
  self.searchBackView.layer.cornerRadius = 4.0;
  [NSLayoutConstraint activateConstraints:@[
    [self.searchBackView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:20.0],
    [self.searchBackView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant:-20.0],
    [self.searchBackView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:13.0 + self.topConstant],
    [self.searchBackView.heightAnchor constraintEqualToConstant:32.0],
  ]];

  [self.searchBackView addSubview:self.searchImageView];
  [NSLayoutConstraint activateConstraints:@[
    [self.searchImageView.centerYAnchor constraintEqualToAnchor:self.searchBackView.centerYAnchor],
    [self.searchImageView.leftAnchor constraintEqualToAnchor:self.searchBackView.leftAnchor constant:18.0],
    [self.searchImageView.widthAnchor constraintEqualToConstant:13.0],
    [self.searchImageView.heightAnchor constraintEqualToConstant:13.0],
  ]];

  [self.searchBackView addSubview:self.searchInput];
  self.searchInput.translatesAutoresizingMaskIntoConstraints = NO;
  [NSLayoutConstraint activateConstraints:@[
    [self.searchInput.leftAnchor constraintEqualToAnchor:self.searchImageView.rightAnchor constant:5.0],
    [self.searchInput.rightAnchor constraintEqualToAnchor:self.searchBackView.rightAnchor constant:-18.0],
    [self.searchInput.topAnchor constraintEqualToAnchor:self.searchBackView.topAnchor],
    [self.searchInput.bottomAnchor constraintEqualToAnchor:self.searchBackView.bottomAnchor],
  ]];

  UIButton *clearButton = [self.searchInput valueForKey:@"_clearButton"];
  clearButton.accessibilityIdentifier = @"id.clear";
  self.searchInput.accessibilityIdentifier = @"id.addFriendAccount";

  [NSLayoutConstraint activateConstraints:@[
    [self.contentTableView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.contentTableView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [self.contentTableView.topAnchor constraintEqualToAnchor:self.searchBackView.bottomAnchor],
    [self.contentTableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
  ]];
  [self.cellClassDic enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, Class  _Nonnull value, __unused BOOL * _Nonnull stop) {
    [self.contentTableView registerClass:value forCellReuseIdentifier:key.stringValue];
  }];

  [self.view addSubview:self.emptyView];
  [NSLayoutConstraint activateConstraints:@[
    [self.emptyView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
    [self.emptyView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor constant:-100.0],
    [self.emptyView.widthAnchor constraintEqualToConstant:122.0],
    [self.emptyView.heightAnchor constraintEqualToConstant:91.0],
  ]];

  self.navigationView.moreButton.hidden = NO;
  [self.navigationView.moreButton setImage:nil forState:UIControlStateNormal];
  [self.navigationView.moreButton addTarget:self action:@selector(didClickSure) forControlEvents:UIControlEventTouchUpInside];
  [self didChangeSelectMember];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  (void)tableView;
  (void)section;
  return self.viewModel.showDatas.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  NESelectTeamMember *model = self.viewModel.showDatas[indexPath.row];
  NEBaseTeamMemberSelectCell *cell = [tableView cellForRowAtIndexPath:indexPath];
  if (![cell isKindOfClass:[NEBaseTeamMemberSelectCell class]]) {
    return;
  }

  NETeamMemberInfoModel *member = model.member;
  NSString *accid = member.teamMember.accountId ?: @"";
  if (accid.length == 0) {
    return;
  }

  if (self.viewModel.selectDic[accid]) {
    [self.viewModel.selectDic removeObjectForKey:accid];
    model.isSelected = NO;
    cell.checkImageView.highlighted = NO;
  } else {
    if (self.viewModel.selectDic.count >= self.selectCountLimit) {
      if (self.selectCountLimit == 1) {
        for (UITableViewCell *visibleCell in tableView.visibleCells) {
          if ([visibleCell isKindOfClass:[NEBaseTeamMemberSelectCell class]]) {
            NEBaseTeamMemberSelectCell *selectCell = (NEBaseTeamMemberSelectCell *)visibleCell;
            selectCell.checkImageView.highlighted = NO;
            selectCell.currentModel.isSelected = NO;
            [self.viewModel.selectDic removeAllObjects];
          }
        }
      } else {
        [self.view ne_makeToast:[NSString stringWithFormat:NETeamUIKitLocalizable(@"select_limit_tip"), (long)self.selectCountLimit]];
        return;
      }
    }

    self.viewModel.selectDic[accid] = member;
    model.isSelected = YES;
    cell.checkImageView.highlighted = YES;
  }
  [self didChangeSelectMember];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  (void)tableView;
  (void)indexPath;
  return 0;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  NSString *text = textField.text ?: @"";
  return text.length > 0;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
  (void)textField;
  self.viewModel.showDatas = [self.viewModel.datas mutableCopy];
  [self didReloadTableData];
  return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
  NSString *currentText = textField.text ?: @"";
  NSString *finalString = [currentText stringByReplacingCharactersInRange:range withString:string ?: @""];
  if (string.length <= 0) {
    if (finalString.length <= 0) {
      self.viewModel.showDatas = [self.viewModel.datas mutableCopy];
    } else {
      self.viewModel.showDatas = [[self.viewModel searchAllData:finalString] mutableCopy];
    }
  } else {
    self.viewModel.showDatas = [[self.viewModel searchAllData:finalString] mutableCopy];
  }
  [self didReloadTableData];
  return YES;
}

- (void)didChangeSelectMember {
  if (self.viewModel.selectDic.count > 0) {
    NSString *title = [NSString stringWithFormat:@"%@(%lu)", commonLocalizable(@"sure"), (unsigned long)self.viewModel.selectDic.count];
    [self.navigationView.moreButton setTitle:title forState:UIControlStateNormal];
    [self.navigationView setMoreButtonWidth:90.0];
  } else {
    [self.navigationView.moreButton setTitle:commonLocalizable(@"sure") forState:UIControlStateNormal];
  }
}

- (void)didNeedRefresh {
  [self.contentTableView reloadData];
  [self didChangeSelectMember];
}

- (void)didClickSure {
  if (!self.showAllMembers && self.viewModel.selectDic.count + self.viewModel.managerSet.count > self.selectCountLimit) {
    [self.view ne_makeToast:[NSString stringWithFormat:NETeamUIKitLocalizable(@"max_managers_tip"), (long)self.selectCountLimit]];
    return;
  }
  if (self.viewModel.selectDic.count <= 0) {
    [self.view ne_makeToast:NETeamUIKitLocalizable(@"member_empty_tip")];
    return;
  }

  NSMutableArray<NETeamMemberInfoModel *> *result = [NSMutableArray array];
  [result addObjectsFromArray:self.viewModel.selectDic.allValues];
  if (self.selectMemberBlock) {
    self.selectMemberBlock(result);
  }
}

- (TeamMemberSelectViewModel *)viewModel {
  if (!_viewModel) {
    _viewModel = [[TeamMemberSelectViewModel alloc] init];
  }
  return _viewModel;
}

- (UITextField *)searchInput {
  if (!_searchInput) {
    _searchInput = [[UITextField alloc] init];
    _searchInput.textColor = [NEConstant hexRGB:0x333333];
    _searchInput.placeholder = NETeamUIKitLocalizable(@"search_member");
    _searchInput.font = [UIFont systemFontOfSize:14.0];
    _searchInput.returnKeyType = UIReturnKeySearch;
    _searchInput.delegate = self;
    _searchInput.clearButtonMode = UITextFieldViewModeAlways;
  }
  return _searchInput;
}

- (UITableView *)contentTableView {
  if (!_contentTableView) {
    _contentTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _contentTableView.translatesAutoresizingMaskIntoConstraints = NO;
    _contentTableView.backgroundColor = UIColor.clearColor;
    _contentTableView.dataSource = self;
    _contentTableView.delegate = self;
    _contentTableView.separatorColor = UIColor.clearColor;
    _contentTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _contentTableView.sectionHeaderHeight = 12.0;
    _contentTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 12.0)];
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

- (UIView *)searchBackView {
  if (!_searchBackView) {
    _searchBackView = [[UIView alloc] init];
  }
  return _searchBackView;
}

- (UIImageView *)searchImageView {
  if (!_searchImageView) {
    _searchImageView = [[UIImageView alloc] init];
    _searchImageView.image = [coreLoader() loadImage:@"textField_search_icon"];
    _searchImageView.translatesAutoresizingMaskIntoConstraints = NO;
  }
  return _searchImageView;
}

@end
