// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseAIUserController.h"
#import "AIUserController.h"
#import "FunAIUserController.h"
#import "AIUserViewModel.h"
#import "ContactConst.h"
#import "FunContactUIColor.h"
#import "NEBaseAIUserListCell.h"
#import <NEChatKit/NEAIUserModel.h>
#import <NEChatKit/NECommonLoader.h>
#import <NEChatKit/UIColor+NECommon.h>
#import <NECommonUIKitOC/NECommonUIKitOC.h>
#import <NIMSDK/V2NIMAIServiceProtocol.h>

static NSString * const NEAIUserContactUserInfoPageRouterCompat = @"imkit://contact/userInfo.page";

@interface AIUserListCell : NEBaseAIUserListCell
@end

@interface FunAIUserListCell : NEBaseAIUserListCell

@property(nonatomic, strong) UIView *dividerLine;

@end

@interface FunAIUserController ()

@property(nonatomic, strong) UIView *searchGrayBackView;
@property(nonatomic, strong, nullable) NSLayoutConstraint *searchGrayBackViewTopAnchor;

@end

@implementation NEBaseAIUserController

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  self.backViewTopAnchor.constant = 8.0 + self.topConstant;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(changeLanguage)
                                               name:NENotificationNameChangeLanguage
                                             object:nil];
  [self setupAIUserListUI];
  [self addTextFiledObserver];
  self.navigationView.moreButton.hidden = YES;

  __weak typeof(self) weakSelf = self;
  [self.viewModel getAIUsers:^(NSError * _Nullable error) {
    [weakSelf refreshTableView];
  }];
}

- (Class)aiUserCellClass {
  return [NEBaseAIUserListCell class];
}

- (CGFloat)aiUserCellHeight {
  return 64.0;
}

- (void)setupAIUserListUI {
  [self changeLanguage];

  [self.view addSubview:self.backView];
  self.backViewTopAnchor = [self.backView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:8.0 + self.topConstant];
  self.backViewTopAnchor.active = YES;
  [NSLayoutConstraint activateConstraints:@[
    [self.backView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:20.0],
    [self.backView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant:-20.0],
    [self.backView.heightAnchor constraintEqualToConstant:0.0],
  ]];

  [self.backView addSubview:self.searchIconImageView];
  [NSLayoutConstraint activateConstraints:@[
    [self.searchIconImageView.centerYAnchor constraintEqualToAnchor:self.backView.centerYAnchor],
    [self.searchIconImageView.leftAnchor constraintEqualToAnchor:self.backView.leftAnchor constant:16.0],
    [self.searchIconImageView.widthAnchor constraintEqualToConstant:13.0],
    [self.searchIconImageView.heightAnchor constraintEqualToConstant:13.0],
  ]];

  [self.backView addSubview:self.searchAIUserTextField];
  [NSLayoutConstraint activateConstraints:@[
    [self.searchAIUserTextField.leftAnchor constraintEqualToAnchor:self.backView.leftAnchor constant:36.0],
    [self.searchAIUserTextField.rightAnchor constraintEqualToAnchor:self.backView.rightAnchor constant:-16.0],
    [self.searchAIUserTextField.topAnchor constraintEqualToAnchor:self.backView.topAnchor],
    [self.searchAIUserTextField.bottomAnchor constraintEqualToAnchor:self.backView.bottomAnchor],
  ]];

  UIButton *clearButton = [self.searchAIUserTextField valueForKey:@"_clearButton"];
  if (clearButton) {
    clearButton.accessibilityIdentifier = @"id.clear";
  }

  [self.view addSubview:self.aiUserTableView];
  [NSLayoutConstraint activateConstraints:@[
    [self.aiUserTableView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.aiUserTableView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [self.aiUserTableView.topAnchor constraintEqualToAnchor:self.backView.bottomAnchor],
    [self.aiUserTableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
  ]];

  [self.aiUserTableView registerClass:[self aiUserCellClass]
               forCellReuseIdentifier:NSStringFromClass([self aiUserCellClass])];

  [self.view addSubview:self.aiUserEmptyView];
  [NSLayoutConstraint activateConstraints:@[
    [self.aiUserEmptyView.leftAnchor constraintEqualToAnchor:self.aiUserTableView.leftAnchor],
    [self.aiUserEmptyView.rightAnchor constraintEqualToAnchor:self.aiUserTableView.rightAnchor],
    [self.aiUserEmptyView.topAnchor constraintEqualToAnchor:self.aiUserTableView.topAnchor constant:50.0],
    [self.aiUserEmptyView.bottomAnchor constraintEqualToAnchor:self.aiUserTableView.bottomAnchor],
  ]];
}

- (void)changeLanguage {
  self.title = contactLocalizable(@"my_ai_user");
  self.searchAIUserTextField.placeholder = commonLocalizable(@"search");
  self.aiUserEmptyView.message = contactLocalizable(@"no_ai_user");
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  if (self.searchAIUserTextField.text.length > 0) {
    return self.viewModel.searchDatas.count;
  }
  return self.viewModel.datas.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  NEBaseAIUserListCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([self aiUserCellClass])
                                                               forIndexPath:indexPath];
  NEAIUserModel *model = [self getRealAIUserModel:indexPath.row];
  if (model) {
    [cell configure:model];
  }
  return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return [self aiUserCellHeight];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  NEAIUserModel *model = [self getRealAIUserModel:indexPath.row];
  if (!model.aiUser) {
    return;
  }
  [[Router shared] use:NEAIUserContactUserInfoPageRouterCompat
            parameters:@{
              @"nav": self.navigationController ?: [NSNull null],
              @"nim_user": model.aiUser,
            }
               closure:nil];
}

- (BOOL)isLastAIUser:(NSInteger)index {
  if (self.searchAIUserTextField.text.length > 0) {
    return self.viewModel.searchDatas.count - 1 == index;
  }
  return self.viewModel.datas.count - 1 == index;
}

- (nullable NEAIUserModel *)getRealAIUserModel:(NSInteger)index {
  if (self.searchAIUserTextField.text.length > 0) {
    if (index >= 0 && index < self.viewModel.searchDatas.count) {
      return self.viewModel.searchDatas[index];
    }
    return nil;
  }
  if (index >= 0 && index < self.viewModel.datas.count) {
    return self.viewModel.datas[index];
  }
  return nil;
}

- (void)addTextFiledObserver {
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(textChange)
                                               name:UITextFieldTextDidChangeNotification
                                             object:nil];
}

