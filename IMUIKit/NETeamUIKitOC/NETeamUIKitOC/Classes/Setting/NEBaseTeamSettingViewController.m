// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseTeamSettingViewController.h"
#import "TeamConstant.h"
#import "TeamDetailHeaderView.h"
#import "SettingCellModel.h"
#import "SettingSectionModel.h"
#import "NEBaseTeamMembersController.h"
#import "NEBaseTeamSettingCell.h"
#import <NEChatKit/IMKitConfigCenter.h>
#import <NEChatKit/NEChatKitOC.h>
#import <NEChatUIKitOC/NETeamUserManager.h>
#import <NEChatKit/NEChatDetectNetworkTool.h>
#import <NEChatKit/NEConstant.h>
#import <NEChatKit/NSObject+NECommon.h>
#import <NEChatKit/UIColor+NECommon.h>
#import <NECommonUIKitOC/UIView+YXToast.h>
#import <NEChatKit/NERouterUrl.h>
#import <NEChatKit/Router.h>
#import <NEChatKit/IMKitClient.h>
#import <NEChatKit/NEALog.h>
#import <NEChatKit/NECoreIM2Constant.h>

static NSString * const NETeamContactSelectedUsersRouter = @"imkit://contact.selectUser.page";
static NSString * const NETeamContactFusionSelectRouter = @"imkit://contact/fusionselector.page";
static NSString * const NETeamContactUserSelectRouter = @"imkit://contact/selector.page";
static NSString * const NETeamMeSettingRouter = @"imkit://mine/userInfo.page";
static NSString * const NETeamContactUserInfoPageRouter = @"imkit://contact/userInfo.page";
static NSString * const NETeamPushPinMessageVCRouter = @"imkit://chat/pinMessage.page";
static NSString * const NETeamSearchMessageRouter = @"imkit://chat/searchMessage.page";

@interface NEBaseTeamSettingViewController ()
@property (nonatomic, strong, readwrite) TeamSettingViewModel *viewModel;
@property (nonatomic, strong, readwrite) UITableView *contentTableView;
@property (nonatomic, strong, readwrite) TeamDetailHeaderView *teamHeaderView;
@property (nonatomic, strong, readwrite) UILabel *memberLabel;
@property (nonatomic, strong, readwrite) UILabel *memberCountLabel;
@property (nonatomic, strong, readwrite) UICollectionView *userinfoCollectionView;
@property (nonatomic, strong, readwrite) ExpandButton *addButton;
@end

@implementation NEBaseTeamSettingViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    _teamSettingType = TeamSettingTypeSenior;
    _className = @"TeamSettingViewController";
    _cellClassDic = [NSMutableDictionary dictionary];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    _teamSettingType = TeamSettingTypeSenior;
    _className = @"TeamSettingViewController";
    _cellClassDic = [NSMutableDictionary dictionary];
  }
  return self;
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  if (self.viewModel.teamInfoModel) {
    [self.teamHeaderView setData:self.viewModel.teamInfoModel.team showOwner:NO];
  }
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.title = NETeamUIKitLocalizable(@"setting");
  self.viewModel.delegate = self;
  self.navigationView.moreButton.hidden = YES;
  [self setupUI];

  NSString *teamId = self.teamId ?: @"";
  if (teamId.length <= 0) {
    [self showToast:@"team id is nil"];
    return;
  }

  if ([[NETeamUserManager shared] getTeamInfo] == nil) {
    [[NETeamUserManager shared] loadData:teamId];
  }

  __weak typeof(self) weakSelf = self;
  [self.viewModel getCurrentMember:[IMKitClient instance].account
                            teamId:teamId
                        completion:^(V2NIMTeamMember * _Nullable member, NSError * _Nullable error) {
    if (member) {
      [weakSelf requestSettingData:teamId member:member];
    } else if (error) {
      [weakSelf showToast:NETeamUIKitErrorToast(error)];
    }
  }];
}

- (void)reloadSectionData {
}

- (void)didRefreshUserinfoCollection {
  [self.userinfoCollectionView reloadData];
}

