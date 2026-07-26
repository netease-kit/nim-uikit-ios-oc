// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "FunHistoryMessageController.h"
#import "UIImage+Chat.h"
#import <NEChatKit/NECommonLoader.h>
#import <NEChatKit/UIColor+NECommon.h>
#import <NECommonUIKitOC/UIView+YXToast.h>
#import "FunSearchMessageOperationCell.h"
#import "FunHistoryMessageMemberController.h"
#import "FunHistoryMediaResultController.h"
#import "NEHistoryDatePickerViewController.h"
#import "ChatMessageHelper.h"
#import "FunChatUIColor.h"

static NSString * const NEFunTeamMemberSelectViewRouter = @"imkit://team/member.select.page";
typedef void (^NEFunSelectTeamMemberBlock)(NSArray<NETeamMemberInfoModel *> *members);

@implementation FunHistoryMessageController

- (instancetype)initWithConversationId:(NSString *)conversationId {
    self = [super initWithConversationId:conversationId];
    if (self) {
        self.viewModel.themeColor = [UIColor ne_funTheme];
        self.layout.itemSize = CGSizeMake(90, 48);
        self.tag = @"FunTeamHistoryMessageController";
        self.cellRegisterDic = [ChatMessageHelper getChatCellRegisterDicWithIsFun:YES];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor funChatBackgroundColor];
    self.navigationController.navigationBarHidden = YES;
    self.navigationView.hidden = YES;
    self.emptyView.backgroundColor = [UIColor funChatBackgroundColor];
    [self.emptyView setEmptyImageWithName:@"fun_emptyView"];
}

- (void)setupSubviews {
    [super setupSubviews];

    [self.view addSubview:self.cancelButton];
    BOOL isEnglish = [NEAppLanguageUtil getCurrentLanguage] == NEAppLanguageEnglish;
    [NSLayoutConstraint activateConstraints:@[
        [self.cancelButton.centerYAnchor constraintEqualToAnchor:self.searchTextField.centerYAnchor],
        [self.cancelButton.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant:-12],
        [self.cancelButton.widthAnchor constraintEqualToConstant:isEnglish ? 60 : 40],
    ]];

    UIImageView *leftImageView = [[UIImageView alloc] initWithImage:[coreLoader() loadImage:@"fun_search"]];
    self.searchTextField.leftView = leftImageView;
    self.searchTextField.font = [UIFont systemFontOfSize:16];
    self.searchTextField.textColor = [UIColor blackColor];
    self.searchTextField.layer.cornerRadius = 4;
    self.searchTextField.backgroundColor = [UIColor whiteColor];
    [NSLayoutConstraint activateConstraints:@[
        [self.searchTextField.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:NEConstant.statusBarHeight + 12],
        [self.searchTextField.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:8],
        [self.searchTextField.rightAnchor constraintEqualToAnchor:self.cancelButton.leftAnchor constant:-8],
        [self.searchTextField.heightAnchor constraintEqualToConstant:36],
    ]];

    self.collectionView.backgroundColor = [UIColor funChatBackgroundColor];
    [self.collectionView registerClass:[FunSearchMessageOperationCell class]
            forCellWithReuseIdentifier:[FunSearchMessageOperationCell className]];
    [self.view updateLayoutConstraintFirstItem:self.tipLable secondItem:self.searchTextField attribute:NSLayoutAttributeTop constant:60];
    [self.view updateLayoutConstraintFirstItem:self.view secondItem:self.collectionView attribute:NSLayoutAttributeLeft constant:48];
    [self.view updateLayoutConstraintFirstItem:self.view secondItem:self.collectionView attribute:NSLayoutAttributeRight constant:-48];
    [self.view updateLayoutConstraintFirstItem:self.collectionView secondItem:self.tipLable attribute:NSLayoutAttributeTop constant:28];

    self.tableView.backgroundColor = [UIColor funChatBackgroundColor];
    self.tableViewTopAnchor.constant = 48;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= self.viewModel.operationTypes.count) {
        return [[UICollectionViewCell alloc] init];
    }
    id model = self.viewModel.operationTypes[indexPath.row];
    FunSearchMessageOperationCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[FunSearchMessageOperationCell className] forIndexPath:indexPath];
    cell.model = model;
    if ((indexPath.row % 3) == 2) {
        cell.lineView.hidden = YES;
    } else {
        cell.lineView.hidden = NO;
    }
    return cell;
}

