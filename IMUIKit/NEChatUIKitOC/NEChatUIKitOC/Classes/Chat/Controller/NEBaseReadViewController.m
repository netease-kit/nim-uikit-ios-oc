// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseReadViewController.h"
#import <NEChatKit/UIColor+NECommon.h>
#import <NEChatKit/NEChatKitOC.h>
#import <NEChatKit/NECoreIM2Constant.h>
#import <NIMSDK/NIMSDK.h>
#import "ChatNavigationView.h"
#import "NEChatUIConstant.h"
#import "UserBaseTableViewCell.h"

@interface NEBaseReadViewController ()
@property (nonatomic, strong) ReadViewModel *viewModel;
@property (nonatomic, strong) V2NIMMessage *message;
@property (nonatomic, copy) NSString *teamId;
@end

@implementation NEBaseReadViewController

- (instancetype)initWithMessage:(V2NIMMessage *)message teamId:(NSString *)teamId {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _message = message;
        _teamId = teamId;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        _message = [[V2NIMMessage alloc] init];
        _teamId = @"";
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.tabViewTopAnchor.constant = self.topConstant;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self commonUI];
    [self loadData];
}

- (void)commonUI {
    self.title = chatLocalizable(@"message_read");
    self.navigationView.moreButton.hidden = YES;

    [self.view addSubview:self.tabView];
    self.tabViewTopAnchor = [self.tabView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:self.topConstant];
    self.tabViewTopAnchor.active = YES;
    [NSLayoutConstraint activateConstraints:@[
        [self.tabView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tabView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tabView.heightAnchor constraintEqualToConstant:48],
    ]];

    [self.view addSubview:self.readTableView];
    [NSLayoutConstraint activateConstraints:@[
        [self.readTableView.topAnchor constraintEqualToAnchor:self.readButton.bottomAnchor constant:1],
        [self.readTableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.readTableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.readTableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];

    [self.view addSubview:self.unreadTableView];
    [NSLayoutConstraint activateConstraints:@[
        [self.unreadTableView.topAnchor constraintEqualToAnchor:self.readButton.bottomAnchor constant:1],
        [self.unreadTableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.unreadTableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.unreadTableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];

    self.emptyView.message = chatLocalizable(@"message_all_unread");
    [self.view addSubview:self.emptyView];
    [NSLayoutConstraint activateConstraints:@[
        [self.emptyView.topAnchor constraintEqualToAnchor:self.readButton.bottomAnchor constant:1],
        [self.emptyView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
        [self.emptyView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
        [self.emptyView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];
}

- (void)loadData {
    __weak typeof(self) weakSelf = self;
    [self.viewModel getTeamMessageReceiptDetail:self.message teamId:self.teamId completion:^(NSError * _Nullable error) {
        if (error) {
            NSError *err = (NSError *)error;
            if (err.code == protocolSendFailed) {
                [weakSelf.view ne_makeToast:commonLocalizable(@"network_error")];
            } else {
                [weakSelf.view ne_makeToast:err.localizedDescription];
            }
        } else {
            NSString *readTitle = [NSString stringWithFormat:@"%@(%ld)", chatLocalizable(@"read"), weakSelf.viewModel.readUsers.count];
            [weakSelf.readButton setTitle:readTitle forState:UIControlStateNormal];
            NSString *unreadTitle = [NSString stringWithFormat:@"%@(%ld)", chatLocalizable(@"unread"), weakSelf.viewModel.unReadUsers.count];
            [weakSelf.unreadButton setTitle:unreadTitle forState:UIControlStateNormal];
            [weakSelf.readTableView reloadData];
            weakSelf.emptyView.hidden = weakSelf.viewModel.readUsers.count > 0;
        }
    }];
}

- (void)readButtonEvent:(UIButton *)button {
    if (!self.readTableView.isHidden) return;
    self.bottonBottomLineLeftAnchor.constant = 0;
    [UIView animateWithDuration:0.5 animations:^{
        [self.view layoutIfNeeded];
    }];
    [self.readTableView reloadData];
    self.readTableView.hidden = NO;
    self.unreadTableView.hidden = YES;
    self.emptyView.hidden = self.viewModel.readUsers.count > 0;
}

- (void)unreadButtonEvent:(UIButton *)button {
    if (!self.unreadTableView.isHidden) return;
    self.bottonBottomLineLeftAnchor.constant = button.frame.size.width;
    [UIView animateWithDuration:0.5 animations:^{
        [self.view layoutIfNeeded];
    }];
    [self.unreadTableView reloadData];
    self.unreadTableView.hidden = NO;
    self.readTableView.hidden = YES;
    self.emptyView.hidden = self.viewModel.unReadUsers.count > 0;
}

#pragma mark - UITableViewDataSource, UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.readTableView) {
        return self.viewModel.readUsers.count;
    } else {
        return self.viewModel.unReadUsers.count;
    }
}

- (UITableViewCell *)cellSetModel:(UITableView *)tableView cell:(UserBaseTableViewCell *)cell indexPath:(NSIndexPath *)indexPath {
    if (tableView == self.readTableView) {
        id model = self.viewModel.readUsers[indexPath.row];
        [cell setModel:model];
    } else {
        id model = self.viewModel.unReadUsers[indexPath.row];
        [cell setModel:model];
    }
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UserBaseTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([UserBaseTableViewCell class]) forIndexPath:indexPath];
    return [self cellSetModel:tableView cell:cell indexPath:indexPath];
}

#pragma mark - Lazy Properties

- (ReadViewModel *)viewModel {
    if (!_viewModel) {
        _viewModel = [[ReadViewModel alloc] init];
    }
    return _viewModel;
}

- (UIButton *)readButton {
    if (!_readButton) {
        _readButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _readButton.titleLabel.font = [UIFont systemFontOfSize:14];
        [_readButton setTitle:chatLocalizable(@"read") forState:UIControlStateNormal];
        [_readButton setTitleColor:UIColor.ne_darkText forState:UIControlStateNormal];
        _readButton.translatesAutoresizingMaskIntoConstraints = NO;
        [_readButton addTarget:self action:@selector(readButtonEvent:) forControlEvents:UIControlEventTouchUpInside];
        _readButton.accessibilityIdentifier = @"id.tabHasRead";
    }
    return _readButton;
}

- (UIButton *)unreadButton {
    if (!_unreadButton) {
        _unreadButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _unreadButton.titleLabel.font = [UIFont systemFontOfSize:14];
        [_unreadButton setTitle:chatLocalizable(@"unread") forState:UIControlStateNormal];
        [_unreadButton setTitleColor:UIColor.ne_darkText forState:UIControlStateNormal];
        _unreadButton.translatesAutoresizingMaskIntoConstraints = NO;
        [_unreadButton addTarget:self action:@selector(unreadButtonEvent:) forControlEvents:UIControlEventTouchUpInside];
        _unreadButton.accessibilityIdentifier = @"id.tabUnRead";
    }
    return _unreadButton;
}

- (UIView *)bottonBottomLine {
    if (!_bottonBottomLine) {
        _bottonBottomLine = [[UIView alloc] init];
        _bottonBottomLine.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _bottonBottomLine;
}

- (UIView *)tabView {
    if (!_tabView) {
        _tabView = [[UIView alloc] init];
        _tabView.translatesAutoresizingMaskIntoConstraints = NO;
        _tabView.backgroundColor = UIColor.whiteColor;

        [_tabView addSubview:self.readButton];
        [NSLayoutConstraint activateConstraints:@[
            [self.readButton.topAnchor constraintEqualToAnchor:_tabView.topAnchor],
            [self.readButton.leadingAnchor constraintEqualToAnchor:_tabView.leadingAnchor],
            [self.readButton.heightAnchor constraintEqualToConstant:48],
            [self.readButton.widthAnchor constraintEqualToConstant:kScreenWidth() / 2.0],
        ]];

        [_tabView addSubview:self.unreadButton];
        [NSLayoutConstraint activateConstraints:@[
            [self.unreadButton.topAnchor constraintEqualToAnchor:self.readButton.topAnchor],
            [self.unreadButton.leadingAnchor constraintEqualToAnchor:self.readButton.trailingAnchor],
            [self.unreadButton.trailingAnchor constraintEqualToAnchor:_tabView.trailingAnchor],
            [self.unreadButton.heightAnchor constraintEqualToConstant:48],
        ]];

        [_tabView addSubview:self.bottonBottomLine];
        self.bottonBottomLineLeftAnchor = [self.bottonBottomLine.leadingAnchor constraintEqualToAnchor:_tabView.leadingAnchor];
        [NSLayoutConstraint activateConstraints:@[
            [self.bottonBottomLine.topAnchor constraintEqualToAnchor:self.readButton.bottomAnchor constant:0],
            [self.bottonBottomLine.heightAnchor constraintEqualToConstant:1],
            [self.bottonBottomLine.widthAnchor constraintEqualToAnchor:self.readButton.widthAnchor],
            self.bottonBottomLineLeftAnchor,
        ]];
    }
    return _tabView;
}

- (UITableView *)readTableView {
    if (!_readTableView) {
        _readTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _readTableView.delegate = self;
        _readTableView.dataSource = self;
        _readTableView.sectionHeaderHeight = 0;
        _readTableView.sectionFooterHeight = 0;
        _readTableView.translatesAutoresizingMaskIntoConstraints = NO;
        _readTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _readTableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
        _readTableView.estimatedRowHeight = 0;
        _readTableView.estimatedSectionHeaderHeight = 0;
        _readTableView.estimatedSectionFooterHeight = 0;
        if (@available(iOS 15.0, *)) {
            _readTableView.sectionHeaderTopPadding = 0.0;
        }
        [_readTableView registerClass:[UserBaseTableViewCell class]
               forCellReuseIdentifier:NSStringFromClass([UserBaseTableViewCell class])];
    }
    return _readTableView;
}

- (UITableView *)unreadTableView {
    if (!_unreadTableView) {
        _unreadTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _unreadTableView.delegate = self;
        _unreadTableView.dataSource = self;
        _unreadTableView.sectionHeaderHeight = 0;
        _unreadTableView.sectionFooterHeight = 0;
        _unreadTableView.translatesAutoresizingMaskIntoConstraints = NO;
        _unreadTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _unreadTableView.hidden = YES;
        _unreadTableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
        _unreadTableView.estimatedRowHeight = 0;
        _unreadTableView.estimatedSectionHeaderHeight = 0;
        _unreadTableView.estimatedSectionFooterHeight = 0;
        if (@available(iOS 15.0, *)) {
            _unreadTableView.sectionHeaderTopPadding = 0.0;
        }
        [_unreadTableView registerClass:[UserBaseTableViewCell class]
                 forCellReuseIdentifier:NSStringFromClass([UserBaseTableViewCell class])];
    }
    return _unreadTableView;
}

@end
