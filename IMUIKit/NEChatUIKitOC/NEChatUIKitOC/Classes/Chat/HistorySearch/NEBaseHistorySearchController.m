// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "NEBaseHistorySearchController.h"
#import "UIImage+Chat.h"
#import <MJRefresh/MJRefresh.h>
#import <NEChatKitOC/NEChatKitOC.h>
#import <NEChatKitOC/NECommonLoader.h>
#import <NECommonUIKitOC/NECommonUIKitOC.h>
#import <NEChatKitOC/NECoreIM2Constant.h>
#import <NEChatKitOC/NEALog.h>
#import <NEChatKitOC/Router.h>
#import <NEChatKitOC/NERouterUrl.h>
#import <NIMSDK/NIMSDK.h>
#import "NEChatUIConstant.h"
#import "TeamHistoryMessageViewModel.h"
#import <NEChatKitOC/UIColor+NECommon.h>
#import "NEBaseHistoryMediaResultController.h"
#import "NEHistoryDatePickerViewController.h"
#import "NERefreshHasNoMoreView.h"
#import "ChatViewController.h"
#import "ChatNavigationView.h"
#import "ChatMessageHelper.h"
#import "NEChatUIKitClient.h"
#import "MessageContentModel.h"
#import "MessageTipsModel.h"
#import "OperationCell.h"
#import <NEChatKitOC/NEChatDetectNetworkTool.h>
#import "NEBaseChatMessageTipCell.h"
#import "NEChatBaseCell.h"

#pragma mark - NEHistorySearchContainerView

@implementation NEHistorySearchContainerView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hitView = [super hitTest:point withEvent:event];
    if (self.searchTextField && self.searchTextField.isFirstResponder && hitView != self.searchTextField) {
        [self.searchTextField resignFirstResponder];
    }
    return hitView;
}

@end

#pragma mark - NEBaseHistorySearchController

@implementation NEBaseHistorySearchController

- (instancetype)initWithConversationId:(NSString *)conversationId {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _tag = @"NEBaseHistoryMessageController";
        _conversationId = conversationId;
        _viewModel = [[TeamHistoryMessageViewModel alloc] initWithConversationId:conversationId];
        _viewModel.themeColor = self.themeColor;
        _layout = [[UICollectionViewFlowLayout alloc] init];
        _layout.itemSize = CGSizeMake(84, 102);
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:_layout];
        _searchStr = @"";
        _isSearching = NO;
        _cellRegisterDic = [NSMutableDictionary dictionary];
        _themeColor = UIColor.ne_normalTheme;
        _messageSearchExParams = [[V2NIMMessageSearchExParams alloc] init];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _tag = @"NEBaseHistoryMessageController";
        _viewModel = [[TeamHistoryMessageViewModel alloc] init];
        _viewModel.themeColor = self.themeColor;
        _layout = [[UICollectionViewFlowLayout alloc] init];
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:_layout];
        _searchStr = @"";
        _isSearching = NO;
        _cellRegisterDic = [NSMutableDictionary dictionary];
        _themeColor = UIColor.ne_normalTheme;
        _messageSearchExParams = [[V2NIMMessageSearchExParams alloc] init];
    }
    return self;
}

- (void)loadView {
    NEHistorySearchContainerView *containerView = [[NEHistorySearchContainerView alloc] init];
    containerView.backgroundColor = UIColor.whiteColor;
    self.view = containerView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupSubviews];
    [self initialConfig];
    self.viewModel.delegate = self;

    if ([self.view isKindOfClass:[NEHistorySearchContainerView class]]) {
        ((NEHistorySearchContainerView *)self.view).searchTextField = self.searchTextField;
    }
}

#pragma mark - Lazy

- (UILabel *)tipLable {
    if (!_tipLable) {
        _tipLable = [[UILabel alloc] init];
        _tipLable.translatesAutoresizingMaskIntoConstraints = NO;
        _tipLable.font = [UIFont systemFontOfSize:14];
        _tipLable.textColor = UIColor.ne_emptyTitleColor;
        _tipLable.text = chatLocalizable(@"quick_search_tips");
    }
    return _tipLable;
}