- (ExpandButton *)cancelButton {
    if (!_cancelButton) {
        _cancelButton = [[ExpandButton alloc] init];
        _cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
        [_cancelButton setTitle:commonLocalizable(@"cancel") forState:UIControlStateNormal];
        [_cancelButton setTitleColor:[UIColor ne_greyText] forState:UIControlStateNormal];
        [_cancelButton addTarget:self action:@selector(backEvent) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancelButton;
}

- (void)searchTeamMemberAction {
    if (!self.conversationId) return;
    NSString *teamId = [V2NIMConversationIdUtil conversationTargetId:self.conversationId];
    if (!teamId) return;

    FunHistoryMessageMemberController *teamMemberSearchVC = [[FunHistoryMessageMemberController alloc] initWithConversationId:self.conversationId];
    __weak typeof(self) weakSelf = self;
    NEFunSelectTeamMemberBlock callback = ^(NSArray<NETeamMemberInfoModel *> *datas) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf && datas.count > 0) {
            NETeamMemberInfoModel *memberInfo = [datas.firstObject isKindOfClass:[NETeamMemberInfoModel class]] ? datas.firstObject : nil;
            NSString *accountId = memberInfo.nimUser.user.accountId;
            if (accountId) {
                UINavigationController *navigationController = strongSelf.navigationController;
                NSInteger count = navigationController.viewControllers.count;
                if (count > 0) {
                    NSMutableArray *vcs = [navigationController.viewControllers mutableCopy] ?: [NSMutableArray array];
                    [vcs insertObject:teamMemberSearchVC atIndex:count - 1];
                    navigationController.viewControllers = vcs;
                }
                [navigationController popViewControllerAnimated:YES];

                V2NIMMessageSearchExParams *params = [[V2NIMMessageSearchExParams alloc] init];
                params.senderAccountIds = @[accountId];
                teamMemberSearchVC.messageSearchExParams = params;
                [teamMemberSearchVC loadData:params autoSearch:YES];
            }
        }
    };

    [Router.shared use:NEFunTeamMemberSelectViewRouter parameters:@{
        @"nav": self.navigationController ?: [NSNull null],
        @"teamId": teamId,
        @"navTitle": chatLocalizable(@"group_memmber"),
        @"memberLimit": @1,
        @"showAllMembers": @YES,
        @"selectMemberBlock": callback
    }];
}

- (void)searchImageAction {
    FunHistoryMediaResultController *mediaSearchVC = [[FunHistoryMediaResultController alloc] init];
    [self.navigationController pushViewController:mediaSearchVC animated:YES];
}

- (void)searchVideoAction {
    FunHistoryMediaResultController *mediaSearchVC = [[FunHistoryMediaResultController alloc] init];
    mediaSearchVC.searchType = NEHistorySearchTypeVideo;
    [self.navigationController pushViewController:mediaSearchVC animated:YES];
}

- (void)searchDateAction {
    NEHistoryDatePickerViewController *datePickerVC = [[NEHistoryDatePickerViewController alloc] init];
    datePickerVC.selectButtonBackgroundColor = [UIColor ne_funTheme];
    datePickerVC.delegate = self;
    [self.navigationController pushViewController:datePickerVC animated:YES];
}

- (void)searchFileAction {
    FunHistoryMediaResultController *mediaSearchVC = [[FunHistoryMediaResultController alloc] init];
    mediaSearchVC.searchType = NEHistorySearchTypeFile;
    [self.navigationController pushViewController:mediaSearchVC animated:YES];
}

- (void)getMessageModel:(id<MessageModel> )model {
    if (model.type == MessageTypeTip || model.type == MessageTypeNotification) {
        return;
    }

    CGFloat contentWidth = model.contentSize.width;
    CGFloat contentHeight = model.contentSize.height;
    CGFloat subHeight = 0;
    if (contentHeight < fun_chat_min_h) {
        subHeight = fun_chat_min_h - contentHeight;
        model.contentSize = CGSizeMake(contentWidth, fun_chat_min_h);
        model.offset = subHeight;
    }

    if (model.isReply) {
        model.offset = subHeight + fun_chat_reply_height + chat_content_margin;
    }

    if (model.type == MessageTypeRtcCallRecord) {
        model.contentSize = CGSizeMake(contentWidth, contentHeight - 2);
        model.offset = -2;
    }
}

@end
