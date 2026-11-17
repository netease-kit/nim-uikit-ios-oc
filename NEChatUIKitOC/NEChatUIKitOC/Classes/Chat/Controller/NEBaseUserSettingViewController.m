// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseUserSettingViewController.h"
#import <NEChatKit/NECommonLoader.h>
#import <NEChatKit/UIColor+NECommon.h>
#import <NEChatKit/NEChatKit.h>

#import <NEChatKit/NECoreIM2Constant.h>
#import <NEBaseUIKitOC/NEBaseUIKitOC.h>
#import <NEChatKit/Router.h>
#import <NEChatKit/NERouterUrl.h>
#import "NEChatUIConstant.h"
#import "ChatCellConstantValue.h"
#import "ChatNavigationView.h"
#import "ChatViewController.h"
#import <NEChatKit/IMKitConfigCenter.h>
#import <NEChatKit/NEAIUserManager.h>

static NSString * const NEChatContactSelectedUsersRouter = @"imkit://contact.selectUser.page";
static NSString * const NEChatTeamCreateDisussRouter = @"imkit://team.create.discuss";
static NSString * const NEChatContactFusionSelectRouter = @"imkit://contact/fusionselector.page";
static NSString * const NEChatContactUserSelectRouter = @"imkit://contact/selector.page";
static NSString * const NEChatTeamCreateDiscussResultRouter = @"imkit://team.create.discuss.result";
static NSString * const NEChatContactUserInfoPageRouter = @"imkit://contact/userInfo.page";
static NSString * const NEChatPushPinMessageVCRouter = @"imkit://chat/pinMessage.page";
static NSString * const NEChatPushTeamChatVCRouter = @"imkit://chat/teamChat.page";
static NSString * const NEChatSearchMessageRouter = @"imkit://chat/searchMessage.page";

@implementation NEBaseUserSettingViewController

- (instancetype)initWithUserId:(NSString *)userId {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.userId = userId;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.contentTableTopAnchor.constant = self.topConstant;
}


- (void)synchronizeTableSupplementaryWidths {
  CGFloat width = CGRectGetWidth(self.contentTable.bounds);
  if (width <= 0) return;
  UIView *header = self.contentTable.tableHeaderView;
  if (header && fabs(CGRectGetWidth(header.frame) - width) > 0.5) {
    CGRect frame = header.frame;
    frame.size.width = width;
    header.frame = frame;
    self.contentTable.tableHeaderView = header;
  }
  UIView *footer = self.contentTable.tableFooterView;
  if (footer && fabs(CGRectGetWidth(footer.frame) - width) > 0.5) {
    CGRect frame = footer.frame;
    frame.size.width = width;
    footer.frame = frame;
    self.contentTable.tableFooterView = footer;
  }
}

- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  [self synchronizeTableSupplementaryWidths];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.viewModel.delegate = self;
    self.viewModel.fromBotSubSession = self.fromBotSubSession;
    if (self.userId) {
        __weak typeof(self) weakSelf = self;
        [self.viewModel getConversation:self.userId completion:^(NSError * _Nullable error) {
            [weakSelf.viewModel getUserSettingModel:weakSelf.userId completion:^{
                weakSelf.contentTable.tableHeaderView = [weakSelf headerView];
                [weakSelf didLoadData];
                [weakSelf.contentTable reloadData];
            }];
        }];
    }
    [self setupUI];
}

- (void)didLoadData {}