- (void)setupUI {
  [self.viewModel getData];
  self.view.backgroundColor = UIColor.ne_lightBackgroundColor;
  [self.view addSubview:self.contentTableView];
  [NSLayoutConstraint activateConstraints:@[
    [self.contentTableView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
    [self.contentTableView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
    [self.contentTableView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:self.topConstant],
    [self.contentTableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
  ]];

  [self.cellClassDic enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, Class  _Nonnull obj, __unused BOOL * _Nonnull stop) {
    [self.contentTableView registerClass:obj forCellReuseIdentifier:key.stringValue];
  }];

  UIGestureRecognizer *pan = self.navigationController.interactivePopGestureRecognizer;
  if (pan) {
    [self.contentTableView.panGestureRecognizer requireGestureRecognizerToFail:pan];
  }

  [self resetupUI];
}

- (void)setTeamHeaderInfo {
  [self.teamHeaderView setData:self.viewModel.teamInfoModel.team showOwner:NO];
}

- (void)requestSettingData:(NSString *)teamId member:(V2NIMTeamMember *)member {
  (void)member;
  __weak typeof(self) weakSelf = self;
  [self.viewModel getTeamWithMembers:teamId completion:^(NSError * _Nullable error) {
    [NEALog infoLog:[NSString stringWithFormat:@"%@ %@", NETeamUIKitModuleName, weakSelf.className]
               desc:[NSString stringWithFormat:@"CALLBACK getTeamInfo %@", error.localizedDescription ?: @"no error"]];
    if (error) {
      if (error.code == protocolSendFailed) {
        [weakSelf showToast:commonLocalizable(@"network_error")];
      } else if (error.code == teamNotExistCode) {
        [weakSelf showToast:commonLocalizable(@"team_not_exist")];
      } else {
        [weakSelf showToast:NETeamUIKitErrorToast(error)];
      }
      return;
    }

    if (weakSelf.viewModel.teamInfoModel.team.teamType == V2NIM_TEAM_TYPE_NORMAL) {
      NSString *custom = weakSelf.viewModel.teamInfoModel.team.serverExtension ?: @"";
      if ([custom containsString:discussTeamKey]) {
        weakSelf.teamSettingType = TeamSettingTypeDiscuss;
        weakSelf.isSeniorDiscuss = YES;
      } else {
        weakSelf.teamSettingType = TeamSettingTypeSenior;
      }
    }
    weakSelf.viewModel.teamSettingType = weakSelf.teamSettingType;
    [weakSelf resetupUI];
    [weakSelf.viewModel getAllTeamMemberInfos:teamId
                                    queryType:V2NIM_TEAM_MEMBER_ROLE_QUERY_TYPE_ALL
                                   completion:^(__unused NSError * _Nullable memberError) {
      [NEALog infoLog:[[self class] className]
                 desc:[NSString stringWithFormat:@"CALLBACK getAllTeamMemberInfos %@", memberError.localizedDescription ?: @"no error"]];
    }];
  }];
}

- (void)resetupUI {
  [self reloadSectionData];
  [self checkoutAddShowOrHide];
  self.contentTableView.tableHeaderView = [self getHeaderView];
  self.contentTableView.tableFooterView = [self getFooterView];
  [self.contentTableView reloadData];
  [self didRefreshUserinfoCollection];
}

- (UIView *)getHeaderView {
  return [[UIView alloc] init];
}

- (UIView *)getFooterView {
  return nil;
}

- (NSString *)getBottomText {
  if (self.teamSettingType == TeamSettingTypeDiscuss) {
    return NETeamUIKitLocalizable(@"leave_discuss");
  }
  if (self.teamSettingType == TeamSettingTypeSenior) {
    return [self.viewModel isOwner] ? NETeamUIKitLocalizable(@"dismiss_team") : NETeamUIKitLocalizable(@"leave_team");
  }
  return nil;
}

- (void)setupUserInfoCollection:(UIView *)cornerView {
  (void)cornerView;
}

- (void)addUser {
  if (self.isRequestingData) {
    return;
  }
  self.isRequestingData = YES;

  __weak typeof(self) weakSelf = self;
  [[Router shared] register:NETeamContactSelectedUsersRouter closure:^(NSDictionary<NSString *,id> *params) {
    NSArray<NSString *> *accids = [params[@"accids"] isKindOfClass:[NSArray class]] ? params[@"accids"] : nil;
    NSString *teamId = weakSelf.viewModel.teamInfoModel.team.teamId ?: @"";
    if (accids.count <= 0 || teamId.length <= 0) {
      return;
    }

    V2NIMTeamAgreeMode agreeMode = weakSelf.viewModel.teamInfoModel.team.agreeMode;
    V2NIMTeamType type = weakSelf.viewModel.teamInfoModel.team.teamType;
    if (agreeMode == V2NIM_TEAM_AGREE_MODE_NO_AUTH || type == V2NIM_TEAM_TYPE_NORMAL) {
      [weakSelf didAddUser:accids teamId:teamId];
    }
  }];

  NSMutableDictionary<NSString *, id> *params = [NSMutableDictionary dictionary];
  params[@"nav"] = self.navigationController ?: [NSNull null];
  NSMutableSet<NSString *> *filters = [NSMutableSet set];

  [self showToast:NETeamUIKitLocalizable(@"requesting")];
  [[NETeamUserManager shared] getAllTeamMembers:self.viewModel.teamInfoModel.team.teamId ?: @""
                                      queryType:V2NIM_TEAM_MEMBER_ROLE_QUERY_TYPE_ALL
                                     completion:^(__unused NSArray<NEUserWithFriend *> *users) {
    weakSelf.isRequestingData = NO;
    NSArray<V2NIMTeamMember *> *models = [[NETeamUserManager shared] getAllTeamMembers];
    for (V2NIMTeamMember *model in models) {
      if (model.accountId.length > 0) {
        [filters addObject:model.accountId];
      }
    }

    if (filters.count > 0) {
      params[@"filters"] = filters;
    }

    NSInteger memberLimit = weakSelf.viewModel.teamInfoModel.team.memberLimit > 0 ?
      weakSelf.viewModel.teamInfoModel.team.memberLimit :
      inviteNumberLimit + filters.count;
    params[@"limit"] = @(memberLimit - filters.count);

    if ([IMKitConfigCenter shared].enableAIUser) {
      [[Router shared] use:NETeamContactFusionSelectRouter parameters:params closure:nil];
    } else {
      [[Router shared] use:NETeamContactUserSelectRouter parameters:params closure:nil];
    }
  }];
}

- (void)removeTeamForMyself {
  if (![[NEChatDetectNetworkTool shareInstance] isNetworkReachability]) {
    [self showToast:commonLocalizable(@"network_error")];
    return;
  }

  __weak typeof(self) weakSelf = self;
  if (self.teamSettingType == TeamSettingTypeSenior) {
    NSString *message = [self.viewModel isOwner] ? NETeamUIKitLocalizable(@"dissolute_team_chat") : NETeamUIKitLocalizable(@"quit_team_chat");
    [self showAlert:nil message:message sure:^(__unused UIAlertAction *action) {
      if (![[NEChatDetectNetworkTool shareInstance] isNetworkReachability]) {
        [weakSelf showToast:commonLocalizable(@"network_error")];
        return;
      }
      if ([weakSelf.viewModel isOwner]) {
        [weakSelf dismissTeam];
      } else {
        [weakSelf leaveTeam];
      }
    }];
  } else if (self.teamSettingType == TeamSettingTypeDiscuss) {
    [self showAlert:nil message:NETeamUIKitLocalizable(@"quit_discuss_chat") sure:^(__unused UIAlertAction *action) {
      if (![[NEChatDetectNetworkTool shareInstance] isNetworkReachability]) {
        [weakSelf showToast:commonLocalizable(@"network_error")];
        return;
      }
      [weakSelf leaveDiscuss];
    }];
  }
}

- (void)leaveDiscuss {
  __weak typeof(self) weakSelf = self;
  if (self.isSeniorDiscuss && [self.viewModel isOwner]) {
    [self.view ne_makeToastActivity:NEToastPositionCenter];
    [self.viewModel transferTeamOwner:^(NSError * _Nullable error) {
      [weakSelf.view ne_hideToastActivity];
      if (error) {
        [weakSelf didError:error];
      } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:NETeamUIKitPopGroupChatVCNotification object:nil];
      }
    }];
    return;
  }
  [self leaveTeam];
}