- (SearchTextField *)searchTextField {
    if (!_searchTextField) {
        _searchTextField = [[SearchTextField alloc] init];
        UIImageView *leftImageView = [[UIImageView alloc] initWithImage:[coreLoader() loadImage:@"textField_search_icon"]];
        _searchTextField.contentMode = UIViewContentModeCenter;
        _searchTextField.leftView = leftImageView;
        _searchTextField.leftViewMode = UITextFieldViewModeAlways;
        _searchTextField.placeholder = chatLocalizable(@"search");
        _searchTextField.font = [UIFont systemFontOfSize:14];
        _searchTextField.textColor = UIColor.ne_greyText;
        _searchTextField.translatesAutoresizingMaskIntoConstraints = NO;
        _searchTextField.layer.cornerRadius = 8;
        _searchTextField.backgroundColor = [UIColor ne_colorWithHexString:@"0xF2F4F5"];
        _searchTextField.clearButtonMode = UITextFieldViewModeAlways;
        _searchTextField.returnKeyType = UIReturnKeySearch;
        _searchTextField.delegate = self;
        [_searchTextField addTarget:self action:@selector(searchTextChanged) forControlEvents:UIControlEventEditingChanged];

        UIButton *clearButton = [_searchTextField valueForKey:@"_clearButton"];
        if ([clearButton isKindOfClass:[UIButton class]]) {
            clearButton.accessibilityIdentifier = @"id.clear";
        }
        _searchTextField.accessibilityIdentifier = @"id.search";
    }
    return _searchTextField;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.translatesAutoresizingMaskIntoConstraints = NO;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.scrollsToTop = NO;
        _tableView.hidden = YES;
        _tableView.delegate = self;
        _tableView.dataSource = self;
        [_tableView registerClass:[NEBaseChatMessageCell class] forCellReuseIdentifier:NSStringFromClass([NEBaseChatMessageCell class])];
        _tableView.rowHeight = 65;
        _tableView.backgroundColor = UIColor.whiteColor;
        _tableView.sectionHeaderHeight = 30;
        _tableView.sectionFooterHeight = 0;
        _tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;

        MJRefreshNormalHeader *header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(refreshData)];
        header.automaticallyChangeAlpha = YES;
        _tableView.mj_header = header;

        MJRefreshAutoNormalFooter *footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadMoreData)];
        _tableView.mj_footer = footer;

        _tableView.estimatedRowHeight = 0;
        _tableView.estimatedSectionHeaderHeight = 0;
        _tableView.estimatedSectionFooterHeight = 0;

        _tableView.delaysContentTouches = NO;
        _tableView.canCancelContentTouches = YES;

        if (@available(iOS 15.0, *)) {
            _tableView.sectionHeaderTopPadding = 0.0;
        }
    }
    return _tableView;
}

#pragma mark - Setup

