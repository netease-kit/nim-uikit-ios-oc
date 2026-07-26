// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "AIChatViewController.h"
#import "UIImage+Chat.h"
#import <NEChatKit/UIColor+NECommon.h>
#import "ChatCellConstantValue.h"
#import "ChatUIConfig.h"
#import "NEChatUIConstant.h"

@interface AIChatViewController ()
@property (nonatomic, strong) AIChatViewModel *viewModel;
@end

@implementation AIChatViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _viewModel = [[AIChatViewModel alloc] init];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self commonUI];
}

- (void)commonUI {
    self.view.backgroundColor = [UIColor clearColor];

    [self.view addSubview:self.titleView];
    [NSLayoutConstraint activateConstraints:@[
        [self.titleView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:6],
        [self.titleView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:chat_content_margin],
        [self.titleView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant:-chat_cell_margin],
        [self.titleView.heightAnchor constraintEqualToConstant:24],
    ]];

    [self.view addSubview:self.tableView];
    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.topAnchor constraintEqualToAnchor:self.titleView.bottomAnchor constant:chat_content_margin],
        [self.tableView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:chat_cell_margin],
        [self.tableView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant:-chat_cell_margin],
        [self.tableView.heightAnchor constraintEqualToConstant:216],
    ]];

    [self.tableView registerClass:[AIChatTableViewCell class] forCellReuseIdentifier:NSStringFromClass([AIChatTableViewCell class])];

    [self.view addSubview:self.loadDataView];
    [NSLayoutConstraint activateConstraints:@[
        [self.loadDataView.topAnchor constraintEqualToAnchor:self.tableView.topAnchor],
        [self.loadDataView.leftAnchor constraintEqualToAnchor:self.tableView.leftAnchor],
        [self.loadDataView.rightAnchor constraintEqualToAnchor:self.tableView.rightAnchor],
        [self.loadDataView.bottomAnchor constraintEqualToAnchor:self.tableView.bottomAnchor],
    ]];

    [self.view addSubview:self.loadDataFailedView];
    [NSLayoutConstraint activateConstraints:@[
        [self.loadDataFailedView.topAnchor constraintEqualToAnchor:self.tableView.topAnchor],
        [self.loadDataFailedView.leftAnchor constraintEqualToAnchor:self.tableView.leftAnchor],
        [self.loadDataFailedView.rightAnchor constraintEqualToAnchor:self.tableView.rightAnchor],
        [self.loadDataFailedView.bottomAnchor constraintEqualToAnchor:self.tableView.bottomAnchor],
    ]];
}

- (void)showLoadingView {
    self.tableView.hidden = YES;
    self.loadDataFailedView.hidden = YES;
    self.loadDataView.hidden = NO;
    [self.loadDataView play];
}

- (void)showFaildeView {
    self.tableView.hidden = YES;
    self.loadDataFailedView.hidden = NO;
    self.loadDataView.hidden = YES;
    [self.loadDataView stop];
}

- (void)showTableView {
    self.tableView.hidden = NO;
    [self.tableView reloadData];
    self.loadDataFailedView.hidden = YES;
    self.loadDataView.hidden = YES;
    [self.loadDataView stop];
}

- (void)loadData:(nullable NSArray *)messages {
    if ([ChatUIConfig shared].aiChatDidClick) {
        [ChatUIConfig shared].aiChatDidClick(self, messages);
        return;
    }
}

- (void)loadMoreData:(nullable NSArray *)messages {
    if (messages) {
        self.lastMessages = messages;
    }
    __weak typeof(self) weakSelf = self;
    [self.viewModel loadData:messages completion:^(NSError *error) {
        if (error) {
            [weakSelf showFaildeView];
        } else {
            [weakSelf showTableView];
        }
    }];
}

- (void)reloadData {
    if ([ChatUIConfig shared].aiChatReloadClick) {
        [ChatUIConfig shared].aiChatReloadClick(self, self.lastMessages);
        return;
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.viewModel.aiChatData.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 72;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= self.viewModel.aiChatData.count) {
        return [[UITableViewCell alloc] init];
    }
    AIChatCellModel *model = self.viewModel.aiChatData[indexPath.row];
    AIChatTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([AIChatTableViewCell class]) forIndexPath:indexPath];
    [cell setModel:model];
    cell.delegate = self;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= self.viewModel.aiChatData.count) return;
    NSString *text = self.viewModel.aiChatData[indexPath.row].contentTitle;
    if (text) {
        [self.delegate didClickMessageItem:text];
    }
}

#pragma mark - AIChatTableViewCellDelegate

- (void)didClickEditButton:(nullable NSString *)text {
    [self.delegate didClickEditButton:text];
}

#pragma mark - Lazy Load

