#import "FunContactViewController.h"
#import <NEChatKitOC/IMKitConfigCenter.h>
#import <NEChatKitOC/UIColor+NECommon.h>
#import <NECommonUIKitOC/NECommonUIKitOC.h>
#import <NECommonUIKitOC/FunSearchView.h>
#import "ContactConst.h"
#import "ContactHeadItem.h"
#import "ContactSectionView.h"
#import "ContactUIConfig.h"
#import "ContactViewModel.h"
#import "FunContactTableViewCell.h"
#import "FunAIUserController.h"
#import "FunAIRobotController.h"
#import "FunContactUIColor.h"
#import "FunFindFriendViewController.h"

@implementation FunContactViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    self.cellRegisterDic = [@{
      @(ContactCellTypeContactPerson) : [FunContactTableViewCell class],
      @(ContactCellTypeContactOthers) : [FunContactTableViewCell class],
    } mutableCopy];
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
    for (UIGestureRecognizer *gesture in self.searchView.gestureRecognizers ?: @[]) {
      [self.searchView removeGestureRecognizer:gesture];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NENotificationNameChangeLanguage object:nil];
  }
}

- (void)changeLanguage {
  NSMutableArray<ContactHeadItem *> *headers = [NSMutableArray array];
  if ([ContactUIConfig shared].showHeader) {
    [headers addObject:[[ContactHeadItem alloc] initWithRouter:ValidationMessageRouter
                                                          name:contactLocalizable(@"validation_message")
                                                     imageName:@"fun_valid_message"
                                                         color:nil]];
    [headers addObject:[[ContactHeadItem alloc] initWithRouter:ContactBlackListRouter
                                                          name:contactLocalizable(@"blacklist")
                                                     imageName:@"fun_blacklist"
                                                         color:nil]];

    if ([IMKitConfigCenter shared].enableTeam) {
      [headers addObject:[[ContactHeadItem alloc] initWithRouter:ContactTeamListRouter
                                                            name:contactLocalizable(@"my_teams")
                                                       imageName:@"fun_my_team"
                                                           color:nil]];
    }

    [headers addObject:[[ContactHeadItem alloc] initWithRouter:ContactAIRobotListRouter
                                                          name:contactLocalizable(@"my_ai_robot")
                                                     imageName:@"fun_ai_robot"
                                                         color:nil]];

    if ([IMKitConfigCenter shared].enableAIUser) {
      [headers addObject:[[ContactHeadItem alloc] initWithRouter:ContactAIUserListRouter
                                                            name:contactLocalizable(@"my_ai_user")
                                                       imageName:@"fun_ai_user"
                                                           color:nil]];
    }

    if ([ContactUIConfig shared].headerData) {
      [ContactUIConfig shared].headerData(self, headers);
    }
  }

  self.viewModel = [[ContactViewModel alloc] initWithContactHeaders:headers];
  if (self.isViewLoaded) {
    __weak typeof(self) weakSelf = self;
    self.viewModel.delegate = self;
    self.viewModel.refresh = ^{
      [weakSelf didRefreshTable];
    };
    [self loadData];
  }
  [self.searchView.searchButton setTitle:commonLocalizable(@"search") forState:UIControlStateNormal];
  [self initSystemNav];
}

- (void)commonUI {
  self.bodyTopViewHeight = 60;
  [super commonUI];

  self.view.backgroundColor = [UIColor funContactBackgroundColor];
  self.bodyTopView.backgroundColor = [UIColor funContactBodyTopViewBackgroundColor];
  self.bodyView.backgroundColor = [UIColor funContactBodyViewBackgroundColor];
  self.tableView.backgroundColor = [UIColor funContactTableViewBackgroundColor];
  self.tableView.sectionIndexColor = [UIColor funContactTableViewSectionIndexColor];
  self.bodyBottomView.backgroundColor = [UIColor funContactBodyBottomViewBackgroundColor];

  UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(searchAction)];
  tap.cancelsTouchesInView = NO;
  [self.searchView addGestureRecognizer:tap];
  [self.bodyTopView addSubview:self.searchView];

  [NSLayoutConstraint activateConstraints:@[
    [self.searchView.topAnchor constraintEqualToAnchor:self.bodyTopView.topAnchor constant:12],
    [self.searchView.leftAnchor constraintEqualToAnchor:self.bodyTopView.leftAnchor constant:8],
    [self.searchView.rightAnchor constraintEqualToAnchor:self.bodyTopView.rightAnchor constant:-8],
    [self.searchView.heightAnchor constraintEqualToConstant:36],
  ]];

  [self.tableView registerClass:[ContactSectionView class]
     forHeaderFooterViewReuseIdentifier:NSStringFromClass([ContactSectionView class])];
  for (NSNumber *key in self.cellRegisterDic) {
    [self.tableView registerClass:self.cellRegisterDic[key]
           forCellReuseIdentifier:[NSString stringWithFormat:@"%@", key]];
  }

  [self.emptyView setEmptyImageName:@"fun_user_empty"];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  UIView *view = [super tableView:tableView viewForHeaderInSection:section];
  if ([view isKindOfClass:[ContactSectionView class]]) {
    ContactSectionView *sectionView = (ContactSectionView *)view;
    sectionView.line.hidden = YES;
    sectionView.backView.backgroundColor = [UIColor funContactSectionViewBackgroundColor];
    sectionView.titleLabel.textColor = [UIColor funContactSectionViewTitleLabelTextColor];
    return sectionView;
  }
  return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return 64;
}

- (NEBaseFindFriendViewController *)getFindFriendViewController {
  return [[FunFindFriendViewController alloc] init];
}

- (void)initSystemNav {
  [super initSystemNav];

  if ([ContactUIConfig shared].showTitleBarRightIcon) {
    UIImage *addImage = [ContactUIConfig shared].titleBarRightRes ?: ne_contactImageNamed(@"fun_nav_add");
    UIBarButtonItem *addItem = [[UIBarButtonItem alloc] initWithImage:addImage
                                                                style:UIBarButtonItemStylePlain
                                                               target:self
                                                               action:@selector(goToFindFriend)];
    addItem.tintColor = [UIColor ne_colorWithHexString:@"333333"];
    self.navigationItem.rightBarButtonItems = @[addItem];
    [self.navigationView.addBtn setImage:addImage forState:UIControlStateNormal];
    self.navigationView.addBtn.hidden = NO;
  } else {
    self.navigationItem.rightBarButtonItems = @[];
    self.navigationView.addBtn.hidden = YES;
  }

  self.title = contactLocalizable(@"contact");
  self.navigationView.navigationTitle.text = contactLocalizable(@"contact");
  self.navigationView.backgroundColor = [UIColor funContactNavigationBackgroundColor];
  self.navigationView.titleBarBottomLine.hidden = YES;
  self.navigationView.brandBtn.hidden = YES;
  self.navigationView.navigationTitle.hidden = NO;
  self.navigationView.searchBtn.hidden = YES;
}

- (FunSearchView *)searchView {
  if (!_searchView) {
    _searchView = [[FunSearchView alloc] initWithFrame:CGRectZero];
    _searchView.translatesAutoresizingMaskIntoConstraints = NO;
  }
  return _searchView;
}

@end
