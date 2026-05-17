// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseFusionContactSelectedController.h"
#import <NEChatKitOC/ChatConstant.h>
#import <NEChatKitOC/ContactRepo.h>
#import <NEChatKitOC/NEFriendUserCache.h>
#import <NEChatKitOC/IMKitConfigCenter.h>
#import <NEChatKitOC/NECoreIM2KitOC.h>
#import <NECommonUIKitOC/NECommonUIKitOC.h>
#import "ContactConst.h"

@interface NEBaseFusionContactSelectedController ()
@property (nonatomic, strong) FusionContactSelectedViewModel *viewModel;
@property (nonatomic, assign) FusionContactType fusionType;
@property (nonatomic, strong, nullable) NSSet<NSString *> *filterSet;
@end

@implementation NEBaseFusionContactSelectedController

- (instancetype)initWithFilterIds:(NSSet<NSString *> *)filterIds type:(FusionContactType)type {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _viewModel = [[FusionContactSelectedViewModel alloc] init];
    _fusionRegisterCellDic = [NSMutableDictionary dictionaryWithDictionary:@{@0: [NEBaseFusionContactSelectedCell class]}];
    _limit = 10;
    _fusionType = type;
    _filterSet = filterIds;
    if (_fusionType == FusionContactTypeUser) {
      self.title = contactLocalizable(@"contact_friend");
    } else if (_fusionType == FusionContactTypeAIUser) {
      self.title = contactLocalizable(@"contact_ai_user");
    }
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  return [super initWithCoder:coder];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(changeLanguage)
                                               name:NENotificationNameChangeLanguage
                                             object:nil];
  [self changeLanguage];
  [self setupFusionContactSelectedUI];
  [self loadData];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(loadData)
                                               name:NENotificationFriendCacheInit
                                             object:nil];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setupFusionContactSelectedUI {
  self.view.backgroundColor = [UIColor whiteColor];
  [self.view addSubview:self.fusionContactTableView];
  [NSLayoutConstraint activateConstraints:@[
    [self.fusionContactTableView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
    [self.fusionContactTableView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.fusionContactTableView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [self.fusionContactTableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
  ]];

  for (NSNumber *key in self.fusionRegisterCellDic) {
    Class value = self.fusionRegisterCellDic[key];
    [self.fusionContactTableView registerClass:value forCellReuseIdentifier:[NSString stringWithFormat:@"%@", key]];
  }

  [self.view addSubview:self.fusionEmptyView];
  [NSLayoutConstraint activateConstraints:@[
    [self.fusionEmptyView.topAnchor constraintEqualToAnchor:self.fusionContactTableView.topAnchor],
    [self.fusionEmptyView.bottomAnchor constraintEqualToAnchor:self.fusionContactTableView.bottomAnchor],
    [self.fusionEmptyView.leftAnchor constraintEqualToAnchor:self.fusionContactTableView.leftAnchor],
    [self.fusionEmptyView.rightAnchor constraintEqualToAnchor:self.fusionContactTableView.rightAnchor],
  ]];
}

- (void)setupFusionContactUI {}

- (void)loadData {
  __weak typeof(self) weakSelf = self;
  if (self.fusionType == FusionContactTypeUser) {
    [self.viewModel loadMemberDatas:self.filterSet completion:^(NSError * _Nullable error) {
      if (error) {
        [weakSelf.view ne_makeToast:error.localizedDescription];
      } else {
        [weakSelf.fusionContactTableView reloadData];
      }
      weakSelf.fusionEmptyView.hidden = (weakSelf.viewModel.memberDatas.count > 0);
    }];
  } else if (self.fusionType == FusionContactTypeAIUser) {
    [self changeLanguage];
    [self.viewModel loadAIUserData:self.filterSet];
    [self.fusionContactTableView reloadData];
    self.fusionEmptyView.hidden = (self.viewModel.memberDatas.count > 0);
  }
}

- (void)changeLanguage {
  if (self.fusionType == FusionContactTypeUser) {
    self.title = contactLocalizable(@"contact_friend");
    self.fusionEmptyView.message = contactLocalizable(@"no_friend");
  } else if (self.fusionType == FusionContactTypeAIUser) {
    self.title = contactLocalizable(@"contact_ai_user");
    self.fusionEmptyView.message = contactLocalizable(@"no_ai_user");
  }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.viewModel.memberDatas.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  NEFusionContactCellModel *cellModel = self.viewModel.memberDatas[indexPath.row];
  NSString *identifier = [NSString stringWithFormat:@"%ld", (long)cellModel.type];
  NEBaseFusionContactSelectedCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
  if (cell) {
    [cell configFusionModel:cellModel];
    return cell;
  }
  return [[UITableViewCell alloc] init];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return 56;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  NEFusionContactCellModel *cellModel = self.viewModel.memberDatas[indexPath.row];
  if (cellModel.selected == NO) {
    if ([self.delegate didSelectedUser:cellModel] == YES) {
      cellModel.selected = !cellModel.selected;
      NEBaseFusionContactSelectedCell *cell = [tableView cellForRowAtIndexPath:indexPath];
      if (cell) {
        [cell configFusionModel:cellModel];
      }
    } else {
      [self.view ne_makeToast:[NSString stringWithFormat:contactLocalizable(@"exceeded_limit"), (long)self.limit]];
    }
  } else {
    [self.delegate didUnselectedUser:cellModel];
    cellModel.selected = !cellModel.selected;
    NEBaseFusionContactSelectedCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell) {
      [cell configFusionModel:cellModel];
    }
  }
}

- (V2NIMUser *)getCellModelUser:(NEFusionContactCellModel *)cellModel {
  if (self.fusionType == FusionContactTypeUser) {
    return cellModel.user.user;
  } else if (self.fusionType == FusionContactTypeAIUser) {
    return cellModel.aiUser;
  }
  return nil;
}

- (void)unselectModel:(NEFusionContactCellModel *)model {
  for (NEFusionContactCellModel *memberModel in self.viewModel.memberDatas) {
    if ([[memberModel getAccountId] isEqualToString:[model getAccountId]]) {
      memberModel.selected = NO;
      [self.fusionContactTableView reloadData];
    }
  }
}

#pragma mark - Lazy Init

- (UITableView *)fusionContactTableView {
  if (!_fusionContactTableView) {
    _fusionContactTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _fusionContactTableView.backgroundColor = [UIColor clearColor];
    _fusionContactTableView.delegate = self;
    _fusionContactTableView.dataSource = self;
    _fusionContactTableView.translatesAutoresizingMaskIntoConstraints = NO;
    _fusionContactTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _fusionContactTableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;

    _fusionContactTableView.estimatedRowHeight = 0;
    _fusionContactTableView.estimatedSectionHeaderHeight = 0;
    _fusionContactTableView.estimatedSectionFooterHeight = 0;

    if (@available(iOS 15.0, *)) {
      _fusionContactTableView.sectionHeaderTopPadding = 0.0;
    }
  }
  return _fusionContactTableView;
}

- (NEEmptyDataView *)fusionEmptyView {
  if (!_fusionEmptyView) {
    _fusionEmptyView = [[NEEmptyDataView alloc] initWithImageName:@"user_empty"
                                                          content:contactLocalizable(@"no_friend")
                                                            frame:CGRectZero];
    _fusionEmptyView.translatesAutoresizingMaskIntoConstraints = NO;
    _fusionEmptyView.userInteractionEnabled = NO;
    _fusionEmptyView.hidden = NO;
  }
  return _fusionEmptyView;
}

@end
