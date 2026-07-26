// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseSelectUserViewController.h"
#import "ChatNavigationView.h"
#import "UIImage+Chat.h"
#import <NEChatKit/UIColor+NECommon.h>
#import <NEChatKit/NEChatKitOC.h>
#import <NEChatKit/ChatConstant.h>
#import "NEChatUIConstant.h"
#import <NEChatKit/IMKitConfigCenter.h>
#import <NEChatKit/NEAIUserManager.h>

@interface NEBaseSelectUserViewController ()
@property (nonatomic, assign) BOOL showSelf;
@property (nonatomic, assign) BOOL showTeamMembers;
@end

@implementation NEBaseSelectUserViewController

- (instancetype)initWithConversationId:(NSString *)conversationId showSelf:(BOOL)showSelf showTeamMembers:(BOOL)showTeamMembers {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _conversationId = conversationId;
        _showSelf = showSelf;
        _showTeamMembers = showTeamMembers;
        _isShowAtAll = YES;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        _conversationId = @"";
        _showSelf = YES;
        _showTeamMembers = NO;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBarHidden = YES;
    self.navigationView.hidden = YES;
    [self commonUI];
    [self loadData];
}

- (void)commonUI {
    self.view.backgroundColor = UIColor.whiteColor;

    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.accessibilityIdentifier = @"id.arrowDown";
    [button setImage:[UIImage ne_imageNamed:@"arrowDown"] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(btnEvent:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    [NSLayoutConstraint activateConstraints:@[
        [button.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [button.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [button.widthAnchor constraintEqualToConstant:50],
        [button.heightAnchor constraintEqualToConstant:50],
    ]];

    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = chatLocalizable(@"user_select");
    label.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = UIColor.ne_darkText;
    [self.view addSubview:label];
    [NSLayoutConstraint activateConstraints:@[
        [label.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:0],
        [label.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [label.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:0],
        [label.heightAnchor constraintEqualToConstant:50],
    ]];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.sectionHeaderHeight = 0;
    self.tableView.sectionFooterHeight = 0;
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.tableFooterView = [[UIView alloc] init];
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    self.tableView.estimatedRowHeight = 0;
    self.tableView.estimatedSectionHeaderHeight = 0;
    self.tableView.estimatedSectionFooterHeight = 0;
    if (@available(iOS 15.0, *)) {
        self.tableView.sectionHeaderTopPadding = 0.0;
    }

    [self.view addSubview:self.tableView];
    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.topAnchor constraintEqualToAnchor:label.bottomAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],
    ]];
}

- (void)loadData {
    NSMutableArray<NETeamMemberInfoModel *> *aiUserMembers = [NSMutableArray array];
    if ([IMKitConfigCenter shared].enableAIUser) {
        NSArray *aiUsers = [[NEAIUserManager shared] getAIChatUserList];
        for (id user in aiUsers) {
            NETeamMemberInfoModel *teamMember = [[NETeamMemberInfoModel alloc] init];
            teamMember.nimUser = [[NEUserWithFriend alloc] initWithUser:user friend:nil];
            [aiUserMembers addObject:teamMember];
        }
    }

    if (!self.showTeamMembers) {
        NETeamInfoModel *team = [[NETeamInfoModel alloc] init];
        team.users = aiUserMembers;
        self.teamInfo = team;
        self.isShowAtAll = NO;
        [self.tableView reloadData];
        return;
    }

    if ([V2NIMConversationIdUtil conversationType:self.conversationId] != V2NIM_CONVERSATION_TYPE_TEAM) return;
    NSString *teamId = [V2NIMConversationIdUtil conversationTargetId:self.conversationId];
    if (!teamId) return;

    __weak typeof(self) weakSelf = self;
    [self.viewModel getTeamMembers:teamId completion:^(NSError * _Nullable error, NETeamInfoModel * _Nullable team) {
        if (error) {
            [weakSelf.view ne_makeToast:error.localizedDescription];
            return;
        }

        NETeamInfoModel *safeTeam = team ?: [[NETeamInfoModel alloc] init];
        if (![safeTeam.users isKindOfClass:[NSMutableArray class]]) {
            safeTeam.users = [safeTeam.users mutableCopy] ?: [NSMutableArray array];
        }

        NSInteger selfIndex = -1;
        if (!weakSelf.showSelf) {
            for (NSInteger i = 0; i < safeTeam.users.count; i++) {
                NETeamMemberInfoModel *user = safeTeam.users[i];
                if ([user.nimUser.user.accountId isEqualToString:[[IMKitClient instance] account]]) {
                    if (user.teamMember.memberRole == V2NIM_TEAM_MEMBER_ROLE_NORMAL) {
                        NSDictionary *json = getDictionaryFromJSONString(safeTeam.team.serverExtension ?: @"");
                        NSString *atValue = json[keyAllowAtAll];
                        if ([atValue isEqualToString:allowAtManagerValue]) {
                            weakSelf.isShowAtAll = NO;
                        }
                    }
                    selfIndex = i;
                }
            }
            if (selfIndex >= 0 && selfIndex < safeTeam.users.count) {
                NSMutableArray<NETeamMemberInfoModel *> *mutableUsers = [safeTeam.users mutableCopy] ?: [NSMutableArray array];
                [mutableUsers removeObjectAtIndex:selfIndex];
                safeTeam.users = mutableUsers;
            }
        }

        NETeamMemberInfoModel *owner = nil;
        NSMutableArray *managers = [NSMutableArray array];
        NSMutableArray *normals = [NSMutableArray array];
        for (NETeamMemberInfoModel *user in safeTeam.users) {
            if (user.teamMember.memberRole == V2NIM_TEAM_MEMBER_ROLE_OWNER) {
                owner = user;
            } else if (user.teamMember.memberRole == V2NIM_TEAM_MEMBER_ROLE_MANAGER) {
                [managers addObject:user];
            } else {
                [normals addObject:user];
            }
        }

        [managers sortUsingComparator:^NSComparisonResult(NETeamMemberInfoModel *m1, NETeamMemberInfoModel *m2) {
            return m1.teamMember.joinTime < m2.teamMember.joinTime ? NSOrderedAscending : NSOrderedDescending;
        }];
        [normals sortUsingComparator:^NSComparisonResult(NETeamMemberInfoModel *m1, NETeamMemberInfoModel *m2) {
            return m1.teamMember.joinTime < m2.teamMember.joinTime ? NSOrderedAscending : NSOrderedDescending;
        }];

        // 过滤数字人
        [managers filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NETeamMemberInfoModel *member, NSDictionary *bindings) {
            for (NETeamMemberInfoModel *aiMember in aiUserMembers) {
                if ([aiMember.nimUser.user.accountId isEqualToString:member.nimUser.user.accountId]) return NO;
            }
            return YES;
        }]];
        [normals filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NETeamMemberInfoModel *member, NSDictionary *bindings) {
            for (NETeamMemberInfoModel *aiMember in aiUserMembers) {
                if ([aiMember.nimUser.user.accountId isEqualToString:member.nimUser.user.accountId]) return NO;
            }
            return YES;
        }]];

        NSMutableArray *allUsers = [NSMutableArray arrayWithArray:aiUserMembers];
        if (owner) {
            [allUsers addObject:owner];
        }
        [allUsers addObjectsFromArray:managers];
        [allUsers addObjectsFromArray:normals];
        safeTeam.users = allUsers;

        weakSelf.teamInfo = safeTeam;
        [weakSelf.tableView reloadData];
    }];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return self.isShowAtAll ? 1 : 0;
    }
    return self.teamInfo.users.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [[UITableViewCell alloc] init];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (self.selectedBlock) {
            self.selectedBlock(indexPath.row, nil);
        }
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    if (indexPath.row >= self.teamInfo.users.count) {
        return;
    }
    if (self.selectedBlock) {
        self.selectedBlock(indexPath.row, self.teamInfo.users[indexPath.row]);
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)btnEvent:(UIButton *)button {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Lazy Properties

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    }
    return _tableView;
}

- (TeamMemberSelectVM *)viewModel {
    if (!_viewModel) {
        _viewModel = [[TeamMemberSelectVM alloc] init];
    }
    return _viewModel;
}

@end