- (void)setupUI {
    self.view.backgroundColor = UIColor.ne_lightBackgroundColor;
    self.title = chatLocalizable(@"chat_setting");
    self.navigationView.moreButton.hidden = YES;
    self.navigationView.backgroundColor = UIColor.ne_lightBackgroundColor;

    [self.view addSubview:self.contentTable];
    self.contentTableTopAnchor = [self.contentTable.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:self.topConstant];
    self.contentTableTopAnchor.active = YES;
    [NSLayoutConstraint activateConstraints:@[
        [self.contentTable.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
        [self.contentTable.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
        [self.contentTable.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];

    for (NSNumber *key in self.cellClassDic) {
        [self.contentTable registerClass:self.cellClassDic[key] forCellReuseIdentifier:key.stringValue];
    }

    if (self.navigationController.interactivePopGestureRecognizer) {
        [self.contentTable.panGestureRecognizer requireGestureRecognizerToFail:self.navigationController.interactivePopGestureRecognizer];
    }
}

- (UIView *)headerView {
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 110)];
    headerView.backgroundColor = UIColor.clearColor;

    UIView *cornerBackView = [[UIView alloc] init];
    cornerBackView.layer.cornerRadius = 8.0;
    cornerBackView.backgroundColor = UIColor.whiteColor;
    cornerBackView.translatesAutoresizingMaskIntoConstraints = NO;
    [headerView addSubview:cornerBackView];
    [NSLayoutConstraint activateConstraints:@[
        [cornerBackView.bottomAnchor constraintEqualToAnchor:headerView.bottomAnchor constant:-12],
        [cornerBackView.leftAnchor constraintEqualToAnchor:headerView.leftAnchor constant:20],
        [cornerBackView.rightAnchor constraintEqualToAnchor:headerView.rightAnchor constant:-20],
        [cornerBackView.heightAnchor constraintEqualToConstant:86.0],
    ]];

    [cornerBackView addSubview:self.userHeaderView];
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] init];
    tapGesture.numberOfTapsRequired = 1;
    tapGesture.numberOfTouchesRequired = 1;
    [self.userHeaderView addGestureRecognizer:tapGesture];

    NSString *url = self.viewModel.userInfo.user.avatar;
    NSString *name = [self.viewModel.userInfo shortName:YES count:2] ?: @"";
    NSString *accountId = self.viewModel.userInfo.user.accountId ?: @"";
    [self.userHeaderView configHeadData:url name:name uid:accountId];

    self.nameLabel.text = [self.viewModel.userInfo showName];
    [cornerBackView addSubview:self.nameLabel];

    if ([self shouldShowAddMemberButton]) {
        [NSLayoutConstraint activateConstraints:@[
            [self.userHeaderView.leftAnchor constraintEqualToAnchor:cornerBackView.leftAnchor constant:16],
            [self.userHeaderView.topAnchor constraintEqualToAnchor:cornerBackView.topAnchor constant:12],
            [self.userHeaderView.widthAnchor constraintEqualToConstant:fun_chat_min_h],
            [self.userHeaderView.heightAnchor constraintEqualToConstant:fun_chat_min_h],
        ]];

        self.nameLabel.font = [NEConstant defaultTextFont:12];
        self.nameLabel.textAlignment = NSTextAlignmentCenter;
        [NSLayoutConstraint activateConstraints:@[
            [self.nameLabel.leftAnchor constraintEqualToAnchor:self.userHeaderView.leftAnchor constant:-12.0],
            [self.nameLabel.rightAnchor constraintEqualToAnchor:self.userHeaderView.rightAnchor constant:12.0],
            [self.nameLabel.topAnchor constraintEqualToAnchor:self.userHeaderView.bottomAnchor constant:6.0],
        ]];

        [cornerBackView addSubview:self.addButton];
        [self.addButton addTarget:self action:@selector(createDiscuss) forControlEvents:UIControlEventTouchUpInside];
        [NSLayoutConstraint activateConstraints:@[
            [self.addButton.leftAnchor constraintEqualToAnchor:self.userHeaderView.rightAnchor constant:20.0],
            [self.addButton.topAnchor constraintEqualToAnchor:self.userHeaderView.topAnchor],
            [self.addButton.widthAnchor constraintEqualToConstant:42.0],
            [self.addButton.heightAnchor constraintEqualToConstant:42.0],
        ]];
    } else {
        [NSLayoutConstraint activateConstraints:@[
            [self.userHeaderView.leftAnchor constraintEqualToAnchor:cornerBackView.leftAnchor constant:16],
            [self.userHeaderView.centerYAnchor constraintEqualToAnchor:cornerBackView.centerYAnchor],
            [self.userHeaderView.widthAnchor constraintEqualToConstant:60],
            [self.userHeaderView.heightAnchor constraintEqualToConstant:60],
        ]];

        self.nameLabel.font = [NEConstant defaultTextFont:16];
        self.nameLabel.textAlignment = NSTextAlignmentLeft;
        [NSLayoutConstraint activateConstraints:@[
            [self.nameLabel.leftAnchor constraintEqualToAnchor:self.userHeaderView.rightAnchor constant:16.0],
            [self.nameLabel.rightAnchor constraintEqualToAnchor:cornerBackView.rightAnchor],
            [self.nameLabel.centerYAnchor constraintEqualToAnchor:self.userHeaderView.centerYAnchor],
        ]];
    }

    return headerView;
}

