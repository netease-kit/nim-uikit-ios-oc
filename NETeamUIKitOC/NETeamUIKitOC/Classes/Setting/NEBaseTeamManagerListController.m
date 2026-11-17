// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseTeamManagerListController.h"
#import "TeamConstant.h"
#import <NEChatKit/NEChatKit.h>
#import <NEChatKit/NEChatDetectNetworkTool.h>
#import <NEChatKit/NEConstant.h>
#import <NEBaseUIKitOC/UIView+YXToast.h>
#import <NEChatKit/NERouterUrl.h>
#import <NEChatKit/Router.h>

static NSString * const NETeamManagerListMeSettingRouter = @"imkit://mine/userInfo.page";
static NSString * const NETeamManagerListContactUserInfoPageRouter = @"imkit://contact/userInfo.page";

@interface NEBaseTeamManagerListController ()
@property (nonatomic, strong, readwrite) TeamManagerListViewModel *viewmodel;
@end

@implementation NEBaseTeamManagerListController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    _cellClassDic = [NSMutableDictionary dictionary];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    _cellClassDic = [NSMutableDictionary dictionary];
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  self.title = NETeamUIKitLocalizable(@"group_manager");
  self.viewmodel.teamId = self.teamId;
  self.viewmodel.delegate = self;

  [self.view addSubview:self.contentTableView];
  [NSLayoutConstraint activateConstraints:@[
    [self.contentTableView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.contentTableView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [self.contentTableView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:self.topConstant],
    [self.contentTableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
  ]];

  [self.cellClassDic enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, Class  _Nonnull value, __unused BOOL * _Nonnull stop) {
    [self.contentTableView registerClass:value forCellReuseIdentifier:key.stringValue];
  }];
  self.navigationView.moreButton.hidden = YES;
  [self.emptyView setEmptyImageName:@"user_empty"];
  self.emptyView.message = NETeamUIKitLocalizable(@"no_manager_member");

  if (self.teamId.length > 0) {
    [self.viewmodel getCurrentMember:self.teamId];
    __weak typeof(self) weakSelf = self;
    [self.viewmodel getManagerDatas:self.teamId completion:^(NSError * _Nullable error) {
      if (error) {
        [weakSelf.view ne_makeToast:NETeamUIKitErrorToast(error)];
      } else {
        [weakSelf sortAndReloadData];
      }
    }];
  }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  (void)tableView;
  return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  (void)tableView;
  if (section == 0) {
    return 1;
  }
  return self.viewmodel.managers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  (void)tableView;
  (void)indexPath;
  return 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  (void)tableView;
  if (indexPath.section != 1 || self.viewmodel.managers.count <= indexPath.row) {
    return;
  }
  NETeamMemberInfoModel *model = self.viewmodel.managers[indexPath.row];
  NEUserWithFriend *user = model.nimUser;
  if ([[IMKitClient instance] isMe:user.user.accountId]) {
    [[Router shared] use:NETeamManagerListMeSettingRouter
              parameters:@{@"nav": self.navigationController ?: [NSNull null]}
                 closure:nil];
  } else if (user.user.accountId.length > 0) {
    [[Router shared] use:NETeamManagerListContactUserInfoPageRouter
              parameters:@{
                @"nav": self.navigationController ?: [NSNull null],
                @"uid": user.user.accountId ?: @"",
              }
                 closure:nil];
  }
}

- (void)didAddManagers:(NSArray<NETeamMemberInfoModel *> *)managers {
  if ([[NEChatDetectNetworkTool shareInstance] isNetworkExplicitlyUnreachable]) {
    [self.view ne_makeToast:commonLocalizable(@"network_error")];
    return;
  }

  NSString *tid = self.teamId ?: @"";
  if (tid.length == 0) {
    return;
  }

  NSMutableArray<NSString *> *uids = [NSMutableArray array];
  for (NETeamMemberInfoModel *member in managers) {
    NSString *uid = member.nimUser.user.accountId ?: @"";
    if (uid.length > 0) {
      [uids addObject:uid];
    }
  }

  __weak typeof(self) weakSelf = self;
  [self.viewmodel addTeamManager:tid uids:uids completion:^(NSError * _Nullable error) {
    if (error) {
      [weakSelf.view ne_makeToast:NETeamUIKitErrorToast(error)];
    } else {
      NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, managers.count)];
      [weakSelf.viewmodel.managers insertObjects:managers atIndexes:indexes];
      [weakSelf sortAndReloadData];
    }
  }];
}

- (void)didClickRemoveButton:(NETeamMemberInfoModel *)model index:(NSInteger)index {
  __weak typeof(self) weakSelf = self;
  if ([[NEChatDetectNetworkTool shareInstance] isNetworkExplicitlyUnreachable]) {
    [self showToast:commonLocalizable(@"network_error")];
    return;
  }
  [self showAlert:NETeamUIKitLocalizable(@"remove_manager_title")
          message:NETeamUIKitLocalizable(@"remove_manager_tip")
             sure:^(__unused UIAlertAction *action) {
    if ([[NEChatDetectNetworkTool shareInstance] isNetworkExplicitlyUnreachable]) {
      [weakSelf showToast:commonLocalizable(@"network_error")];
      return;
    }
    NSString *tid = weakSelf.teamId ?: @"";
    NSString *uid = model.nimUser.user.accountId ?: @"";
    if (tid.length == 0 || uid.length == 0) {
      return;
    }
    [weakSelf.viewmodel removeTeamManager:tid uids:@[uid] completion:^(NSError * _Nullable error) {
      if (error) {
        [weakSelf.view ne_makeToast:NETeamUIKitErrorToast(error)];
      } else {
        NSIndexSet *indexes = [weakSelf.viewmodel.managers indexesOfObjectsPassingTest:^BOOL(NETeamMemberInfoModel * _Nonnull obj, __unused NSUInteger idx, __unused BOOL * _Nonnull stop) {
          return [obj.nimUser.user.accountId isEqualToString:uid];
        }];
        if (indexes.count > 0) {
          [weakSelf.viewmodel.managers removeObjectsAtIndexes:indexes];
          [weakSelf sortAndReloadData];
        }
      }
    }];
  }];
}

- (void)didClickRemoveButton:(NETeamMemberInfoModel *)model :(NSInteger)index {
  [self didClickRemoveButton:model index:index];
}

- (NSSet<NSString *> *)getFilters {
  NSMutableSet<NSString *> *filters = [NSMutableSet set];
  NSArray<NETeamMemberInfoModel *> *managerSnapshot = [self.viewmodel.managers copy];
  for (NETeamMemberInfoModel *model in managerSnapshot) {
    NSString *uid = model.nimUser.user.accountId ?: @"";
    if (uid.length > 0) {
      [filters addObject:uid];
    }
  }
  return filters.copy;
}

- (void)sortAndReloadData {
  [self.viewmodel.managers sortUsingComparator:^NSComparisonResult(NETeamMemberInfoModel * _Nonnull obj1, NETeamMemberInfoModel * _Nonnull obj2) {
    int64_t time1 = obj1.teamMember.joinTime;
    int64_t time2 = obj2.teamMember.joinTime;
    if (time2 > time1) return NSOrderedAscending;
    if (time2 < time1) return NSOrderedDescending;
    return NSOrderedSame;
  }];
  [self.contentTableView reloadData];
}

- (void)didNeedReloadData {
  [self sortAndReloadData];
}

- (TeamManagerListViewModel *)viewmodel {
  if (!_viewmodel) {
    _viewmodel = [[TeamManagerListViewModel alloc] init];
  }
  return _viewmodel;
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

@end