- (void)setupSubviews {
    self.view.backgroundColor = UIColor.whiteColor;
    self.navigationView.moreButton.hidden = YES;
    [self.view addSubview:self.searchTextField];
    [self.view addSubview:self.tipLable];
    [self.view addSubview:self.collectionView];
    [self.view addSubview:self.tableView];
    [self.view addSubview:self.emptyView];

    [NSLayoutConstraint activateConstraints:@[
        [self.tipLable.centerXAnchor constraintEqualToAnchor:self.collectionView.centerXAnchor],
        [self.tipLable.topAnchor constraintEqualToAnchor:self.searchTextField.bottomAnchor constant:48],
    ]];

    self.layout.minimumLineSpacing = 0;
    self.layout.minimumInteritemSpacing = 0;
    self.layout.scrollDirection = UICollectionViewScrollDirectionVertical;

    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.backgroundColor = UIColor.whiteColor;
    self.collectionView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;

    [self.collectionView registerClass:[OperationCell class] forCellWithReuseIdentifier:NSStringFromClass([OperationCell class])];

    [NSLayoutConstraint activateConstraints:@[
        [self.collectionView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant:-26],
        [self.collectionView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:26],
        [self.collectionView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [self.collectionView.topAnchor constraintEqualToAnchor:self.tipLable.bottomAnchor constant:24],
    ]];

    self.tableViewTopAnchor = [self.tableView.topAnchor constraintEqualToAnchor:self.navigationView.bottomAnchor constant:50];
    self.tableViewTopAnchor.active = YES;
    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor],
        [self.tableView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];

    [self.tableView registerClass:[NEBaseChatMessageCell class] forCellReuseIdentifier:NSStringFromClass([NEBaseChatMessageCell class])];

    [self.cellRegisterDic enumerateKeysAndObjectsUsingBlock:^(NSString *key, id cellValue, BOOL *stop) {
        Class cellClass = Nil;
        if ([cellValue isKindOfClass:[NSString class]]) {
            cellClass = NSClassFromString((NSString *)cellValue);
        } else {
            cellClass = cellValue;
        }
        if (cellClass) {
            [self.tableView registerClass:cellClass forCellReuseIdentifier:key];
        }
    }];

    self.emptyView.message = chatLocalizable(@"no_search_results");
    self.emptyView.backgroundColor = UIColor.whiteColor;
    [NSLayoutConstraint activateConstraints:@[
        [self.emptyView.rightAnchor constraintEqualToAnchor:self.collectionView.rightAnchor],
        [self.emptyView.leftAnchor constraintEqualToAnchor:self.collectionView.leftAnchor],
        [self.emptyView.bottomAnchor constraintEqualToAnchor:self.collectionView.bottomAnchor],
        [self.emptyView.topAnchor constraintEqualToAnchor:self.searchTextField.bottomAnchor],
    ]];
}

- (void)initialConfig {
    self.title = chatLocalizable(@"historical_record");
}

#pragma mark - Data

- (void)refreshData {
    [self loadData:nil firstLoad:YES];
}

- (void)loadMoreData {
    [self loadData:nil firstLoad:NO];
}

- (void)loadData:(nullable V2NIMMessageSearchExParams *)params firstLoad:(BOOL)firstLoad {
    if (self.isSearching) return;

    self.isSearching = YES;
    V2NIMMessageSearchExParams *searchParams = params ?: self.messageSearchExParams;
    searchParams.conversationId = self.conversationId;

    if (firstLoad && params != nil) {
        [self.view makeToastActivity:YXToastPositionCenter];
    }

    __weak typeof(self) weakSelf = self;
    [self.viewModel searchHistoryMessages:searchParams firstSearch:firstLoad completion:^(NSError * _Nullable error, NSInteger messageCount, BOOL hasMore) {
        weakSelf.isSearching = NO;
        [weakSelf.tableView.mj_header endRefreshing];
        [weakSelf.tableView.mj_footer endRefreshing];

        if (error) {
            NSError *err = error;
            [weakSelf.view ne_hideToastActivity];
            if (err.code == protocolSendFailed) {
                [weakSelf showToast:commonLocalizable(@"network_error")];
            } else {
                [weakSelf showToast:err.localizedDescription];
                [NEALog errorLog:[ModuleName stringByAppendingString:NSStringFromClass([NEBaseHistorySearchController class])] desc:[NSString stringWithFormat:@"%s failed, error: %@", __FUNCTION__, err.localizedDescription]];
            }
            return;
        }

        if (hasMore) {
            [weakSelf addBottomLoadMore];
        } else {
            [weakSelf removeBottomLoadMore];
        }

        if (firstLoad) {
            [weakSelf.view ne_hideToastActivity];
        }

        if (searchParams.keywordList.count > 0) {
            weakSelf.searchTextField.hidden = NO;
        } else {
            weakSelf.searchTextField.hidden = YES;
        }

        weakSelf.emptyView.hidden = weakSelf.viewModel.messages.count > 0;
        weakSelf.tableView.hidden = weakSelf.viewModel.messages.count == 0;
        [weakSelf.tableView reloadData];
        if (firstLoad) {
            weakSelf.tableView.contentOffset = CGPointZero;
        }
    }];
}