- (void)toInfoView {
}

- (void)toMemberList {
  NEBaseTeamMembersController *memberController = [[NEBaseTeamMembersController alloc] initWithTeamId:self.viewModel.teamInfoModel.team.teamId];
  [self.navigationController pushViewController:memberController animated:YES];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  (void)collectionView;
  (void)section;
  return self.viewModel.teamInfoModel.users.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  (void)collectionView;
  (void)indexPath;
  return [[UICollectionViewCell alloc] init];
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
  (void)collectionView;
  (void)collectionViewLayout;
  (void)indexPath;
  return CGSizeZero;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
  (void)collectionView;
  if (self.viewModel.teamInfoModel.users.count <= indexPath.row) {
    return;
  }
  NETeamMemberInfoModel *member = self.viewModel.teamInfoModel.users[indexPath.row];
  NEUserWithFriend *nimUser = member.nimUser;
  NSString *uid = nimUser.user.accountId ?: @"";
  if (uid.length <= 0) {
    return;
  }

  if ([[IMKitClient instance] isMe:uid]) {
    [[Router shared] use:NETeamMeSettingRouter
              parameters:@{@"nav": self.navigationController ?: [NSNull null]}
                 closure:nil];
  } else {
    [[Router shared] use:NETeamContactUserInfoPageRouter
              parameters:@{
                @"nav": self.navigationController ?: [NSNull null],
                @"uid": uid,
              }
                 closure:nil];
  }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  (void)tableView;
  if (self.viewModel.sectionData.count > section) {
    SettingSectionModel *model = self.viewModel.sectionData[section];
    return model.cellModels.count;
  }
  return 0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  (void)tableView;
  return self.viewModel.sectionData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  SettingCellModel *model = self.viewModel.sectionData[indexPath.section].cellModels[indexPath.row];
  NEBaseTeamSettingCell *cell = [tableView dequeueReusableCellWithIdentifier:[NSString stringWithFormat:@"%ld", (long)model.type]
                                                                forIndexPath:indexPath];
  if ([cell isKindOfClass:[NEBaseTeamSettingCell class]]) {
    [cell configure:model];
    return cell;
  }
  return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  (void)tableView;
  SettingCellModel *model = self.viewModel.sectionData[indexPath.section].cellModels[indexPath.row];
  if (model.cellClick) {
    model.cellClick();
  }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  (void)tableView;
  SettingCellModel *model = self.viewModel.sectionData[indexPath.section].cellModels[indexPath.row];
  return model.rowHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  (void)tableView;
  if (self.viewModel.sectionData.count > section) {
    SettingSectionModel *model = self.viewModel.sectionData[section];
    if (model.cellModels.count > 0) {
      return 12.0;
    }
  }
  return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  (void)tableView;
  (void)section;
  UIView *headerView = [[UIView alloc] init];
  headerView.backgroundColor = UIColor.ne_lightBackgroundColor;
  return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
  (void)tableView;
  if (section == self.viewModel.sectionData.count - 1) {
    return 12.0;
  }
  return 0;
}