- (UIView *)titleView {
    if (!_titleView) {
        _titleView = [[UIView alloc] init];
        _titleView.translatesAutoresizingMaskIntoConstraints = NO;

        self.titleIcon = [[UIImageView alloc] initWithImage:[UIImage ne_imageNamed:@"ai_icon_highlight"]];
        self.titleIcon.translatesAutoresizingMaskIntoConstraints = NO;
        [_titleView addSubview:self.titleIcon];
        [NSLayoutConstraint activateConstraints:@[
            [self.titleIcon.leftAnchor constraintEqualToAnchor:_titleView.leftAnchor],
            [self.titleIcon.centerYAnchor constraintEqualToAnchor:_titleView.centerYAnchor],
            [self.titleIcon.widthAnchor constraintEqualToConstant:24],
            [self.titleIcon.heightAnchor constraintEqualToConstant:24],
        ]];

        [_titleView addSubview:self.reloadButton];
        [NSLayoutConstraint activateConstraints:@[
            [self.reloadButton.centerYAnchor constraintEqualToAnchor:_titleView.centerYAnchor],
            [self.reloadButton.rightAnchor constraintEqualToAnchor:_titleView.rightAnchor],
            [self.reloadButton.widthAnchor constraintEqualToConstant:24],
            [self.reloadButton.heightAnchor constraintEqualToConstant:24],
        ]];

        UILabel *title = [[UILabel alloc] init];
        title.translatesAutoresizingMaskIntoConstraints = NO;
        title.text = chatLocalizable(@"ai_chat_title");
        [_titleView addSubview:title];
        [NSLayoutConstraint activateConstraints:@[
            [title.leftAnchor constraintEqualToAnchor:self.titleIcon.rightAnchor constant:4],
            [title.centerYAnchor constraintEqualToAnchor:_titleView.centerYAnchor],
            [title.rightAnchor constraintEqualToAnchor:self.reloadButton.leftAnchor constant:4],
            [title.heightAnchor constraintEqualToConstant:24],
        ]];
    }
    return _titleView;
}

- (ExpandButton *)reloadButton {
    if (!_reloadButton) {
        _reloadButton = [[ExpandButton alloc] init];
        _reloadButton.translatesAutoresizingMaskIntoConstraints = NO;
        [_reloadButton setImage:[UIImage ne_imageNamed:@"ai_reload"] forState:UIControlStateNormal];
        [_reloadButton addTarget:self action:@selector(reloadData) forControlEvents:UIControlEventTouchUpInside];
    }
    return _reloadButton;
}

- (NELottieAnimationView *)loadDataView {
    if (!_loadDataView) {
        _loadDataView = [[NELottieAnimationView alloc] initWithName:@"ai_chat_loading" bundle:chatBundle()];
        _loadDataView.translatesAutoresizingMaskIntoConstraints = NO;
        _loadDataView.loopMode = LottieLoopModeLoop;
        _loadDataView.contentMode = UIViewContentModeCenter;
    }
    return _loadDataView;
}

- (UIView *)loadDataFailedView {
    if (!_loadDataFailedView) {
        _loadDataFailedView = [[UIView alloc] init];
        _loadDataFailedView.translatesAutoresizingMaskIntoConstraints = NO;
        _loadDataFailedView.hidden = YES;

        UILabel *failedTips = [[UILabel alloc] init];
        failedTips.translatesAutoresizingMaskIntoConstraints = NO;
        failedTips.text = chatLocalizable(@"ai_chat_for_failure");
        failedTips.textColor = [UIColor ne_darkText];

        UIButton *failedReloadButton = [[UIButton alloc] init];
        failedReloadButton.translatesAutoresizingMaskIntoConstraints = NO;
        failedReloadButton.backgroundColor = [UIColor whiteColor];
        failedReloadButton.layer.cornerRadius = 8;
        failedReloadButton.layer.borderWidth = 1;
        failedReloadButton.layer.borderColor = [[UIColor ne_colorWithHexString:@"#000000"] colorWithAlphaComponent:0.1].CGColor;
        [failedReloadButton setTitle:chatLocalizable(@"ai_chat_click_retry") forState:UIControlStateNormal];
        [failedReloadButton setTitleColor:[UIColor ne_darkText] forState:UIControlStateNormal];
        failedReloadButton.titleLabel.font = [UIFont systemFontOfSize:14];
        [failedReloadButton addTarget:self action:@selector(reloadData) forControlEvents:UIControlEventTouchUpInside];

        [_loadDataFailedView addSubview:failedReloadButton];
        [NSLayoutConstraint activateConstraints:@[
            [failedReloadButton.centerXAnchor constraintEqualToAnchor:_loadDataFailedView.centerXAnchor],
            [failedReloadButton.centerYAnchor constraintEqualToAnchor:_loadDataFailedView.centerYAnchor],
            [failedReloadButton.heightAnchor constraintEqualToConstant:32],
        ]];

        [_loadDataFailedView addSubview:failedTips];
        [NSLayoutConstraint activateConstraints:@[
            [failedTips.centerXAnchor constraintEqualToAnchor:_loadDataFailedView.centerXAnchor],
            [failedTips.centerYAnchor constraintEqualToAnchor:failedReloadButton.centerYAnchor constant:-44],
            [failedTips.heightAnchor constraintEqualToConstant:24],
        ]];
    }
    return _loadDataFailedView;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.translatesAutoresizingMaskIntoConstraints = NO;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.showsVerticalScrollIndicator = NO;
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.estimatedRowHeight = 0;
        _tableView.estimatedSectionHeaderHeight = 0;
        _tableView.estimatedSectionFooterHeight = 0;
        if (@available(iOS 15.0, *)) {
            _tableView.sectionHeaderTopPadding = 0.0;
        }
    }
    return _tableView;
}

@end