- (void)loadData:(nullable V2NIMMessageSearchExParams *)params autoSearch:(BOOL)autoSearch {
    [self loadData:params firstLoad:autoSearch];
}

- (void)addBottomLoadMore {
    MJRefreshAutoNormalFooter *footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadMoreData)];
    footer.triggerAutomaticallyRefreshPercent = -20;
    self.tableView.mj_footer = footer;
}

- (void)removeBottomLoadMore {
    [self.tableView.mj_footer endRefreshingWithNoMoreData];
    self.tableView.mj_footer = nil;

    NERefreshHasNoMoreView *view = [[NERefreshHasNoMoreView alloc] initWithFrame:CGRectMake(0, 0, (NSInteger)CGRectGetWidth(self.tableView.bounds), 20)];
    self.tableView.tableFooterView = view;
}

#pragma mark - Search Actions

- (void)searchTeamMemberAction {
    if (!self.conversationId) return;
    NSString *teamId = [V2NIMConversationIdUtil conversationTargetId:self.conversationId];
    if (!teamId) return;

    __weak typeof(self) weakSelf = self;
    NESelectTeamMemberBlock callback = ^(NSArray *datas) {
        id firstData = datas.firstObject;
        NSString *accountId = nil;
        if ([firstData respondsToSelector:@selector(nimUser)]) {
            id nimUser = [firstData nimUser];
            if ([nimUser respondsToSelector:@selector(user)]) {
                id user = [nimUser user];
                if ([user respondsToSelector:@selector(accountId)]) {
                    accountId = [user accountId];
                }
            }
        }
        if (accountId) {
            weakSelf.title = chatLocalizable(@"search_message_by_member");
            weakSelf.tableViewTopAnchor.constant = 0;
            weakSelf.tableView.hidden = NO;

            V2NIMMessageSearchExParams *params = [[V2NIMMessageSearchExParams alloc] init];
            params.senderAccountIds = @[accountId];
            weakSelf.messageSearchExParams = params;
            [weakSelf loadData:params firstLoad:YES];
        }
    };

    [Router.shared use:TeamMemberSelectViewRouter
            parameters:@{
                @"nav": self.navigationController ?: [NSNull null],
                @"teamId": teamId,
                @"navTitle": chatLocalizable(@"group_memmber"),
                @"memberLimit": @1,
                @"showAllMembers": @YES,
                @"selectMemberBlock": callback,
            }
               closure:nil];
}

- (void)searchImageAction {
    NEBaseHistoryMediaResultController *mediaSearchVC = [[NEBaseHistoryMediaResultController alloc] init];
    [self.navigationController pushViewController:mediaSearchVC animated:YES];
}

- (void)searchVideoAction {
    NEBaseHistoryMediaResultController *mediaSearchVC = [[NEBaseHistoryMediaResultController alloc] init];
    mediaSearchVC.searchType = MessageTypeVideo;
    [self.navigationController pushViewController:mediaSearchVC animated:YES];
}

- (void)searchDateAction {
    NEHistoryDatePickerViewController *datePickerVC = [[NEHistoryDatePickerViewController alloc] init];
    datePickerVC.delegate = self;
    [self.navigationController pushViewController:datePickerVC animated:YES];
}

- (void)searchFileAction {
    NEBaseHistoryMediaResultController *mediaSearchVC = [[NEBaseHistoryMediaResultController alloc] init];
    mediaSearchVC.searchType = MessageTypeFile;
    [self.navigationController pushViewController:mediaSearchVC animated:YES];
}