- (BOOL)shouldShowAddMemberButton {
    if (self.fromBotSubSession || ![IMKitConfigCenter shared].enableTeam) {
        return NO;
    }
    NSString *userId = [self.userId isKindOfClass:[NSString class]] ? self.userId : nil;
    return userId.length > 0 && ![[NEAIRobotManager shared] isRobot:userId];
}

- (NSArray<UIViewController *> *)filterStackViewController {
    return [self.navigationController.viewControllers filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(UIViewController *vc, NSDictionary *bindings) {
        return ![vc isKindOfClass:[ChatViewController class]] && ![vc isKindOfClass:[NEBaseUserSettingViewController class]];
    }]];
}

- (void)createDiscuss {
    __weak typeof(self) weakSelf = self;
    [Router.shared register:NEChatContactSelectedUsersRouter closure:^(NSDictionary * _Nonnull param) {
        NSMutableDictionary *convertParam = [NSMutableDictionary dictionary];
        for (NSString *key in param) {
            if ([key isEqualToString:@"names"] && [param[key] isKindOfClass:[NSString class]]) {
                convertParam[key] = [NSString stringWithFormat:@"%@、%@", weakSelf.nameLabel.text ?: @"", param[key]];
            } else {
                convertParam[key] = param[key];
            }
        }
        [weakSelf.view makeToastActivity:YXToastPositionCenter];
        [Router.shared use:NEChatTeamCreateDisussRouter parameters:convertParam closure:nil];
    }];

    NSMutableSet<NSString *> *filters = [NSMutableSet set];
    [filters addObject:[[IMKitClient instance] account]];
    if (self.userId) {
        [filters addObject:self.userId];
    }

    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{
        @"nav": self.navigationController ?: [NSNull null],
        @"filters": filters,
        @"limit": @(inviteNumberLimit),
        @"uid": self.userId ?: @"",
    }];

    if ([IMKitConfigCenter shared].enableAIUser) {
        [Router.shared use:NEChatContactFusionSelectRouter parameters:params closure:nil];
    } else {
        [Router.shared use:NEChatContactUserSelectRouter parameters:params closure:nil];
    }

    [Router.shared register:NEChatTeamCreateDiscussResultRouter closure:^(NSDictionary * _Nonnull param) {
        [weakSelf.view ne_hideToastActivity];
        NSInteger code = [param[@"code"] integerValue];
        NSString *teamid = param[@"teamId"];
        if (code == 0 && teamid) {
            NSString *conversationId = [V2NIMConversationIdUtil teamConversationId:teamid];
            dispatch_async(dispatch_get_main_queue(), ^{
                NSArray *allControllers = [weakSelf filterStackViewController];
                UINavigationController *navigationController = weakSelf.navigationController;
                if (allControllers && navigationController) {
                    [navigationController setViewControllers:allControllers animated:NO];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [Router.shared use:NEChatPushTeamChatVCRouter
                                parameters:@{@"nav": navigationController,
                                              @"conversationId": conversationId ?: [NSNull null]}
                                   closure:nil];
                    });
                }
            });
        } else if (param[@"msg"]) {
            [weakSelf.view ne_makeToast:param[@"msg"]];
        }
    }];
}

- (void)showUserInfo {
    if (self.viewModel.userInfo) {
        [Router.shared use:NEChatContactUserInfoPageRouter
                parameters:@{@"nav": self.navigationController ?: [NSNull null], @"user": self.viewModel.userInfo}
                   closure:nil];
    }
}

