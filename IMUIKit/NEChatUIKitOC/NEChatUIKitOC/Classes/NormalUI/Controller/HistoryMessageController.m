// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

#import "HistoryMessageController.h"
#import <NEChatKitOC/UIColor+NECommon.h>
#import "HistoryMessageMemberController.h"
#import "HistoryMediaResultController.h"
#import "NormalSearchMessageOperationCell.h"
#import "ChatMessageHelper.h"
#import "NEHistoryDatePickerViewController.h"
#import "NormalChatUIColor.h"

@implementation HistoryMessageController

- (instancetype)initWithConversationId:(NSString *)conversationId {
    self = [super initWithConversationId:conversationId];
    if (self) {
        self.viewModel.themeColor = UIColor.ne_normalTheme;
        self.tag = @"TeamHistoryMessageController";
        self.cellRegisterDic = [ChatMessageHelper getChatCellRegisterDic:NO];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    return self;
}

- (void)setupSubviews {
    [super setupSubviews];
    self.navigationView.backgroundColor = UIColor.whiteColor;
    self.navigationController.navigationBar.backgroundColor = UIColor.whiteColor;

    [NSLayoutConstraint activateConstraints:@[
        [self.searchTextField.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:NEConstant.navigationHeight + NEConstant.statusBarHeight + 20],
        [self.searchTextField.leftAnchor constraintEqualToAnchor:self.view.leftAnchor constant:20],
        [self.searchTextField.rightAnchor constraintEqualToAnchor:self.view.rightAnchor constant:-20],
        [self.searchTextField.heightAnchor constraintEqualToConstant:32],
    ]];

    [self.collectionView registerClass:[NormalSearchMessageOperationCell class] forCellWithReuseIdentifier:[NormalSearchMessageOperationCell className]];
    self.tableViewTopAnchor.constant = 50;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= self.viewModel.operationTypes.count) {
        return [[UICollectionViewCell alloc] init];
    }
    id model = self.viewModel.operationTypes[indexPath.row];
    NormalSearchMessageOperationCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[NormalSearchMessageOperationCell className] forIndexPath:indexPath];
    cell.model = model;
    return cell;
}

- (void)getMessageModel:(id<MessageModel>)model {
    MessageContentModel *contentModel = [model isKindOfClass:[MessageContentModel class]] ? (MessageContentModel *)model : nil;
    if (contentModel.isReply) {
        CGFloat normalMoreHeight = chat_reply_height + chat_content_margin;
        contentModel.contentSize = CGSizeMake(contentModel.contentSize.width, contentModel.contentSize.height + normalMoreHeight);
        contentModel.height += normalMoreHeight;
    }
}

- (void)searchTeamMemberAction {
    if (!self.conversationId) return;
    NSString *teamId = [V2NIMConversationIdUtil conversationTargetId:self.conversationId];
    if (!teamId) return;

    HistoryMessageMemberController *teamMemberSearchVC = [[HistoryMessageMemberController alloc] initWithConversationId:self.conversationId];
    __weak typeof(self) weakSelf = self;
    NESelectTeamMemberBlock callback = ^(NSArray<NETeamMemberInfoModel *> *datas) {
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

    [Router.shared use:TeamMemberSelectViewRouter parameters:@{
        @"nav": self.navigationController ?: [NSNull null],
        @"teamId": teamId,
        @"navTitle": chatLocalizable(@"group_memmber"),
        @"memberLimit": @1,
        @"showAllMembers": @YES,
        @"selectMemberBlock": callback
    }];
}

- (void)searchImageAction {
    HistoryMediaResultController *mediaSearchVC = [[HistoryMediaResultController alloc] init];
    [self.navigationController pushViewController:mediaSearchVC animated:YES];
}

- (void)searchVideoAction {
    HistoryMediaResultController *mediaSearchVC = [[HistoryMediaResultController alloc] init];
    mediaSearchVC.searchType = NEHistorySearchTypeVideo;
    [self.navigationController pushViewController:mediaSearchVC animated:YES];
}

- (void)searchDateAction {
    NEHistoryDatePickerViewController *datePickerVC = [[NEHistoryDatePickerViewController alloc] init];
    datePickerVC.selectButtonBackgroundColor = UIColor.normalSearchDateButtonBg;
    datePickerVC.delegate = self;
    [self.navigationController pushViewController:datePickerVC animated:YES];
}

- (void)searchFileAction {
    HistoryMediaResultController *mediaSearchVC = [[HistoryMediaResultController alloc] init];
    mediaSearchVC.searchType = NEHistorySearchTypeFile;
    [self.navigationController pushViewController:mediaSearchVC animated:YES];
}

@end