- (void)routerToMessage:(nullable V2NIMMessage *)message {
    NSString *conversationId = message.conversationId ?: ChatRepo.conversationId;
    V2NIMConversationType conversationType = [V2NIMConversationIdUtil conversationType:conversationId];

    NSMutableArray *newMsgs = [NSMutableArray array];
    for (UIViewController *vc in self.navigationController.viewControllers) {
        if ([vc isKindOfClass:[ChatViewController class]]) {
            ChatViewController *chatVC = (ChatViewController *)vc;
            newMsgs = [chatVC.onReceiveNewMsgs mutableCopy];
            break;
        }
    }

    if (conversationType == V2NIM_CONVERSATION_TYPE_P2P) {
        [Router.shared use:PushP2pChatVCRouter
                parameters:@{
                    @"nav": self.navigationController ?: [NSNull null],
                    @"conversationId": conversationId ?: [NSNull null],
                    @"anchor": message ?: [NSNull null],
                    @"onReceiveNewMsgs": newMsgs,
                    @"animated": @NO,
                }
                   closure:nil];
        for (UIViewController *vc in self.navigationController.viewControllers) {
            if ([vc isKindOfClass:[ChatViewController class]]) {
                [((ChatViewController *)vc).onReceiveNewMsgs removeAllObjects];
                break;
            }
        }
    } else if (conversationType == V2NIM_CONVERSATION_TYPE_TEAM) {
        [Router.shared use:PushTeamChatVCRouter
                parameters:@{
                    @"nav": self.navigationController ?: [NSNull null],
                    @"conversationId": conversationId ?: [NSNull null],
                    @"anchor": message ?: [NSNull null],
                    @"onReceiveNewMsgs": newMsgs,
                    @"animated": @NO,
                }
                   closure:nil];
        for (UIViewController *vc in self.navigationController.viewControllers) {
            if ([vc isKindOfClass:[ChatViewController class]]) {
                [((ChatViewController *)vc).onReceiveNewMsgs removeAllObjects];
                break;
            }
        }
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    NSString *searchText = self.searchTextField.text;
    if (!searchText) return YES;

    if (searchText.length <= 0) {
        [self.viewModel.messages removeAllObjects];
        self.emptyView.hidden = YES;
        self.tableView.hidden = YES;
        self.tipLable.hidden = NO;
        self.collectionView.hidden = NO;
        [self.collectionView reloadData];
        return YES;
    }

    self.searchStr = searchText;
    V2NIMMessageSearchExParams *params = [[V2NIMMessageSearchExParams alloc] init];
    params.keywordList = @[searchText];
    self.messageSearchExParams = params;
    [self loadData:params firstLoad:YES];
    return YES;
}

- (void)searchTextChanged {
    if (self.searchTextField.markedTextRange == nil) {
        if (self.searchTextField.text.length == 0) {
            [self.viewModel.messages removeAllObjects];
            self.emptyView.hidden = YES;
            self.tableView.hidden = YES;
            self.tipLable.hidden = NO;
            self.collectionView.hidden = NO;
            [self.collectionView reloadData];
        }
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (self.searchTextField.isFirstResponder) {
        [self.searchTextField resignFirstResponder];
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithOtherGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

#pragma mark - UICollectionViewDataSource & UICollectionViewDelegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return (NSInteger)self.viewModel.operationTypes.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= (NSInteger)self.viewModel.operationTypes.count) {
        return [[UICollectionViewCell alloc] init];
    }
    id model = self.viewModel.operationTypes[indexPath.row];
    OperationCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([OperationCell class]) forIndexPath:indexPath];
    cell.model = model;
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (IMKitConfigCenter.shared.enableCloudMessageSearch) {
        if ([[NEChatDetectNetworkTool shareInstance] isNetworkReachability] == NO) {
            [self showToast:commonLocalizable(@"network_error")];
            return;
        }
    }

    OperationItem *model = (OperationItem *)self.viewModel.operationTypes[indexPath.row];
    OperationType type = model.type;

    switch (type) {
        case OperationTypeSearchTeamMember:
            [self searchTeamMemberAction];
            break;
        case OperationTypeSearchImage:
            [self searchImageAction];
            break;
        case OperationTypeSearchVideo:
            [self searchVideoAction];
            break;
        case OperationTypeSearchDate:
            [self searchDateAction];
            break;
        case OperationTypeSearchFile:
            [self searchFileAction];
            break;
        default:
            break;
    }
}

#pragma mark - NEHistoryDatePickerViewControllerDelegate

- (void)datePickerDidSelectDate:(int64_t)timestamp {
    V2NIMMessageListOption *opt = [[V2NIMMessageListOption alloc] init];
    opt.conversationId = ChatRepo.conversationId;
    opt.limit = 1;
    opt.direction = V2NIM_QUERY_DIRECTION_ASC;
    opt.beginTime = timestamp;

    __weak typeof(self) weakSelf = self;
    [ChatRepo.shared getMessageListWithOption:opt completion:^(NSArray<V2NIMMessage *> * _Nullable messages, NSError * _Nullable error) {
        if (messages.firstObject) {
            [weakSelf routerToMessage:messages.firstObject];
        } else {
            [weakSelf routerToMessage:nil];
        }
    }];
}

#pragma mark - UITableViewDataSource & UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)self.viewModel.messages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= (NSInteger)self.viewModel.messages.count) {
        return [[NEBaseChatMessageCell alloc] init];
    }

    id model = self.viewModel.messages[indexPath.row];
    BOOL inMultiForward = NO;
    if ([model respondsToSelector:@selector(inMultiForward)]) {
        inMultiForward = [[model valueForKey:@"inMultiForward"] boolValue];
    }
    if (!inMultiForward) {
        [model setValue:@YES forKey:@"inMultiForward"];
    }
    [model setValue:@NO forKey:@"isPined"];

    NSString *reuseId = @"";
    MessageType msgType = (MessageType)[[model valueForKey:@"type"] integerValue];
    NSString *key = [NSString stringWithFormat:@"%ld", (long)msgType];

    if (msgType == MessageTypeCustom) {
        NSInteger customType = [[model valueForKey:@"customType"] integerValue];
        if (customType == customMultiForwardType) {
            reuseId = [NSString stringWithFormat:@"%ld", (long)MessageTypeMultiForward];
        } else if (customType == customRichTextType) {
            reuseId = [NSString stringWithFormat:@"%ld", (long)MessageTypeRichText];
        } else if ([NEChatUIKitClient.instance getRegisterCustomCell][[NSString stringWithFormat:@"%ld", (long)customType]] != nil) {
            reuseId = [NSString stringWithFormat:@"%ld", (long)customType];
        } else {
            reuseId = NSStringFromClass([NEBaseChatMessageCell class]);
        }
    } else if (msgType == MessageTypeNotification || msgType == MessageTypeTip) {
        reuseId = [NSString stringWithFormat:@"%ld", (long)MessageTypeTime];
    } else if (self.cellRegisterDic[key] != nil) {
        reuseId = key;
    } else {
        reuseId = NSStringFromClass([NEBaseChatMessageCell class]);
    }

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseId forIndexPath:indexPath];

    if ([cell isKindOfClass:[NEBaseChatMessageTipCell class]] && [model isKindOfClass:[MessageTipsModel class]]) {
        [(NEBaseChatMessageTipCell *)cell setModel:(MessageTipsModel *)model];
        return cell;
    } else if ([cell isKindOfClass:[NEBaseChatMessageCell class]] && [model isKindOfClass:[MessageContentModel class]]) {
        NEBaseChatMessageCell *msgCell = (NEBaseChatMessageCell *)cell;
        MessageContentModel *contentModel = (MessageContentModel *)model;
        msgCell.singleLeft = YES;
        [msgCell setModel:contentModel isSend:NO];
        [msgCell setSelect:contentModel enableSelect:NO];
        msgCell.delegate = self;

        // 禁用 bubble tap gesture，改由 didSelectRowAt 处理
        for (UIGestureRecognizer *gesture in msgCell.bubbleImageLeft.gestureRecognizers) {
            if ([gesture isKindOfClass:[UITapGestureRecognizer class]]) {
                gesture.enabled = NO;
            }
        }
        for (UIGestureRecognizer *gesture in msgCell.bubbleImageRight.gestureRecognizers) {
            if ([gesture isKindOfClass:[UITapGestureRecognizer class]]) {
                gesture.enabled = NO;
            }
        }
        msgCell.bubbleImageLeft.userInteractionEnabled = NO;
        msgCell.bubbleImageRight.userInteractionEnabled = NO;
        return msgCell;
    } else if ([cell isKindOfClass:[NEChatBaseCell class]] && [model isKindOfClass:[MessageContentModel class]]) {
        [(NEChatBaseCell *)cell setModel:(MessageContentModel *)model isSend:NO];
        return cell;
    }

    return [[NEBaseChatMessageCell alloc] init];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= (NSInteger)self.viewModel.messages.count) return 0;
    id model = self.viewModel.messages[indexPath.row];
    CGFloat height = 0;
    if ([model respondsToSelector:@selector(cellHeight)]) {
        height = [[model valueForKey:@"cellHeight"] floatValue];
    }
    return height - chat_content_margin;
}