- (void)textChange {
  [self.viewModel.searchDatas removeAllObjects];
  NSString *text = self.searchAIUserTextField.text ?: @"";
  if (text.length > 0) {
    for (NEAIUserModel *model in self.viewModel.datas) {
      NSString *uid = model.aiUser.accountId ?: @"";
      NSString *nick = model.aiUser.name ?: @"";
      if ([uid containsString:text] || [nick containsString:text]) {
        [self.viewModel.searchDatas addObject:model];
      }
    }
  } else {
    self.aiUserEmptyView.hidden = YES;
  }
  [self refreshTableView];
}

- (void)refreshTableView {
  [self.aiUserTableView reloadData];
  self.aiUserEmptyView.hidden = self.viewModel.datas.count > 0;
}

#pragma mark - Lazy Init

- (AIUserViewModel *)viewModel {
  if (!_viewModel) {
    _viewModel = [[AIUserViewModel alloc] init];
  }
  return _viewModel;
}

- (UITextField *)searchAIUserTextField {
  if (!_searchAIUserTextField) {
    _searchAIUserTextField = [[UITextField alloc] init];
    _searchAIUserTextField.translatesAutoresizingMaskIntoConstraints = NO;
    _searchAIUserTextField.placeholder = commonLocalizable(@"search");
    _searchAIUserTextField.clearButtonMode = UITextFieldViewModeAlways;
    _searchAIUserTextField.textColor = [UIColor ne_greyText];
    _searchAIUserTextField.font = [UIFont systemFontOfSize:14.0];
    _searchAIUserTextField.backgroundColor = [UIColor ne_backcolor];
    _searchAIUserTextField.accessibilityIdentifier = @"id.search";
  }
  return _searchAIUserTextField;
}

- (UITableView *)aiUserTableView {
  if (!_aiUserTableView) {
    _aiUserTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _aiUserTableView.translatesAutoresizingMaskIntoConstraints = NO;
    _aiUserTableView.backgroundColor = [UIColor clearColor];
    _aiUserTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _aiUserTableView.sectionHeaderHeight = 12.0;
    _aiUserTableView.dataSource = self;
    _aiUserTableView.delegate = self;
    _aiUserTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 12.0)];
    _aiUserTableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    _aiUserTableView.estimatedRowHeight = 0;
    _aiUserTableView.estimatedSectionHeaderHeight = 0;
    _aiUserTableView.estimatedSectionFooterHeight = 0;
    if (@available(iOS 15.0, *)) {
      _aiUserTableView.sectionHeaderTopPadding = 0.0;
    }
  }
  return _aiUserTableView;
}

- (NEEmptyDataView *)aiUserEmptyView {
  if (!_aiUserEmptyView) {
    _aiUserEmptyView = [[NEEmptyDataView alloc] initWithImageName:@"user_empty"
                                                          content:contactLocalizable(@"no_ai_user")
                                                            frame:CGRectZero];
    _aiUserEmptyView.translatesAutoresizingMaskIntoConstraints = NO;
    _aiUserEmptyView.hidden = YES;
  }
  return _aiUserEmptyView;
}

