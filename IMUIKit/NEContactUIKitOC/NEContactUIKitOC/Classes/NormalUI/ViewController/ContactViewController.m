// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "ContactViewController.h"
#import <NEChatKit/NECommonLoader.h>
#import <NEChatKit/UIColor+NECommon.h>
#import "ContactTableViewCell.h"
#import "ContactSectionView.h"
#import "ContactViewModel.h"
#import "ContactHeadItem.h"
#import "ContactUIConfig.h"
#import "ContactConst.h"
#import <NEChatKit/IMKitConfigCenter.h>
#import <NEChatKit/NEConstant.h>
#import "FindFriendViewController.h"
#import "AIUserController.h"
#import "AIRobotController.h"
#import "NormalContactUIColor.h"
#import <NECommonUIKitOC/NECommonUIKitOC.h>

static NSString * const NENormalValidationMessageRouterCompat = @"imkit://contact/verifyList.page";
static NSString * const NENormalContactBlackListRouterCompat = @"imkit://contact/blackList.page";
static NSString * const NENormalContactTeamListRouterCompat = @"imkit://contact/teamList.page";
static NSString * const NENormalContactAIRobotListRouterCompat = @"imkit://contact/aiRobotList.page";
static NSString * const NENormalContactAIUserListRouterCompat = @"imkit://contact/aiList.page";

@implementation ContactViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    self.cellRegisterDic = @{
      @(ContactCellTypeContactPerson): [ContactTableViewCell class],
      @(ContactCellTypeContactOthers): [ContactTableViewCell class],
    };
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(changeLanguage)
                                                 name:NENotificationNameChangeLanguage
                                               object:nil];
    [self changeLanguage];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  return [super initWithCoder:coder];
}

- (void)willMoveToParentViewController:(UIViewController *)parent {
  [super willMoveToParentViewController:parent];
  if (parent == nil) {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
  }
}

- (void)changeLanguage {
  NSMutableArray<ContactHeadItem *> *contactHeaders = [NSMutableArray array];
  if ([ContactUIConfig shared].showHeader) {
    [contactHeaders addObject:[[ContactHeadItem alloc] initWithRouter:NENormalValidationMessageRouterCompat name:contactLocalizable(@"validation_message") imageName:@"valid_message" color:nil]];
    [contactHeaders addObject:[[ContactHeadItem alloc] initWithRouter:NENormalContactBlackListRouterCompat name:contactLocalizable(@"blacklist") imageName:@"blacklist" color:nil]];

    if ([IMKitConfigCenter shared].enableTeam) {
      [contactHeaders addObject:[[ContactHeadItem alloc] initWithRouter:NENormalContactTeamListRouterCompat name:contactLocalizable(@"my_teams") imageName:@"group" color:nil]];
    }

    [contactHeaders addObject:[[ContactHeadItem alloc] initWithRouter:NENormalContactAIRobotListRouterCompat name:contactLocalizable(@"my_ai_robot") imageName:@"ai_robot" color:nil]];

    if ([IMKitConfigCenter shared].enableAIUser) {
      [contactHeaders addObject:[[ContactHeadItem alloc] initWithRouter:NENormalContactAIUserListRouterCompat name:contactLocalizable(@"my_ai_user") imageName:@"ai_user" color:nil]];
    }

    if ([ContactUIConfig shared].headerData) {
      [ContactUIConfig shared].headerData(self, contactHeaders);
    }
  }
  self.viewModel = [[ContactViewModel alloc] initWithContactHeaders:contactHeaders];
  if (self.isViewLoaded) {
    __weak typeof(self) weakSelf = self;
    self.viewModel.delegate = self;
    self.viewModel.refresh = ^{
      [weakSelf didRefreshTable];
    };
    [self loadData];
  }
  [self initSystemNav];
}