- (nullable NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.searchTextField resignFirstResponder];
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    id cellModel = self.viewModel.messages[indexPath.row];
    V2NIMMessage *message = nil;
    if ([cellModel respondsToSelector:@selector(message)]) {
        message = [cellModel message];
    }
    if (message) {
        [self routerToMessage:message];
    }
}

#pragma mark - ChatBaseCellDelegate

- (void)didTapAvatarView:(UITableViewCell *)cell model:(MessageContentModel *)model {}
- (void)didLongPressAvatar:(UITableViewCell *)cell model:(MessageContentModel *)model {}

- (void)didTapMessageView:(UITableViewCell *)cell model:(MessageContentModel *)model replyModel:(id)replyModel {
    if (!model.message) return;
    [self.searchTextField resignFirstResponder];
    [self routerToMessage:model.message];
}

- (void)didLongPressMessageView:(UITableViewCell *)cell model:(MessageContentModel *)model {}
- (void)didTapResendView:(UITableViewCell *)cell model:(MessageContentModel *)model {}
- (void)didTapReeditButton:(UITableViewCell *)cell model:(MessageContentModel *)model {}
- (void)didTapReadView:(UITableViewCell *)cell model:(MessageContentModel *)model {}
- (void)didTapSelectButton:(UITableViewCell *)cell model:(MessageContentModel *)model {}