- (UIView *)backView {
  if (!_backView) {
    _backView = [[UIView alloc] init];
    _backView.translatesAutoresizingMaskIntoConstraints = NO;
    _backView.backgroundColor = [UIColor clearColor];
    _backView.clipsToBounds = YES;
    _backView.layer.cornerRadius = 4.0;
  }
  return _backView;
}

- (UIImageView *)searchIconImageView {
  if (!_searchIconImageView) {
    _searchIconImageView = [[UIImageView alloc] initWithImage:[coreLoader() loadImage:@"textField_search_icon"]];
    _searchIconImageView.translatesAutoresizingMaskIntoConstraints = NO;
  }
  return _searchIconImageView;
}

@end

@implementation AIUserListCell
@end

@implementation FunAIUserListCell

- (void)setupAIUserListCellUI {
  [self.contentView addSubview:self.aiUserHeaderView];
  [NSLayoutConstraint activateConstraints:@[
    [self.aiUserHeaderView.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:21.0],
    [self.aiUserHeaderView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [self.aiUserHeaderView.widthAnchor constraintEqualToConstant:40.0],
    [self.aiUserHeaderView.heightAnchor constraintEqualToConstant:40.0],
  ]];
  self.aiUserHeaderView.layer.cornerRadius = 4.0;

  [self.contentView addSubview:self.aiUserNameLabel];
  [NSLayoutConstraint activateConstraints:@[
    [self.aiUserNameLabel.leftAnchor constraintEqualToAnchor:self.aiUserHeaderView.rightAnchor constant:14.0],
    [self.aiUserNameLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
    [self.aiUserNameLabel.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:-21.0],
  ]];

  [self.contentView addSubview:self.dividerLine];
  [NSLayoutConstraint activateConstraints:@[
    [self.dividerLine.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:20.0],
    [self.dividerLine.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor],
    [self.dividerLine.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
    [self.dividerLine.heightAnchor constraintEqualToConstant:1.0],
  ]];
}

- (UIView *)dividerLine {
  if (!_dividerLine) {
    _dividerLine = [[UIView alloc] init];
    _dividerLine.translatesAutoresizingMaskIntoConstraints = NO;
    _dividerLine.backgroundColor = [UIColor funContactDividerLineColor];
  }
  return _dividerLine;
}

@end

@implementation AIUserController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.navigationView.backgroundColor = [UIColor whiteColor];
  self.navigationController.navigationBar.backgroundColor = [UIColor whiteColor];
  self.backView.backgroundColor = [UIColor ne_backcolor];
}

- (Class)aiUserCellClass {
  return [AIUserListCell class];
}

- (CGFloat)aiUserCellHeight {
  return 64.0;
}

@end

@implementation FunAIUserController

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  self.searchGrayBackViewTopAnchor.constant = self.topConstant;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = [UIColor funContactBackgroundColor];

  [self.view insertSubview:self.searchGrayBackView belowSubview:self.backView];
  self.searchGrayBackViewTopAnchor = [self.searchGrayBackView.topAnchor constraintEqualToAnchor:self.view.topAnchor
                                                                                       constant:self.topConstant];
  self.searchGrayBackViewTopAnchor.active = YES;
  [NSLayoutConstraint activateConstraints:@[
    [self.searchGrayBackView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.searchGrayBackView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [self.searchGrayBackView.bottomAnchor constraintEqualToAnchor:self.aiUserTableView.topAnchor],
  ]];

  self.backView.backgroundColor = [UIColor whiteColor];
  self.searchAIUserTextField.backgroundColor = [UIColor whiteColor];
  [self.aiUserEmptyView setEmptyImageName:@"fun_user_empty"];
}

- (Class)aiUserCellClass {
  return [FunAIUserListCell class];
}

- (CGFloat)aiUserCellHeight {
  return 64.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  FunAIUserListCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([FunAIUserListCell class])
                                                            forIndexPath:indexPath];
  NEAIUserModel *model = [self getRealAIUserModel:indexPath.row];
  if (model) {
    [cell configure:model];
  }
  cell.dividerLine.hidden = [self isLastAIUser:indexPath.row];
  return cell;
}

- (UIView *)searchGrayBackView {
  if (!_searchGrayBackView) {
    _searchGrayBackView = [[UIView alloc] init];
    _searchGrayBackView.translatesAutoresizingMaskIntoConstraints = NO;
    _searchGrayBackView.backgroundColor = [UIColor funContactBackgroundColor];
  }
  return _searchGrayBackView;
}

@end