- (void)commonUI {
  [super commonUI];
  self.view.backgroundColor = [UIColor normalContactBackgroundColor];
  self.bodyTopView.backgroundColor = [UIColor normalContactBodyTopViewBackgroundColor];
  self.bodyView.backgroundColor = [UIColor normalContactBodyViewBackgroundColor];
  self.tableView.backgroundColor = [UIColor normalContactTableViewBackgroundColor];
  self.tableView.sectionIndexColor = [UIColor normalContactTableViewSectionIndexColor];
  self.bodyBottomView.backgroundColor = [UIColor normalContactBodyBottomViewBackgroundColor];

  [self.tableView registerClass:[ContactSectionView class]
     forHeaderFooterViewReuseIdentifier:NSStringFromClass([ContactSectionView class])];

  for (NSNumber *key in self.cellRegisterDic) {
    [self.tableView registerClass:self.cellRegisterDic[key]
           forCellReuseIdentifier:[NSString stringWithFormat:@"%@", key]];
  }
}

- (NEBaseFindFriendViewController *)getFindFriendViewController {
  return [[FindFriendViewController alloc] init];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  UIView *view = [super tableView:tableView viewForHeaderInSection:section];
  if ([view isKindOfClass:[ContactSectionView class]]) {
    ContactSectionView *sectionView = (ContactSectionView *)view;
    sectionView.backView.backgroundColor = [UIColor normalContactSectionViewBackgroundColor];
    sectionView.line.backgroundColor = [UIColor normalContactSectionViewLineColor];
    sectionView.titleLabel.textColor = [UIColor normalContactSectionViewTitleLabelTextColor];
    return sectionView;
  }
  return nil;
}

#pragma mark - Nav

- (void)initSystemNav {
  [super initSystemNav];
  UIBarButtonItem *addItem = [[UIBarButtonItem alloc] initWithImage:[ContactUIConfig shared].titleBarRightRes ?: [coreLoader() loadImage:@"nav_add"]
                                                              style:UIBarButtonItemStylePlain
                                                             target:self
                                                             action:@selector(goToFindFriend)];
  addItem.tintColor = [UIColor ne_colorWithHexString:@"333333"];
  UIBarButtonItem *searchItem = [[UIBarButtonItem alloc] initWithImage:[ContactUIConfig shared].titleBarRight2Res ?: [coreLoader() loadImage:@"nav_search"]
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(searchContact)];
  searchItem.imageInsets = UIEdgeInsetsMake(0, 35, 0, 0);
  searchItem.tintColor = [UIColor ne_colorWithHexString:@"333333"];

  self.navigationItem.rightBarButtonItems = @[addItem, searchItem];
  if (![ContactUIConfig shared].showTitleBarRight2Icon) {
    self.navigationItem.rightBarButtonItems = @[addItem];
    self.navigationView.searchBtn.hidden = YES;
  }
  if (![ContactUIConfig shared].showTitleBarRightIcon) {
    self.navigationItem.rightBarButtonItems = @[searchItem];
    self.navigationView.addBtn.hidden = YES;
  }

  UIButton *brandBarBtn = [[UIButton alloc] init];
  [brandBarBtn setTitle:[ContactUIConfig shared].title ?: contactLocalizable(@"contact") forState:UIControlStateNormal];
  [brandBarBtn setTitleColor:[ContactUIConfig shared].titleColor ?: [UIColor blackColor] forState:UIControlStateNormal];
  brandBarBtn.titleLabel.font = [NEConstant textFont:@"PingFangSC-Medium" size:20];
  UIBarButtonItem *brandBtn = [[UIBarButtonItem alloc] initWithCustomView:brandBarBtn];
  self.navigationItem.leftBarButtonItem = brandBtn;

  [self.navigationView.brandBtn setImage:nil forState:UIControlStateNormal];
  [self.navigationView.brandBtn setTitle:[ContactUIConfig shared].title ?: contactLocalizable(@"contact") forState:UIControlStateNormal];
  [self.navigationView.brandBtn setTitleColor:[ContactUIConfig shared].titleColor ?: [UIColor blackColor] forState:UIControlStateNormal];
  self.navigationView.brandBtn.titleEdgeInsets = UIEdgeInsetsZero;
  self.navigationView.backgroundColor = [UIColor normalContactNavigationBackgroundColor];
  self.navigationView.titleBarBottomLine.backgroundColor = [UIColor normalContactNavigationDivideBg];
}

@end