#pragma mark - ChatViewModelDelegate

- (void)sending:(V2NIMMessage *)message index:(NSIndexPath *)index {}
- (void)sendSuccess:(V2NIMMessage *)message index:(NSIndexPath *)index {}
- (void)onResendSuccess:(NSIndexPath *)fromIndex toIndexPath:(NSIndexPath *)toIndexPath {}
- (void)onRecvMessages:(NSArray<V2NIMMessage *> *)messages indexs:(NSArray<NSIndexPath *> *)indexs {}
- (void)onLoadMoreWithMessage:(NSArray<NSIndexPath *> *)indexs {}
- (void)onModefiedMessage:(NSIndexPath *)index {}
- (void)onDeleteMessage:(NSArray<V2NIMMessage *> *)messages deleteIndexs:(NSArray<NSIndexPath *> *)deleteIndexs reloadIndex:(NSArray<NSIndexPath *> *)reloadIndex {}

- (void)onRevokeMessage:(V2NIMMessage *)message atIndexs:(NSArray<NSIndexPath *> *)atIndexs {
    [self.tableView deleteData:atIndexs];
    self.emptyView.hidden = self.viewModel.messages.count > 0;
    self.tableView.hidden = self.viewModel.messages.count == 0;
}

- (void)onMessageStatusChange:(V2NIMMessage *)message atIndexs:(NSArray<NSIndexPath *> *)atIndexs {}
- (void)remoteUserEditing {}
- (void)remoteUserEndEditing {}
- (void)remoteUserOnlineChanged {}

- (void)tableViewReload {
    [self.tableView reloadData];
}

- (void)setTopValueWithName:(NSString *)name content:(NSString *)content url:(NSString *)url isVideo:(BOOL)isVideo hideClose:(BOOL)hideClose {}
- (void)updateTopName:(NSString *)name {}

@end