#pragma mark - UITableViewDataSource, UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.viewModel.cellDatas.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    id model = self.viewModel.cellDatas[indexPath.row];
    NSString *reuseId = [NSString stringWithFormat:@"%ld", (long)[(UserSettingCellModel *)model type]];
    NEBaseUserSettingCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseId forIndexPath:indexPath];
    if (cell) {
        [cell configure:model];
        return cell;
    }
    return [[UITableViewCell alloc] init];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    id model = self.viewModel.cellDatas[indexPath.row];
    void (^block)(void) = [model cellClick];
    if (block) {
        block();
    }
}

#pragma mark - UserSettingViewModelDelegate

- (void)didNeedRefreshUI {
    [self didLoadData];
    [self.contentTable reloadData];
}

- (void)didError:(NSError *)error {
    [self.view ne_makeToast:error.localizedDescription];
}

- (void)didShowErrorMsg:(NSString *)msg {
    [self.view ne_makeToast:msg];
}

- (void)didClickMark {
    NSString *conversationId = self.userId.length > 0 ? [V2NIMConversationIdUtil p2pConversationId:self.userId] : nil;
    UINavigationController *nav = self.navigationController;
    if (conversationId.length > 0 && nav) {
        [Router.shared use:NEChatPushPinMessageVCRouter
                parameters:@{@"nav": nav, @"conversationId": conversationId}
                   closure:nil];
    }
}

- (void)didClickHistory {
    NSString *conversationId = self.userId.length > 0 ? [V2NIMConversationIdUtil p2pConversationId:self.userId] : nil;
    UINavigationController *nav = self.navigationController;
    if (conversationId.length > 0 && nav) {
        [Router.shared use:NEChatSearchMessageRouter
                parameters:@{@"nav": nav, @"conversationId": conversationId}
                   closure:nil];
    }
}

#pragma mark - Lazy Properties

- (UserSettingViewModel *)viewModel {
    if (!_viewModel) {
        _viewModel = [[UserSettingViewModel alloc] init];
    }
    return _viewModel;
}

- (NEUserHeaderView *)userHeaderView {
    if (!_userHeaderView) {
        _userHeaderView = [[NEUserHeaderView alloc] initWithFrame:CGRectZero];
        _userHeaderView.translatesAutoresizingMaskIntoConstraints = NO;
        _userHeaderView.clipsToBounds = YES;
        _userHeaderView.titleLabel.font = [NEConstant defaultTextFont:16.0];
        _userHeaderView.userInteractionEnabled = YES;
    }
    return _userHeaderView;
}

- (ExpandButton *)addButton {
    if (!_addButton) {
        _addButton = [[ExpandButton alloc] init];
        _addButton.translatesAutoresizingMaskIntoConstraints = NO;
        [_addButton setImage:chatLoadImage(@"setting_add") forState:UIControlStateNormal];
        _addButton.accessibilityIdentifier = @"id.add";
    }
    return _addButton;
}

- (UILabel *)nameLabel {
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _nameLabel.font = [NEConstant defaultTextFont:12.0];
        _nameLabel.textColor = UIColor.ne_darkText;
        _nameLabel.textAlignment = NSTextAlignmentCenter;
        _nameLabel.accessibilityIdentifier = @"id.name";
    }
    return _nameLabel;
}

- (UITableView *)contentTable {
    if (!_contentTable) {
        _contentTable = [[UITableView alloc] init];
        _contentTable.translatesAutoresizingMaskIntoConstraints = NO;
        _contentTable.backgroundColor = UIColor.clearColor;
        _contentTable.dataSource = self;
        _contentTable.delegate = self;
        _contentTable.separatorColor = UIColor.clearColor;
        _contentTable.separatorStyle = UITableViewCellSeparatorStyleNone;
        _contentTable.sectionHeaderHeight = 12.0;
        _contentTable.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 12)];
        if (@available(iOS 15.0, *)) {
            _contentTable.sectionHeaderTopPadding = 0.0;
        }
    }
    return _contentTable;
}

- (NSMutableDictionary *)cellClassDic {
    if (!_cellClassDic) {
        _cellClassDic = [NSMutableDictionary dictionary];
    }
    return _cellClassDic;
}

@end