- (void)didAddUser:(NSArray<NSString *> *)accids teamId:(NSString *)teamId {
  __weak typeof(self) weakSelf = self;
  [self.view ne_makeToastActivity:NEToastPositionCenter];
  [self.viewModel inviteUsers:accids teamId:teamId completion:^(NSError * _Nullable error, NSArray<V2NIMTeamMember *> * _Nullable members) {
    if (error) {
      [weakSelf.view ne_hideToastActivity];
      if (error.code == protocolSendFailed) {
        [weakSelf showToast:commonLocalizable(@"network_error")];
      } else if (error.code == noPermissionInviteCode) {
        [weakSelf showToast:NETeamUIKitLocalizable(@"no_permission_tip")];
      } else {
        [weakSelf showToast:NETeamUIKitErrorToast(error)];
      }
    } else {
      (void)members;
      [weakSelf.view ne_hideToastActivity];
    }
  }];
}

- (void)dismissTeam {
  NSString *teamId = self.teamId ?: @"";
  if (teamId.length <= 0) {
    return;
  }

  __weak typeof(self) weakSelf = self;
  [self.view ne_makeToastActivity:NEToastPositionCenter];
  [self.viewModel dismissTeam:teamId completion:^(NSError * _Nullable error) {
    [NEALog infoLog:[NSString stringWithFormat:@"%@ %@", NETeamUIKitModuleName, weakSelf.className]
               desc:[NSString stringWithFormat:@"CALLBACK dismissTeam %@", error.localizedDescription ?: @"no error"]];
    [weakSelf.view ne_hideToastActivity];
    if (error) {
      [weakSelf didError:error];
    } else {
      [[NSNotificationCenter defaultCenter] postNotificationName:NETeamUIKitPopGroupChatVCNotification object:nil];
    }
  }];
}

- (void)refreshMemberCount {
  NSInteger count = self.viewModel.teamInfoModel.team.memberCount;
  self.memberCountLabel.text = [NSString stringWithFormat:@"%ld", (long)count];
}

- (void)leaveTeam {
  NSString *teamId = self.teamId ?: @"";
  if (teamId.length <= 0) {
    return;
  }

  __weak typeof(self) weakSelf = self;
  [self.view ne_makeToastActivity:NEToastPositionCenter];
  [self.viewModel leaveTeam:teamId completion:^(NSError * _Nullable error) {
    [NEALog infoLog:[NSString stringWithFormat:@"%@ %@", NETeamUIKitModuleName, weakSelf.className ?: @"TeamSettingViewController"]
               desc:[NSString stringWithFormat:@"CALLBACK quitTeam %@", error.localizedDescription ?: @"no error"]];
    [weakSelf.view ne_hideToastActivity];
    if (error) {
      [weakSelf didError:error];
      return;
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      [weakSelf.viewModel getTeamWithMembers:teamId completion:^(__unused NSError * _Nullable teamError) {
        if (weakSelf.viewModel.teamInfoModel.team.memberCount == 1 && [weakSelf.viewModel isOwner]) {
          [weakSelf dismissTeam];
        } else {
          [[NSNotificationCenter defaultCenter] postNotificationName:NETeamUIKitPopGroupChatVCNotification object:nil];
        }
      }];
    });
  }];
}

- (void)didClickMark {
  NSString *teamId = self.teamId ?: @"";
  if (teamId.length <= 0) {
    return;
  }
  NSString *conversationId = [V2NIMConversationIdUtil teamConversationId:teamId];
  [[Router shared] use:NETeamPushPinMessageVCRouter
            parameters:@{
              @"nav": self.navigationController ?: [NSNull null],
              @"conversationId": conversationId ?: @"",
            }
               closure:nil];
}

- (void)didError:(NSError *)error {
  [self showToast:NETeamUIKitErrorToast(error)];
}

- (void)didShowNoNetworkToast {
  [self showToast:commonLocalizable(@"network_error")];
}

- (void)didNeedRefreshUI {
  [self setTeamHeaderInfo];
  [self refreshMemberCount];
  [self checkoutAddShowOrHide];
  [self reloadSectionData];
  [self.contentTableView reloadData];
  [self didRefreshUserinfoCollection];
}

- (void)didClickTeamManage {
}

- (void)checkoutAddShowOrHide {
}

- (void)updateInviteModeOwnerAction:(SettingCellModel *)model {
  __weak typeof(self) weakSelf = self;
  [weakSelf.view ne_makeToastActivity:NEToastPositionCenter];
  [weakSelf.viewModel.teamRepo updateInviteMode:weakSelf.teamId ?: @""
                                       teamType:V2NIM_TEAM_TYPE_NORMAL
                                           mode:V2NIM_TEAM_INVITE_MODE_MANAGER
                                     completion:^(NSError * _Nullable error, V2NIMTeam * _Nullable team) {
    [NEALog infoLog:[NSString stringWithFormat:@"%@ %@", NETeamUIKitModuleName, [weakSelf className]]
               desc:[NSString stringWithFormat:@"CALLBACK updateInviteMode %@", error.localizedDescription ?: @"no error"]];
    [weakSelf.view ne_hideToastActivity];
    if (error) {
      [weakSelf didError:error];
      return;
    }
    weakSelf.viewModel.teamInfoModel.team = team;
    model.subTitle = NETeamUIKitLocalizable(@"team_owner");
    [weakSelf.contentTableView reloadData];
  }];
}

- (void)updateInviteModeAllAction:(SettingCellModel *)model {
  __weak typeof(self) weakSelf = self;
  [weakSelf.view ne_makeToastActivity:NEToastPositionCenter];
  [weakSelf.viewModel.teamRepo updateInviteMode:weakSelf.teamId ?: @""
                                       teamType:V2NIM_TEAM_TYPE_NORMAL
                                           mode:V2NIM_TEAM_INVITE_MODE_ALL
                                     completion:^(NSError * _Nullable error, V2NIMTeam * _Nullable team) {
    [NEALog infoLog:[NSString stringWithFormat:@"%@ %@", NETeamUIKitModuleName, [weakSelf className]]
               desc:[NSString stringWithFormat:@"CALLBACK updateInviteMode %@", error.localizedDescription ?: @"no error"]];
    [weakSelf.view ne_hideToastActivity];
    if (error) {
      [weakSelf didError:error];
      return;
    }
    weakSelf.viewModel.teamInfoModel.team = team;
    model.subTitle = NETeamUIKitLocalizable(@"team_all");
    [weakSelf.contentTableView reloadData];
  }];
}

- (void)didClickChangeNick {
}

- (void)didClickHistoryMessage {
  NSString *teamId = self.teamId ?: @"";
  if (teamId.length <= 0) {
    return;
  }

  NSString *conversationId = [V2NIMConversationIdUtil teamConversationId:teamId];
  [[Router shared] use:NETeamSearchMessageRouter
            parameters:@{
              @"nav": self.navigationController ?: [NSNull null],
              @"conversationId": conversationId ?: @"",
              @"teamInfo": self.viewModel.teamInfoModel ?: [NSNull null],
            }
               closure:nil];
}

- (NSArray<NETeamMemberInfoModel *> *)getManagerUsers {
  NSMutableArray<NETeamMemberInfoModel *> *members = [NSMutableArray array];
  for (NETeamMemberInfoModel *model in self.viewModel.teamInfoModel.users) {
    if (model.teamMember.memberRole == V2NIM_TEAM_MEMBER_ROLE_MANAGER) {
      [members addObject:model];
    }
  }
  return members.copy;
}

- (void)willMoveToParentViewController:(UIViewController *)parent {
  [super willMoveToParentViewController:parent];
  if ([IMKitConfigCenter shared].enableOnlineStatus && parent == nil) {
    [self.viewModel clear];
  }
}

- (TeamSettingViewModel *)viewModel {
  if (!_viewModel) {
    _viewModel = [[TeamSettingViewModel alloc] init];
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

- (TeamDetailHeaderView *)teamHeaderView {
  if (!_teamHeaderView) {
    _teamHeaderView = [[TeamDetailHeaderView alloc] initWithAvatarWH:42.0];
    _teamHeaderView.translatesAutoresizingMaskIntoConstraints = NO;
    _teamHeaderView.clipsToBounds = YES;
    _teamHeaderView.teamNameLabel.font = [NEConstant defaultTextFont:16.0];
    _teamHeaderView.teamNameLabel.textColor = UIColor.ne_darkText;
    _teamHeaderView.lineView.hidden = YES;
  }
  return _teamHeaderView;
}

- (UILabel *)memberLabel {
  if (!_memberLabel) {
    _memberLabel = [[UILabel alloc] init];
    _memberLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _memberLabel.textColor = [NEConstant hexRGB:0x333333];
    _memberLabel.font = [NEConstant defaultTextFont:16.0];
    _memberLabel.accessibilityIdentifier = @"id.member";
  }
  return _memberLabel;
}

- (UILabel *)memberCountLabel {
  if (!_memberCountLabel) {
    _memberCountLabel = [[UILabel alloc] init];
    _memberCountLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _memberCountLabel.font = [NEConstant defaultTextFont:16.0];
    _memberCountLabel.textColor = [NEConstant hexRGB:0x999999];
    _memberCountLabel.accessibilityIdentifier = @"id.count";
  }
  return _memberCountLabel;
}

- (UICollectionView *)userinfoCollectionView {
  if (!_userinfoCollectionView) {
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    flowLayout.minimumLineSpacing = 0.0;
    flowLayout.minimumInteritemSpacing = 0.0;
    _userinfoCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
    _userinfoCollectionView.translatesAutoresizingMaskIntoConstraints = NO;
    _userinfoCollectionView.delegate = self;
    _userinfoCollectionView.dataSource = self;
    _userinfoCollectionView.backgroundColor = UIColor.clearColor;
    _userinfoCollectionView.showsHorizontalScrollIndicator = NO;
    _userinfoCollectionView.scrollEnabled = NO;
  }
  return _userinfoCollectionView;
}

- (ExpandButton *)addButton {
  if (!_addButton) {
    _addButton = [[ExpandButton alloc] init];
    _addButton.translatesAutoresizingMaskIntoConstraints = NO;
    _addButton.accessibilityIdentifier = @"id.add";
  }
  return _addButton;
}

@end
